{curryRight, isFunction, isArray, isObject} = require 'lodash'

ensure_prefix = (params, prefix) ->
  results = {}
  for key, value of params
    key = "#{prefix}#{key}" unless key.startsWith(prefix)
    results[key] = value
  results

curried = curryRight ensure_prefix

map_parameters = (params, mapping) ->
  result = {}
  for key, value of params
    mapper = mapping[key]
    if mapper?
      mapped = {key: mapper, value}
      mapped = mapper key, value if isFunction mapper
      result[mapped.key] = mapped.value
    else
      result[key] = value
  result

module.exports =

  map_parameters: map_parameters

  ensure_prefix: ensure_prefix

  expression_names: curried('#')

  expression_values: curried(':')

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
