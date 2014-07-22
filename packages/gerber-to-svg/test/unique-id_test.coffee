id = require '../src/unique-id'

describe 'unique id generator', ->
  it 'should be able to generate a bunch of unique ids', ->
    prev = null
    counter = 0
    while counter++ < 200
      uniqueId = id()
      uniqueId.should.not.equal prev
      prev = uniqueId

  it 'should keep those ids unique even in different closures', ->
    counter = 0
    while counter++ < 200
      uniqueId = id()
      do (uniqueId) ->
        otherIdFunc = require '../src/unique-id'
        otherId = otherIdFunc()
        otherId.should.not.equal uniqueId
