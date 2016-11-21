{assign} = require 'lodash'
chain = require '../src/chain'

describe 'Chain Tests', ->

  it 'should handle empty chain', (done) ->
    context = {}
    seed = foo: 'bar'
    chain context, []
      .invoke seed
      .then (result) ->
        result.should.eql seed
        done()
      .catch done

  describe 'non promise links', ->

    it 'should allow seed update', (done) ->
      context = {}
      seed = foo: 'bar'
      chain context, [
        (data) ->
          data.bar = 'baz'
          data
      ]
        .invoke seed
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz'
          result.should.eql seed
          done()
        .catch done

    it 'should allow seed change', (done) ->
      context = {}
      seed = foo: 'bar'
      chain context, [
        (data) ->
          bar: 'baz'
      ]
        .invoke seed
        .then (result) ->
          result.should.eql bar: 'baz'
          done()
        .catch done

    it 'should handle multiple', (done) ->
      context = {}
      seed = foo: 'bar'
      chain context, [
        (data) ->
          data.bar = 'baz'
          data
        (data) ->
          data.baz = 'qak'
          data
        (data) ->
          data.qak = 'foo'
          data
      ]
        .invoke seed
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz', baz: 'qak', qak: 'foo'
          done()
        .catch done

  describe 'promise links', ->

    it 'should allow seed update', (done) ->
      context = {}
      seed = foo: 'bar'
      chain context, [
        (data) ->
          data.bar = 'baz'
          Promise.resolve data
      ]
        .invoke seed
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz'
          result.should.eql seed
          done()
        .catch done

    it 'should allow seed change', (done) ->
      context = {}
      seed = foo: 'bar'
      chain context, [
        (data) ->
          Promise.resolve bar: 'baz'
      ]
        .invoke seed
        .then (result) ->
          result.should.eql bar: 'baz'
          done()
        .catch done

    it 'should handle multiple', (done) ->
      context = {}
      seed = foo: 'bar'
      chain context, [
        (data) ->
          data.bar = 'baz'
          Promise.resolve data
        (data) ->
          data.baz = 'qak'
          Promise.resolve data
        (data) ->
          data.qak = 'foo'
          Promise.resolve data
      ]
        .invoke seed
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz', baz: 'qak', qak: 'foo'
          done()
        .catch done

    it 'should handle error', (done) ->
      context = {}
      seed = foo: 'bar'
      chain context, [
        (data) ->
          data.bar = 'baz'
          Promise.resolve data
        (data) ->
          Promise.reject "Something didn't work"
        (data) ->
          data.qak = 'foo'
          Promise.resolve data
      ]
        .invoke seed
        .then ->
          done 'Should have resulted in error'
        .catch (err) ->
          err.should.not.be.null
          done()


  describe 'link context', ->

    it 'should execute with the provided context', (done) ->
      context =
        foo: 'bar'
        func: (data) ->
          data.foo = @foo
          data
      seed = {}
      chain context, [
        context.func
        (data) ->
          context.should.equal @
          data
      ]
        .invoke seed
        .then (result) ->
          result.should.eql foo: 'bar'
          done()
        .catch done
