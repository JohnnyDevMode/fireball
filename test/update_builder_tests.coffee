builder = require '../src/update_builder'

describe 'Patch Builder Tests', ->

  it 'should create set param', ->
    changes = thing: 'asdads'
    params = builder.patch changes
    params.update.should.eql 'set #thing = :thing'
    params.names.should.eql '#thing': 'thing'
    params.values.should.eql ':thing': 'asdads'

  it 'should create set multiple params', ->
    changes = thing: 'asdads', other_thing: '231231'
    params = builder.patch changes
    params.update.should.eql 'set #thing = :thing, #other_thing = :other_thing'
    params.names.should.eql '#thing': 'thing', '#other_thing': 'other_thing'
    params.values.should.eql ':thing': 'asdads', ':other_thing': '231231'
