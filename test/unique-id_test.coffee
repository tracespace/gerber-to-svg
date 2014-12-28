id = require '../src/unique-id'
expect = require('chai').expect

describe 'unique id generator', ->
  it 'should be able to generate a bunch of unique ids', ->
    prev = null
    counter = 0
    while counter++ < 50
      uniqueId = id()
      expect( uniqueId ).to.not.equal prev
      prev = uniqueId

  it 'should keep those ids unique even in different closures', ->
    counter = 0
    uniqueId = id()
    do (uniqueId) ->
      otherIdFunc = require '../src/unique-id'
      otherId = otherIdFunc()
      expect( otherId ).to.not.equal uniqueId
