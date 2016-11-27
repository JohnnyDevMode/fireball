Model = require '../src/model'
Instance = require '../src/instance'
{pick} = require 'lodash'

model = ChildInstance = undefined

describe 'Instance Tests', ->

  beforeEach (done) ->
    @timeout 20000
    model = new Model 'table_one'
    ChildInstance = Instance.extend_with model
    clean_db done

  describe '@extend_with', ->

    it 'should create an instance class extensions for a model', (done) ->
      Child = Instance.extend_with Model
      Child.should.not.be.null
      Child.model.should.eql Model
      done()

    it 'should not create an instance class extensions without model', ->
      expect(Instance.extend_with).to.throw Error

  describe '@constructor', ->

    it 'should wrap data', ->
      data = foo: 'bar', baz: 'qak'
      instance = new ChildInstance data
      instance.foo.should.eql data.foo
      instance.baz.should.eql data.baz

  describe 'instance', ->

    describe '.put', ->

      it 'should call model .put', (done) ->
        data = foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        model.put = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          done()
        instance.put()

      it 'should call model .put with params', (done) ->
        data = foo: 'bar', baz: 'qak'
        in_params = condition: 'asdads'
        instance = new ChildInstance data
        model.put = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          params.should.eql in_params
          done()
        instance.put in_params

    describe '.delete', ->

      it 'should call model .delete', (done) ->
        data = foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        model.delete = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          done()
        instance.delete()

      it 'should call model .delete with params', (done) ->
        data = foo: 'bar', baz: 'qak'
        in_params = condition: 'asdads'
        instance = new ChildInstance data
        model.delete = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          params.should.eql in_params
          done()
        instance.delete in_params

    describe '.update', ->

      it 'should call model .update', (done) ->
        data = foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        model.update = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          done()
        instance.update()

      it 'should call model .update with params', (done) ->
        data = foo: 'bar', baz: 'qak'
        in_params = condition: 'asdads'
        instance = new ChildInstance data
        model.update = (item, params) ->
          item.foo.should.eql data.foo
          item.baz.should.eql data.baz
          params.should.eql in_params
          done()
        instance.update in_params

    describe '.key', ->

      it 'should call model.key_schema .key_for', (done) ->
        data = identifier: '12345', foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        model.key_schema.key_for = (item) ->
          (pick item, ['identifier', 'foo', 'baz']).should.eql data
          done()
        instance.key()

    describe '.refresh', ->

      it 'should call model .get with key', (done) ->
        data = identifier: '12345', foo: 'bar', baz: 'qak'
        instance = new ChildInstance data
        model.get = (key) ->
          key.should.eql identifier: '12345'
          done()
        instance.refresh()

      it 'should call model .get with key and params', (done) ->
        data = identifier: '12345', foo: 'bar', baz: 'qak'
        in_params = something: 'asdads'
        instance = new ChildInstance data
        model.get = (key, params) ->
          key.should.eql identifier: '12345'
          params.should.eql in_params
          done()
        instance.refresh in_params

    describe '.patch', ->

      it 'should call model .update with key and update from update builder', (done) ->
        data = identifier: '12345', foo: 'bar', baz: 'qak'
        changes = thing: 'asdads', other_thing: '231231'
        instance = new ChildInstance data
        model.update = (key, params) ->
          key.should.eql identifier: '12345'
          params.should.have.property 'update'
          params.should.have.property 'names'
          params.should.have.property 'values'
          done()
        instance.patch changes

      it 'should call model .update with key and update from update builder and include params', (done) ->
        data = identifier: '12345', foo: 'bar', baz: 'qak'
        in_params = something: 'asdads'

        changes = thing: 'asdads', other_thing: '231231'
        instance = new ChildInstance data
        model.update = (key, params) ->
          params.should.have.property 'update'
          params.should.have.property 'names'
          params.should.have.property 'values'
          params.should.have.property 'something'
          done()
        instance.patch changes, in_params
