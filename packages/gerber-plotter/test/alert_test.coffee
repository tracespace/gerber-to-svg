# test suite for alert module
alert = require '../src/alert'

describe 'alert module', ->
  it 'should allow the warning stream to be set', ->
    buf = ''
    w = (message) ->
      buf += message
    alert.setWarn w
    alert.warn 'warning test'
    buf.should.eql 'warning test'
