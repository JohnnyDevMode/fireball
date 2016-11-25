utils = require '../src/utils'

describe 'Utils Tests', ->

  describe '.key_and_params', ->

    it 'should handle simple key no params', ->
      utils.key_and_params('2123123').should.eql ['2123123', {}]

    it 'should handle object key no params', ->
      utils.key_and_params(identifier: '2123123').should.eql [identifier: '2123123', {}]

    it 'should handle array key no params', ->
      utils.key_and_params(['1234', '4321']).should.eql [['1234', '4321'], {}]

    it 'should handle simple key with params', ->
      utils.key_and_params('2123123', {foo: 'bar'}).should.eql ['2123123', {foo: 'bar'}]

    it 'should handle object key with params', ->
      utils.key_and_params(identifier: '2123123', {foo: 'bar'}).should.eql [{identifier: '2123123'}, {foo: 'bar'}]

    it 'should handle array key with params', ->
      utils.key_and_params(['1234', '4321'], {foo: 'bar'}).should.eql [['1234', '4321'], {foo: 'bar'}]

    it 'should handle array key with params', ->
      utils.key_and_params(['1234'], '4321').should.eql [['1234', '4321'], {}]

  describe '.key_for', ->

    it 'should extract key from item no range', ->
      item = identifier: '12312', foo: 'bar', baz: 'quk'
      key = utils.key_for item, 'identifier'
      key.should.eql identifier: '12312'

    it 'should extract key from item with range', ->
      item = identifier: '12312', foo: 'bar', baz: 'quk'
      key = utils.key_for item, 'foo', 'baz'
      key.should.eql foo: 'bar',  baz: 'quk'

    it 'should use proided hash value', ->
      key = utils.key_for '12312', 'identifier'
      key.should.eql identifier: '12312'

    it 'should use proided hash and range', ->
      key = utils.key_for ['12312', 'fred'], 'identifier', 'name'
      key.should.eql identifier: '12312', name: 'fred'

    it 'should use proided hash and range in array', ->
      key = utils.key_for [identifier: '12312', name: 'fred'], 'identifier', 'name'
      key.should.eql identifier: '12312', name: 'fred'
