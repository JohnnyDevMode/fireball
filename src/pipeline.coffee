
##
#
#  Promise like pipeline implementation that supports standard piping and splitting and joining multiple child pipelines.
#
##

# utils
head = (array) ->
  array[0]

tail = (array) ->
  array.slice(1)

# Segment States
State =
  Pending: 'pending'
  Fulfilled: 'fulfilled'
  Rejected: 'rejected'


##
# Base segment in the pipeline.  Functions as a Promise but allows piping and splitting.
##
class Segment

  constructor: (@_context={}) ->
    @_state = State.Pending
    @_fulfill_queue = []
    @_reject_queue = []

  context: (@_context) ->
    @

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

  _pipe: (func) ->
    segment = new FuncSegment func, @_context
    @then (data) => segment._exec data
    @catch (err) => segment._reject err
    segment

  _pass: ->
    segment = new Segment @_context
    @then (data) => segment._fulfill data
    @catch (err) => segment._reject err
    segment

  pipe: (func) ->
    if Array.isArray func
      next = head func
      return @ unless next?
      @_pipe(next).pipe tail func
    else if func == undefined
      @_pass()
    else
      @_pipe func

  split: (map_func) ->
    segment = new SplitSegment @_context
    proceed = (resolve_context) =>
      resolve_context.then (arg) => segment._split arg
      resolve_context.catch (err) => segment._reject err
    if map_func?
      proceed @pipe map_func
    else
      proceed @
    segment

  map: (func) ->
    if func == undefined
      @_pass()
    else
      @split().pipe(func).join()



class SourceSegment extends Segment

  constructor: (data, context) ->
    super context
    @_fulfill data

class FuncSegment extends Segment

  constructor: (@func, context) ->
    super(context)

  _exec: (data) ->
    result = @func.apply @_context, [data]
    if result?.then?
      result
        .then (result) => @_fulfill result
        .catch (error) => @_reject error
    else
      @_fulfill result

class SplitSegment extends Segment

  constructor: (context) ->
    super context
    @_has_split = false
    @_pipe_funcs = []

  _split: (data) ->
    throw 'Can only split on Array context!' unless Array.isArray(data)
    throw 'Already split!' if @child_pipes?.length
    @_has_split = true
    @_child_pipes = (new SourceSegment(item, @_context) for item in data)
    if @_pipe_funcs?.length
      for child in @_child_pipes
        child.pipe @_pipe_funcs
    @_join() if @_join_segment
    @_then() if @_then_callback

  pipe: (func) ->
    if @_has_split
      @_child_pipes = (child.pipe func for child in (@_child_pipes or []))
    else
      @_pipe_funcs.push func
    @

  _then: ->
    process = =>
      current = @_child_pipes.shift()
      current.then (result) =>
        @then_callback result
        return process() if @_child_pipes?.length
      current.catch (err) => @catch err
    process()

  then: (callback) ->
    @then_callback = callback
    @_then() if @_has_split
    @

  _join: ->
    results = []
    process = =>
      current = @_child_pipes.shift()
      return @_join_segment._fulfill results unless current?
      current.then (result) =>
        results.push result
        process()
      current.catch (err) => @_join_segment._reject err
    process()

  join: ->
    @_join_segment = new Segment @_context
    @_join() if @_has_split
    @_join_segment

module.exports =

    source: (data) ->
      new SourceSegment data
