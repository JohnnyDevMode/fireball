Promise = require 'promise'
keygen = require 'keygen'
aws = require 'aws-sdk'
{assign, isArray, map} = require 'lodash'
{map_parameters, expression_names, expression_values, key_and_params, key_for} = require './utils'

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

_apply_timestamps = (item) ->
  now = new Date()
  item.created_at = now unless item.created_at?
  item.updated_at = now
  item

_apply_identifier = (item) ->
  item.identifier = keygen.url @key_size unless item.identifier?
  item



class Model

  constructor: (@name, extension={}) ->
    @doc_client = new aws.DynamoDB.DocumentClient()
    @key_size = keygen.large
    @[prop] = value for prop, value of extension

  put: (item, params={}) ->
    item = assign {}, item
    _apply_timestamps item if @auto_timestamps
    _apply_identifier item if @hash_key == 'identifier'
    params = map_parameters params, condition_mapping
    params.Item = item
    @_request('put', params).then (result) ->
      item

  put_all: (items) ->
    params = RequestItems: {}
    items = map items, (item) =>
      item = assign {}, item
      _apply_timestamps item if @auto_timestamps
      _apply_identifier item if @hash_key == 'identifier'
    params.RequestItems[@name] = (PutRequest: Item: item for item in items)
    @_request('batchWrite', params, false).then (results) ->
      items

  insert: (item, params={}) ->
    item = assign {}, item
    _apply_identifier item
    params.condition = 'identifier <> :identifier'
    params.values =  ':identifier': item.identifier
    @put item, params

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
    @_request('delete', params).then (result) ->
      result

  query: (params={}) ->
    params = map_parameters params, query_mapping
    @_request('query', params).then (result) ->
      result?.Items or []

  query_single: (params={}) ->
    @query(params).then (result) ->
      result[0]

  scan: (params={}) ->
    params = map_parameters params, scan_mapping
    @_request('scan', params).then (result) ->
      result.Items

  for_keys: (keys) ->
    params = RequestItems: {}
    params.RequestItems[@name] = Keys: (@_key_for key for key in keys)
    @_request('batchGet', params, false).then (results) =>
      results.Responses[@name]

  hash_key: 'identifier'

  range_key: undefined

  auto_timestamps: true

  _request: (method, params, include_table=true) ->
    params ?= {}
    params.TableName = @name if include_table
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
