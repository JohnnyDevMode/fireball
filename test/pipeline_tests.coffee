{assign} = require 'lodash'
pipeline = require '../src/pipeline'

describe 'Pipeline Tests', ->

  describe 'linear pipes', ->

    it 'should handle no segments', (done) ->
      context = {foo: 'bar'}
      pipeline
        .source context
        .then (result) ->
          result.should.equal context
          done()
        .catch done

    it 'should pipe with non promise func', (done) ->
      context = {foo: 'bar'}
      pipeline
        .source context
        .pipe (context) ->
          assign context, bar: 'baz'
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz'
          result.should.eql context
          done()
        .catch done

    it 'should pipe with multiple non promise func', (done) ->
      context = {foo: 'bar'}
      pipeline
        .source context
        .pipe (context) ->
          assign context, bar: 'baz'
        .pipe (context) ->
          assign context, baz: 'qak'
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz', baz: 'qak'
          result.should.eql context
          done()
        .catch done

    it 'should pipe with promise func', (done) ->
      context = {foo: 'bar'}
      pipeline
        .source context
        .pipe (context) ->
          Promise.resolve(assign context, bar: 'baz')
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz'
          result.should.eql context
          done()
        .catch done

    it 'should pipe with multiple promise func', (done) ->
      context = {foo: 'bar'}
      pipeline
        .source context
        .pipe (context) ->
          Promise.resolve(assign context, bar: 'baz')
        .pipe (context) ->
          Promise.resolve(assign context, baz: 'qak')
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz', baz: 'qak'
          result.should.eql context
          done()
        .catch done

    it 'should pipe with multiple mixed func', (done) ->
      context = {foo: 'bar'}
      pipeline
        .source context
        .pipe (context) ->
          Promise.resolve(assign context, bar: 'baz')
        .pipe (context) ->
          assign context, baz: 'qak'
        .then (result) ->
          result.should.eql foo: 'bar', bar: 'baz', baz: 'qak'
          result.should.eql context
          done()
        .catch done

    it 'should handle error', (done) ->
      context = {foo: 'bar'}
      err_msg = 'Some error occured'
      pipeline
        .source context
        .pipe (context) ->
          assign context, baz: 'qak'
        .pipe (context) ->
          Promise.reject err_msg
        .then (result) ->
          done 'Should have been an error'
        .catch (err) ->
          err.should.eql err_msg
          done()

    it 'should handle early error', (done) ->
      context = {foo: 'bar'}
      err_msg = 'Some error occured'
      pipeline
        .source context
        .pipe (context) ->
          Promise.reject err_msg
        .pipe (context) ->
          assign context, baz: 'qak'
        .then (result) ->
          done 'Should have been an error'
        .catch (err) ->
          err.should.eql err_msg
          done()

  describe 'split pipes', ->

    it 'should handle a basic split and join', (done) ->
      pipeline
        .source [1, 2, 3]
        .split()
        .join()
        .then (results) ->
          results.should.eql [1, 2, 3]
          done()
        .catch done

    it 'should handle split with pipe', (done) ->
      pipeline
        .source [1, 2, 3]
        .split()
        .pipe (item) ->
          item + 10
        .join()
        .then (results) ->
          results.should.eql [11, 12, 13]
          done()
        .catch done

    it 'should handle split with multiple pipes', (done) ->
      pipeline
        .source [1, 2, 3]
        .split()
        .pipe (item) ->
          item + 10
        .pipe (item) ->
          item + 20
        .join()
        .then (results) ->
          results.should.eql [31, 32, 33]
          done()
        .catch done

    it 'should handle split with error', (done) ->
      err_msg = 'Some error occured'
      pipeline
        .source [1, 2, 3]
        .split()
        .pipe (item) ->
          Promise.reject(err_msg)
        .pipe (item) ->
          item + 20
        .join()
        .then (results) ->
          done 'Should have been an error'
        .catch (err) ->
          err_msg.should.eql err
          done()
