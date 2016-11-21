
##
#
#  Promise like pipeline implementation that supports standard piping and splitting and joining multiple child pipelines.
#
##

# Segment States
State =
  Pending: 'pending'
  Fulfilled: 'fulfilled'
  Rejected: 'rejected'

objCnt = 0

##
# Base segment in the pipeline.  Functions as a Promise but allows piping and splitting.
##
class Segment

  constructor: ->
    @obj_id = objCnt++
    @_state = State.Pending
    @_fulfill_queue = []
    @_reject_queue = []

  then: (callback) ->
    switch @_state
      when State.Pending then @_fulfill_queue.push callback
      when State.Fulfilled then callback @_result
    @

  catch: (callback) ->
    switch @_state
      when State.Pending then @_reject_queue.push callback
      when State.Rejected then callback @_error
    @

  _fulfill: (@_result) ->
    switch @_state
      when State.Rejected then throw 'Pipeline segment cannot be fulfilled, already rejected'
      when State.Fulfilled then throw 'Pipeline segment cannot be fulfilled, already fulfilled'
    @_state = State.Fulfilled
    for callback in @_fulfill_queue
      do (callback) =>
        callback(@_result)

  _reject: (@_error) ->
    throw 'Pipeline segment already rejected!' if @_state == State.Rejected
    @_state = State.Rejected
    callback(@_error) for callback in @_reject_queue

  pipe: (func) ->
    segment = new FuncSegment func
    @then (arg) => segment._exec arg
    @catch (err) => segment._reject err
    segment

  split: ->
    segment = new SplitSegment()
    @then (arg) => segment._split arg
    @catch (err) => segment._reject err
    segment

class SourceSegment extends Segment

  constructor: (context) ->
    super()
    @_fulfill context

class FuncSegment extends Segment

  constructor: (@func) ->
    super()

  _exec: (context) ->
    result = @func context
    if result?.then?
      result
        .then (result) => @_fulfill result
        .catch (error) => @_reject error
    else
      @_fulfill result

class SplitSegment extends Segment

  constructor: ->
    super()

  _split: (context) ->
    throw 'Can only split on Array context!' unless Array.isArray(context)
    throw 'Already split!' if @child_pipes?.length
    @_child_pipes = (new SourceSegment(item) for item in context)

  pipe: (func) ->
    @_child_pipes = (child.pipe func for child in (@_child_pipes or []))
    @

  join: ->
    results = []
    segment = new Segment()
    process = =>
      current = @_child_pipes.shift()
      current.then (result) =>
        results.push result
        return process() if @_child_pipes?.length
        segment._fulfill results
      current.catch (err) =>
        segment._reject err
    process()
    segment

module.exports =

    source: (context) ->
      new SourceSegment context
