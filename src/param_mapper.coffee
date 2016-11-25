{curryRight, isFunction} = require 'lodash'

ensure_prefix = (params, prefix) ->
  results = {}
  for key, value of params
    key = "#{prefix}#{key}" unless key.startsWith(prefix)
    results[key] = value
  results

curried_prefix = curryRight ensure_prefix

expression_names = curried_prefix '#'

expression_values = curried_prefix ':'

mapping =
  names: (key, value) ->
    key: 'ExpressionAttributeNames'
    value: expression_names value
  values: (key, value) ->
    key: 'ExpressionAttributeValues'
    value: expression_values value
  condition: 'ConditionExpression'
  update: 'UpdateExpression'
  projection: 'ProjectionExpression'
  filter: 'FilterExpression'
  key_condition: 'KeyConditionExpression'
  index: 'IndexName'
  limit: 'Limit'
  forward: 'ScanIndexForward'


map_parameters = (params) ->
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

module.exports =  {ensure_prefix, expression_names, expression_values, map_parameters}
