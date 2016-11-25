Instance = require '../src/instance'
Model = require './test_model'

describe 'Instance Tests', ->

  beforeEach (done) ->
    @timeout 20000
    clean_db done

  describe '@extend_with', ->

    it 'should create an instance class extensions for a model', (done) ->
      Child = Instance.extend_with Model
      Child.should.not.be.null
      Child.model.should.eql Model
      done()

    it 'should not create an instance class extensions without model', ->
      expect(Instance.extend_with).to.throw Error

  describe 'instance', ->

    ChildInstance = Instance.extend_with Model

    describe '@constructor', ->

      it 'should wrap data', ->
        data = foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        instance.foo.should.eql data.foo
        instance.baz.should.eql data.baz

    describe '.put', ->

      it 'should call model .put', (done) ->
        data = foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        Model.put = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          done()
        instance.put()

      it 'should call model .put with params', (done) ->
        data = foo: 'bar', baz: 'qak'
        in_params = condition: 'asdads'
        instance = new ChildInstance data
        Model.put = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          params.should.eql in_params
          done()
        instance.put in_params

    describe '.delete', ->

      it 'should call model .delete', (done) ->
        data = foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        Model.delete = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          done()
        instance.delete()

      it 'should call model .delete with params', (done) ->
        data = foo: 'bar', baz: 'qak'
        in_params = condition: 'asdads'
        instance = new ChildInstance data
        Model.delete = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          params.should.eql in_params
          done()
        instance.delete in_params


    describe '.update', ->

      it 'should call model .update', (done) ->
        data = foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        Model.update = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          done()
        instance.update()

      it 'should call model .update with params', (done) ->
        data = foo: 'bar', baz: 'qak'
        in_params = condition: 'asdads'
        instance = new ChildInstance data
        Model.update = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          params.should.eql in_params
          done()
        instance.update in_params
