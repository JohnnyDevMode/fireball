KeySchema = require '../src/key_schema'
keygen = require 'keygen'


describe 'Key Schema Tests', ->

  describe '@constructor', ->

    it 'should default hash_key and size', ->
      schema = new KeySchema()
      schema.hash.should.eql 'identifier'
      schema.size.should.eql keygen.large

    it 'should take hash_key and default size', ->
      schema = new KeySchema hash_key: 'some_key'
      console.log schema
      schema.hash.should.eql 'some_key'
      schema.size.should.eql keygen.large

    it 'should take hash_key and range and default size', ->
      schema = new KeySchema hash_key: 'some_key', range_key: 'other_key'
      schema.range.should.eql 'other_key'
      schema.size.should.eql keygen.large

    it 'should take hash_key, range and size and default auto ', ->
      schema = new KeySchema hash_key: 'some_key', range_key: 'other_key', key_size: keygen.small
      schema.size.should.eql keygen.small
      schema.auto.should.eql true

    it 'should take hash_key, range, size and auto ', ->
      schema = new KeySchema hash_key: 'some_key', range_key: 'other_key', key_size: keygen.small, generate_hash_key: false
      schema.auto.should.eql false

  describe '.keyed_params', ->

    it 'should handle simple key no params', ->
      schema = new KeySchema hash_key: 'identifier'
      schema.keyed_params('2123123').should.eql Key: identifier: '2123123'

    it 'should handle simple key with params', ->
      schema = new KeySchema hash_key: 'identifier'
      schema.keyed_params('2123123', {foo: 'bar'}).should.eql Key: {identifier: '2123123'}, foo: 'bar'

    it 'should handle simple key with range', ->
      schema = new KeySchema hash_key: 'identifier', range_key: 'name'
      schema.keyed_params('2123123', 'fred').should.eql Key: {identifier: '2123123', name: 'fred'}

    it 'should handle simple key with range and params', ->
      schema = new KeySchema hash_key: 'identifier', range_key: 'name'
      schema.keyed_params('2123123', 'fred', {foo: 'bar'}).should.eql Key: {identifier: '2123123', name: 'fred'}, foo: 'bar'

    it 'should handle object key no params', ->
      schema = new KeySchema hash_key: 'identifier'
      schema.keyed_params(identifier: '2123123').should.eql {Key: identifier: '2123123'}

    it 'should handle object key with params', ->
      schema = new KeySchema hash_key: 'identifier'
      schema.keyed_params(identifier: '2123123', {foo: 'bar'}).should.eql Key: {identifier: '2123123'}, foo: 'bar'

    it 'should handle object key with range', ->
      schema = new KeySchema hash_key: 'identifier', range_key: 'name'
      schema.keyed_params(identifier: '2123123', name: 'fred').should.eql Key: {identifier: '2123123', name: 'fred'}

    it 'should handle object key with range and params', ->
      schema = new KeySchema hash_key: 'identifier', range_key: 'name'
      schema.keyed_params(identifier: '2123123', name: 'fred', {foo: 'bar'}).should.eql Key: {identifier: '2123123', name: 'fred'}, foo: 'bar'

  describe '.key_for', ->

    it 'should extract key from item no range', ->
      schema = new KeySchema hash_key: 'identifier'
      item = identifier: '12312', foo: 'bar', baz: 'quk'
      key = schema.key_for item, 'identifier'
      key.should.eql identifier: '12312'

    it 'should extract key from item with range', ->
      schema = new KeySchema hash_key: 'foo', range_key: 'baz'
      item = identifier: '12312', foo: 'bar', baz: 'quk'
      key = schema.key_for item
      key.should.eql foo: 'bar', baz: 'quk'

    it 'should use proided hash value', ->
      schema = new KeySchema hash_key: 'identifier'
      key = schema.key_for '12312', 'identifier'
      key.should.eql identifier: '12312'
