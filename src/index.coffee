Promise = require 'promise'
keygen = require 'keygen'
aws = require 'aws-sdk'
{assign, isArray, isObject, cloneDeep} = require 'lodash'
{map_parameters, expression_names, expression_values, key_and_params, key_for} = require './utils'
pipeline = require './pipeline'

expression_mapping =
  names: (key, value) ->
    key: 'ExpressionAttributeNames'
    value: expression_names value
  values: (key, value) ->
    key: 'ExpressionAttributeValues'
    value: expression_values value
condition_mapping = assign {}, expression_mapping, condition: 'ConditionExpression'
update_mapping = assign {}, expression_mapping, update: 'UpdateExpression'
projection_mapping = assign {}, expression_mapping, projection: 'ProjectionExpression'
filter_mapping = assign {}, expression_mapping, filter: 'FilterExpression'
query_mapping = assign {}, filter_mapping, key_condition: 'KeyConditionExpression', index: 'IndexName', limit: 'Limit', forward: 'ScanIndexForward'
scan_mapping = assign {}, filter_mapping, limit: 'Limit'

clone = (data) -> cloneDeep data

apply_timestamps = (item) ->
  return item unless @auto_timestamps
  now = new Date()
  item.created_at = now unless item.created_at?
  item.updated_at = now
  item

apply_identifier = (item) ->
  item.identifier = keygen.url @key_size if @hash_key == 'identifier' and not item.identifier?
  item

apply_table = (params) -> assign params, TableName: @name

map_params = (mapping) -> (params) -> map_parameters params, mapping

class Model

  constructor: (@name, extension={}) ->
    @doc_client = new aws.DynamoDB.DocumentClient()
    @key_size = keygen.large
    @[prop] = value for prop, value of extension

  put: (item, params={}) ->
    item = assign {}, item
    @_piped item
      .pipe [apply_timestamps, apply_identifier]
      .pipe (item) -> assign params, Item: item
      .pipe map_params condition_mapping
      .pipe apply_table
      .pipe (params) => @_request 'put', params
      .pipe -> item

  put_all: (items) ->
    new_items = []
    @_piped items
      .map [clone, apply_timestamps, apply_identifier]
      .pipe (items) =>
        new_items = items
        params = RequestItems: {}
        params.RequestItems[@name] = (PutRequest: Item: item for item in items)
        params
      .pipe (params) => @_request 'batchWrite', params
      .pipe -> new_items

  insert: (item, params={}) ->
    item = assign {}, item
    @_piped item
      .pipe apply_identifier
      .pipe (item) ->
        assign params, condition: 'identifier <> :identifier', values: {':identifier': item.identifier}
      .pipe => @put item, params

  update: (keys..., params) ->
    @_piped @_keyed_params keys, params
      .pipe map_params update_mapping
      .pipe apply_table
      .pipe (params) ->
        params.ReturnValues ?=  'ALL_NEW'
        params
      .pipe (params) => @_request 'update', params
      .pipe (result) -> result.Attributes

  get: (keys..., params) ->
    @_piped @_keyed_params keys, params
      .pipe map_params projection_mapping
      .pipe apply_table
      .pipe (params) => @_request 'get', params
      .pipe (result) -> result?.Item

  delete: (keys..., params) ->
    @_piped @_keyed_params keys, params
      .pipe map_params condition_mapping
      .pipe apply_table
      .pipe (params) => @_request 'delete', params

  query: (key_condition, params={}) ->
    @_piped params
      .pipe (params) -> assign params, {key_condition}
      .pipe map_params query_mapping
      .pipe apply_table
      .pipe (params) =>
        @_request 'query', params
      .pipe (results) -> results?.Items or []

  query_single: (key_condition, params={}) ->
    @query(key_condition, params).pipe (result) -> result[0]

  scan: (filter, params) ->
    [filter, params] = [undefined, filter] unless params?
    @_piped params or {}
      .pipe (params) -> assign params, {filter}
      .pipe map_params scan_mapping
      .pipe apply_table
      .pipe (params) => @_request 'scan', params
      .pipe (results) -> results?.Items or []

  all: (params) -> @scan undefined, params

  for_keys: (keys) ->
    pipeline.source keys
      .map (key) => key_for key, @hash_key, @range_key
      .pipe (keys) =>
        params = RequestItems: {}
        params.RequestItems[@name] = Keys: keys
        params
      .pipe (params) => @_request 'batchGet', params
      .pipe (results) => results.Responses[@name]


  hash_key: 'identifier'

  range_key: undefined

  auto_timestamps: true

  _request: (method, params) ->
    new Promise (resolve, reject) =>
      @doc_client[method] params, (err, result) ->
        return reject(err) if err?
        resolve result

  _key_for: (key) -> key_for key, @hash_key, @range_key

  _keyed_params: (keys, params) ->
    [key, params] = key_and_params keys, params
    params.Key = @_key_for key
    params

  _piped: (source) ->
    pipeline.source(source).context @

  @model: (name, extension={}) ->
    new @ name, extension

  @extend: (module, name, extension={}) ->
    module.exports = @model name, extension

  @update_builder: (item) ->
    set_exp = 'set '
    names = {}
    values = {}
    parts = []
    for name, value of item
      parts.push "##{name} = :#{name}"
      names["##{name}"] = name
      values[":#{name}"] = value
    {update: "#{set_exp} #{parts.join(', ')}", names, values}

module.exports = Model
