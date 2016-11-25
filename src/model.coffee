keygen = require 'keygen'
aws = require 'aws-sdk'
{assign, isObject, cloneDeep} = require 'lodash'
{key_and_params, key_for} = require './utils'
{map_parameters} = require './param_mapper'
Pipeline = require 'ppl'

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
process_results = (results) ->
  items = results?.Items or []
  items.last_key = results?.LastEvaluatedKey
  items

class Model

  constructor: (@name, extension={}) ->
    @doc_client = new aws.DynamoDB.DocumentClient()
    @key_size = keygen.large
    @hash_key = 'identifier'
    @range_key = undefined
    @auto_timestamps = true
    @[prop] = value for prop, value of extension

  put: (item, params={}) ->
    item = assign {}, item
    @_piped item
      .pipe [apply_timestamps, apply_identifier, @pre_write_hook]
      .pipe (item) -> assign params, Item: item
      .pipe map_parameters
      .pipe apply_table
      .pipe (params) => @_request 'put', params
      .pipe -> item
      .pipe @post_read_hook

  put_all: (items) ->
    new_items = []
    @_piped items
      .map [cloneDeep, apply_timestamps, apply_identifier, @pre_write_hook]
      .pipe (items) =>
        new_items = items
        params = RequestItems: {}
        params.RequestItems[@name] = (PutRequest: Item: item for item in items)
        params
      .pipe (params) => @_request 'batchWrite', params
      .pipe -> new_items
      .map @post_read_hook

  insert: (item, params={}) ->
    item = assign {}, item
    @_piped item
      .pipe apply_identifier
      .pipe (item) ->
        assign params, condition: 'identifier <> :identifier', values: {':identifier': item.identifier}
      .pipe => @put item, params

  update: (keys..., params) ->
    @_piped @_keyed_params keys, params
      .pipe map_parameters
      .pipe apply_table
      .pipe (params) ->
        params.ReturnValues ?=  'ALL_NEW'
        params
      .pipe (params) => @_request 'update', params
      .pipe (result) -> result.Attributes

  get: (keys..., params) ->
    @_piped @_keyed_params keys, params
      .pipe map_parameters
      .pipe apply_table
      .pipe (params) => @_request 'get', params
      .pipe (result) -> result?.Item
      .pipe @post_read_hook

  delete: (keys..., params) ->
    @_piped @_keyed_params keys, params
      .pipe map_parameters
      .pipe apply_table
      .pipe (params) => @_request 'delete', params

  query: (key_condition, params={}) ->
    @_piped params
      .pipe (params) -> assign params, {key_condition}
      .pipe map_parameters
      .pipe apply_table
      .pipe (params) => @_request 'query', params
      .pipe process_results
      .map @post_read_hook

  query_single: (key_condition, params={}) ->
    @query(key_condition, params).pipe (result) -> result[0]

  scan: (filter, params) ->
    [filter, params] = [undefined, filter] unless params?
    @_piped params or {}
      .pipe (params) -> assign params, {filter}
      .pipe map_parameters
      .pipe apply_table
      .pipe (params) => @_request 'scan', params
      .pipe process_results
      .map @post_read_hook

  all: (params) -> @scan undefined, params

  for_keys: (keys) ->
    @_piped keys
      .map (key) => key_for key, @hash_key, @range_key
      .pipe (keys) =>
        params = RequestItems: {}
        params.RequestItems[@name] = Keys: keys
        params
      .pipe (params) => @_request 'batchGet', params
      .pipe (results) => results.Responses[@name]
      .map @post_read_hook

  _request: (method, params) ->
    new Pipeline (resolve, reject) =>
      @doc_client[method] params, (err, result) ->
        return reject(err) if err?
        resolve result

  _keyed_params: (keys, params) ->
    [key, params] = key_and_params keys, params
    params.Key = key_for key, @hash_key, @range_key
    params

  _piped: (source) ->
    Pipeline.source(source).context @

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
