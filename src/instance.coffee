{assign} = require 'lodash'

class Instance

  constructor: (data) ->
  	assign @, data

  toString: ->
    values = []
    for key, value of @
      values.push "#{key}: '#{value}'" if @.hasOwnProperty key
    values = values.join ','
    "Instance[#{@constructor.model?.name}](#{values})"

  @extend_with: (model) ->
    throw new Error "Instance extensions require model!" unless model?
    extension = class extends Instance
    extension.model = model
    extension

for func in ['put', 'delete', 'update']
  do (func) ->
    Instance::[func] = (params) -> @constructor.model[func] @, params

module.exports = Instance
