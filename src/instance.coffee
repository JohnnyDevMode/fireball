{assign} = require 'lodash'
{patch} = require './update_builder'

class Instance

  constructor: (data) ->
  	assign @, data

  key: -> @_model().key_schema.key_for @

  refresh: (params) -> @_model().get @key(), params

  patch: (changes, params={}) ->
    Model = require './model'
    assign params, patch changes
    @_model().update @key(), params

  toString: ->
    values = []
    for key, value of @
      values.push "#{key}: '#{value}'" if @.hasOwnProperty key
    values = values.join ','
    "Instance[#{@_model()?.name}](#{values})"

  @extend_with: (model) ->
    throw new Error "Instance extensions require model!" unless model?
    extension = class extends Instance
    extension.model = model
    extension

  _model: -> @constructor.model


for func in ['put', 'delete', 'update']
  do (func) ->
    Instance::[func] = (params) -> @constructor.model[func] @, params

module.exports = Instance
