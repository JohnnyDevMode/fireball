{isArray, isObject} = require 'lodash'

module.exports =

  key_and_params: (key, params={}) ->
    unless isObject params
      key.push params
      params = {}
    [key, params] = [params, {}] if isArray(key) and key.length == 0
    params ?= {}
    [key, params]

  key_for: (item, hash_key, range_key) ->
    key = {}
    item = item[0] if isArray(item) and item.length == 1
    hash_value = range_value = item
    [hash_value, range_value] = item if isArray(item)
    hash_value = hash_value[hash_key] if isObject(hash_value)
    key[hash_key] = hash_value
    if range_key?
      range_value = range_value[range_key] if isObject(range_value)
      key[range_key] = range_value
    key
