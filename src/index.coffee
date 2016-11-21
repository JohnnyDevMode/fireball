Promise = require 'promise'
keygen = require 'keygen'
aws = require 'aws-sdk'
{assign, isArray, map} = require 'lodash'
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
update_mapping = assign {}, expression_mapping, expression: 'UpdateExpression'
projection_mapping = assign {}, expression_mapping, projection: 'ProjectionExpression'
filter_mapping = assign {}, expression_mapping, filter: 'FilterExpression', expression: 'FilterExpression'
query_mapping = assign {}, filter_mapping, expression: 'KeyConditionExpression', index: 'IndexName', limit: 'Limit', forward: 'ScanIndexForward'
scan_mapping = assign {}, filter_mapping, limit: 'Limit'

apply_timestamps = (auto_timestamps) -> (item) ->
  return item unless auto_timestamps
  now = new Date()
  item.created_at = now unless item.created_at?
  item.updated_at = now
  item

apply_identifier = (hash_key, key_size) -> (item) ->
  item.identifier = keygen.url key_size if hash_key == 'identifier' and not item.identifier?
  item

apply_table = (table_name) -> (params) ->
  params.TableName = table_name
  params

map_params = (mapping) ->
  (params) -> map_parameters params, mapping

invoke_request = (model, method) ->
  (params) -> model._request method, params

class Model

  constructor: (@name, extension={}) ->
    @doc_client = new aws.DynamoDB.DocumentClient()
    @key_size = keygen.large
    @[prop] = value for prop, value of extension

  put: (item, params={}) ->
    item = assign {}, item
    pipeline.source item
      .pipe apply_timestamps @auto_timestamps
      .pipe apply_identifier @hash_key, @key_size
      .pipe (item) ->
        params.Item = item
        params
      .pipe map_params condition_mapping
      .pipe apply_table @name
      .pipe (params) => @_request 'put', params
      .pipe -> item

  put_all: (items) ->
    params = RequestItems: {}
    items = map items, (item) =>
      item = assign {}, item
      apply_timestamps.apply @, [item] if @auto_timestamps
      apply_identifier.apply @, [item] if @hash_key == 'identifier'
    params.RequestItems[@name] = (PutRequest: Item: item for item in items)
    @_request('batchWrite', params, false).then (results) ->
      items

  insert: (item, params={}) ->
    item = assign {}, item
    pipeline.source item
      .pipe apply_identifier @hash_key, @key_size
      .pipe (item) ->
        assign params, condition: 'identifier <> :identifier', values: {':identifier': item.identifier}
      .pipe => @put item, params

  update: (keys..., params) ->
    params = @_keyed_params keys, params, update_mapping
    params.ReturnValues ?=  'ALL_NEW'
    @_request('update', params).then (result) ->
      result.Attributes

  get: (keys..., params) ->
    params = @_keyed_params keys, params, projection_mapping
    @_request('get', params).then (result) ->
      result?.Item

  delete: (keys..., params) ->
    params = @_keyed_params keys, params, condition_mapping
    @_request 'delete', params

  query: (params={}) ->
    pipeline.source params
      .pipe map_params query_mapping
      .pipe apply_table @name
      .pipe (params) => @_request 'query', params
      .pipe (results) -> results?.Items or []

  query_single: (params={}) ->
    @query(params).pipe (result) ->
      result[0]

  scan: (params={}) ->
    pipeline.source params
      .pipe map_params scan_mapping
      .pipe apply_table @name
      .pipe (params) => @_request 'scan', params
      .pipe (results) -> results?.Items or []


  for_keys: (keys) ->
    pipeline.source keys
      .split()
        .pipe (key) => key_for key, @hash_key, @range_key
      .join()
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

  _keyed_params: (keys, params, mapping) ->
    [key, params] = key_and_params keys, params
    params = map_parameters params, mapping
    params.Key = @_key_for key
    params

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
    {expression: "#{set_exp} #{parts.join(', ')}", names, values}

module.exports = Model
