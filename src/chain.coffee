Promise = require 'promise'

class PromChain

  constructor: (@context, @links) ->
    @promise = new Promise (fulfill, reject) =>
      @_fulfill = fulfill
      @_reject = reject

  invoke: (seed) ->
    @next seed
    @promise

  next: (arg) ->
    link = @links.shift()
    return @_fulfill(arg) unless link?
    result = link.apply @context, [arg]
    if result.then?
      result.then (result) =>
        @next result
      .catch @_reject
    else
      @next result

module.exports = (context, links) ->
  new PromChain context, links
