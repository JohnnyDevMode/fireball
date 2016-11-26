{isArray, isObject} = require 'lodash'
keygen = require 'keygen'

module.exports = class KeySchema

  constructor: (options={}) ->
    @hash = options.hash_key or 'identifier'
    @range = options.range_key
    @size = options.key_size or keygen.large
    @auto = if options.generate_hash_key? then options.generate_hash_key else true

  keyed_params: (hash_value, range_value, params) ->
    if isObject hash_value  # Assume a full key object
      key = @key_for hash_value, @hash, @range
      params = range_value
    else # Assume key parts
      key = {}
      key[@hash] = hash_value
      if @range?
        key[@range] = range_value
      else
        params = range_value
    params ?= {}
    params.Key = key
    params

  key_for: (item) ->
    key = {}
    if isObject item
      key[@hash] = item[@hash]
      key[@range] = item[@range] if @range?
    else
      key[@hash] = item
    key

  generate_for: (item) ->
    item[@hash] = keygen.url @size if @auto and not item[@hash]?
    item
