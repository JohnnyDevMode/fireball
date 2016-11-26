{isArray, isObject} = require 'lodash'

module.exports = class KeySchema

  constructor: (@hash_key, @range_key) ->
    @hash_key ?= 'identifier'

  keyed_params: (hash_value, range_value, params) ->
    if isObject hash_value  # Assume a full key object
      key = @key_for hash_value, @hash_key, @range_key
      params = range_value
    else # Assume key parts
      key = {}
      key[@hash_key] = hash_value
      if @range_key?
        key[@range_key] = range_value
      else
        params = range_value
    params ?= {}
    params.Key = key
    params

  key_for: (item) ->
    key = {}
    if isObject item
      key[@hash_key] = item[@hash_key]
      key[@range_key] = item[@range_key] if @range_key?
    else
      key[@hash_key] = item
    key
