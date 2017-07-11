aws = require 'aws-sdk'
{assign, cloneDeep, omit, pick} = require 'lodash'
Pipeline = require 'ppl'
KeySchema = require './key_schema'
{map_parameters} = require './param_mapper'
Instance = require './instance'
update_builder = require './update_builder'

apply_timestamps = (item) ->
  return item unless @auto_timestamps
  now = new Date()
  item.created_at = now unless item.created_at?
  item.updated_at = now
  item

apply_identifier = (item) -> @key_schema.generate_for item

apply_table = (params) -> assign params, TableName: @name

process_results = (results) ->
  Pipeline
    .source results?.Items
    .context @
    .map [@post_read_hook, @wrap]
    .then (processed) ->
      processed.last_key = results?.LastEvaluatedKey
      if processed.last_key?
        params = assign {}, results.params, ExclusiveStartKey: processed.last_key
        model = @
        processed.next = =>
          @_piped(params)
            .pipe (params) => @_request results.method, params
            .pipe process_results
      processed

key_overides = ['hash_key', 'range_key', 'key_size', 'generate_hash_key']

class Model

  constructor: (@name, extension={}) ->
    @doc_client = new aws.DynamoDB.DocumentClient()
    @key_schema = new KeySchema pick(extension, key_overides)
    @instance_type = Instance.extend_with @
    @auto_timestamps = true
    @[prop] = value for prop, value of omit(extension, key_overides)

  put: (item, params={}) ->
    item = assign {}, item
    final_item = undefined
    @_piped item
      .pipe [apply_timestamps, apply_identifier, @pre_write_hook]
      .pipe (item) ->
        final_item = item
        assign params, Item: item
      .pipe [map_parameters, apply_table]
      .pipe (params) => @_request 'put', params
      .pipe -> final_item
      .pipe [@post_read_hook, @wrap]

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
      .map [@post_read_hook, @wrap]

  insert: (item, params={}) ->
    item = assign {}, item
    @_piped item
      .pipe apply_identifier
      .pipe (item) ->
        assign params, condition: 'identifier <> :identifier', values: {':identifier': item.identifier}
      .pipe => @put item, params

  update: (hash_key, range_key, params) ->
    @_piped @key_schema.keyed_params(hash_key, range_key, params)
      .pipe [map_parameters, apply_table]
      .pipe (params) ->
        params.ReturnValues ?=  'ALL_NEW'
        params
      .pipe (params) => @_request 'update', params
      .pipe (result) -> result.Attributes

  get: (hash_key, range_key, params) ->
    @_piped @key_schema.keyed_params(hash_key, range_key, params)
      .pipe [map_parameters, apply_table]
      .pipe (params) => @_request 'get', params
      .pipe (result) -> result?.Item
      .pipe [@post_read_hook, @wrap]

  delete: (hash_key, range_key, params) ->
    @_piped @key_schema.keyed_params(hash_key, range_key, params)
      .pipe [map_parameters, apply_table]
      .pipe (params) => @_request 'delete', params

  query: (key_condition, params={}) ->
    @_piped params
      .pipe (params) -> assign params, {key_condition}
      .pipe [map_parameters, apply_table]
      .pipe (params) => @_request 'query', params
      .pipe process_results

  query_single: (key_condition, params={}) ->
    params.limit = 1
    @query(key_condition, params).pipe (result) -> result[0]

  query_complete: (key_condition, params={}) ->
    results = []
    process = (page) ->
      results = results.concat page
      return page.next().pipe process if page.next?
      Pipeline.resolve results
    @query(key_condition, params).pipe process

  query_count: (key_condition, params={}) ->
    @_piped params
      .pipe (params) -> assign params, {key_condition, select: 'COUNT'}
      .pipe [map_parameters, apply_table]
      .pipe (params) => @_request 'query', params
      .pipe (result) -> result.Count

  scan: (filter, params) ->
    [filter, params] = [undefined, filter] unless params?
    @_piped params or {}
      .pipe (params) -> assign params, {filter}
      .pipe [map_parameters, apply_table]
      .pipe (params) => @_request 'scan', params
      .pipe process_results

  all: (params) -> @scan undefined, params

  for_keys: (keys) ->
    @_piped keys
      .map (key) => @key_schema.key_for key
      .pipe (keys) =>
        params = RequestItems: {}
        params.RequestItems[@name] = Keys: keys
        params
      .pipe (params) => @_request 'batchGet', params
      .pipe (results) => results.Responses[@name]
      .map [@post_read_hook, @wrap]

  wrap: (item) ->
    return item if not item? or item?.constructor?.model?
    new @instance_type item

  _request: (method, params) ->
    new Pipeline (resolve, reject) =>
      @doc_client[method] params, (err, result) ->
        return reject(err) if err?
        resolve assign {}, result, {params, method}

  _piped: (source) ->
    Pipeline.source(source).context @

  @model: (name, extension={}) ->
    new @ name, extension

  @extend: (module, name, extension={}) ->
    module.exports = @model name, extension

  @update_builder: update_builder

module.exports = Model
