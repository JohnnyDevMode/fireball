KeySchema = require '../src/key_schema'
keygen = require 'keygen'


describe 'Utils Tests', ->

  describe '@constructor', ->

    it 'should default hash_key and size', ->
      schema = new KeySchema()
      schema.hash_key.should.eql 'identifier'
      schema.key_size.should.eql keygen.large

    it 'should take hash_key and default size', ->
      schema = new KeySchema 'some_key'
      schema.hash_key.should.eql 'some_key'
      schema.key_size.should.eql keygen.large

    it 'should take hash_key and range and default size', ->
      schema = new KeySchema 'some_key', 'other_key'
      schema.range_key.should.eql 'other_key'
      schema.key_size.should.eql keygen.large

    it 'should take hash_keym range and size', ->
      schema = new KeySchema 'some_key', 'other_key', keygen.small
      schema.key_size.should.eql keygen.small

  describe '.keyed_params', ->

    it 'should handle simple key no params', ->
      schema = new KeySchema 'identifier'
      schema.keyed_params('2123123').should.eql Key: identifier: '2123123'

    it 'should handle simple key with params', ->
      schema = new KeySchema 'identifier'
      schema.keyed_params('2123123', {foo: 'bar'}).should.eql Key: {identifier: '2123123'}, foo: 'bar'

    it 'should handle simple key with range', ->
      schema = new KeySchema 'identifier', 'name'
      schema.keyed_params('2123123', 'fred').should.eql Key: {identifier: '2123123', name: 'fred'}

    it 'should handle simple key with range and params', ->
      schema = new KeySchema 'identifier', 'name'
      schema.keyed_params('2123123', 'fred', {foo: 'bar'}).should.eql Key: {identifier: '2123123', name: 'fred'}, foo: 'bar'

    it 'should handle object key no params', ->
      schema = new KeySchema 'identifier'
      schema.keyed_params(identifier: '2123123').should.eql {Key: identifier: '2123123'}

    it 'should handle object key with params', ->
      schema = new KeySchema 'identifier'
      schema.keyed_params(identifier: '2123123', {foo: 'bar'}).should.eql Key: {identifier: '2123123'}, foo: 'bar'

    it 'should handle object key with range', ->
      schema = new KeySchema 'identifier', 'name'
      schema.keyed_params(identifier: '2123123', name: 'fred').should.eql Key: {identifier: '2123123', name: 'fred'}

    it 'should handle object key with range and params', ->
      schema = new KeySchema 'identifier', 'name'
      schema.keyed_params(identifier: '2123123', name: 'fred', {foo: 'bar'}).should.eql Key: {identifier: '2123123', name: 'fred'}, foo: 'bar'

  describe '.key_for', ->

    it 'should extract key from item no range', ->
      schema = new KeySchema 'identifier'
      item = identifier: '12312', foo: 'bar', baz: 'quk'
      key = schema.key_for item, 'identifier'
      key.should.eql identifier: '12312'

    it 'should extract key from item with range', ->
      schema = new KeySchema 'foo', 'baz'
      item = identifier: '12312', foo: 'bar', baz: 'quk'
      key = schema.key_for item
      key.should.eql foo: 'bar', baz: 'quk'

    it 'should use proided hash value', ->
      schema = new KeySchema 'identifier'
      key = schema.key_for '12312', 'identifier'
      key.should.eql identifier: '12312'
