mapper = require '../src/param_mapper'

describe 'Param Mapper Tests', ->

  describe '.ensure_prefix', ->

    it 'should prefix params', ->
      params = param: 'value', param2: 'value2'
      actual = mapper.ensure_prefix params, '-'
      actual.should.eql '-param': 'value', '-param2': 'value2'

    it 'should not double prefix params', ->
      params = '-param': 'value', '-param2': 'value2'
      actual = mapper.ensure_prefix params, '-'
      actual.should.eql '-param': 'value', '-param2': 'value2'

  describe '.expression_names', ->

    it 'should prefix names', ->
      params = param: 'value', param2: 'value2'
      actual = mapper.expression_names params
      actual.should.eql '#param': 'value', '#param2': 'value2'

    it 'should not double prefix names', ->
      params = '#param': 'value', '#param2': 'value2'
      actual = mapper.expression_names params
      actual.should.eql '#param': 'value', '#param2': 'value2'

  describe '.expression_values', ->

    it 'should prefix values', ->
      params = param: 'value', param2: 'value2'
      actual = mapper.expression_values params
      actual.should.eql ':param': 'value', ':param2': 'value2'

    it 'should not double prefix names', ->
      params = ':param': 'value', ':param2': 'value2'
      actual = mapper.expression_values params
      actual.should.eql ':param': 'value', ':param2': 'value2'

  describe '.map_parameters', ->

    it 'should map param keys', ->
      params =
        condition: 'con'
        update: 'upd'
        projection: 'pro'
        filter: 'fil'
        key_condition: 'key'
        index: 'ind'
        limit: 'lim'
        forward: 'for'
      expected =
        ConditionExpression: 'con'
        UpdateExpression: 'upd'
        ProjectionExpression: 'pro'
        FilterExpression: 'fil'
        KeyConditionExpression: 'key'
        IndexName: 'ind'
        Limit: 'lim'
        ScanIndexForward: 'for'
      actual = mapper.map_parameters params
      actual.should.eql expected

    it 'should map names no prefixing', ->
      params = names: {'#foo': 'bar', '#baz': 'qak'}
      expected =
        ExpressionAttributeNames: '#foo': 'bar', '#baz': 'qak'
      actual = mapper.map_parameters params
      actual.should.eql expected

    it 'should map names with prefixing', ->
      params = names: {foo: 'bar', baz: 'qak'}
      expected =
        ExpressionAttributeNames: '#foo': 'bar', '#baz': 'qak'
      actual = mapper.map_parameters params
      actual.should.eql expected

    it 'should map values no prefixing', ->
      params = values: {':foo': 'bar', ':baz': 'qak'}
      expected =
        ExpressionAttributeValues: ':foo': 'bar', ':baz': 'qak'
      actual = mapper.map_parameters params
      actual.should.eql expected

    it 'should map values with prefixing', ->
      params = values: {foo: 'bar', baz: 'qak'}
      expected =
        ExpressionAttributeValues: ':foo': 'bar', ':baz': 'qak'
      actual = mapper.map_parameters params
      actual.should.eql expected
