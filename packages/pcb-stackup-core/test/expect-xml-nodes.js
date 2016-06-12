// helper to expect an chain of element calls
'use strict'

var expect = require('chai').expect

var findCall = function(element, tag, attr, children) {
  var i
  var call
  var called

  for (i = 0; i < element.callCount; i++) {
    call = element.getCall(i)
    called = (!children)
      ? call.calledWith(tag, attr)
      : call.calledWith(tag, attr, children)

    if (called) {
      return call
    }
  }
}

// element is a sinon spy, expectations is an array of expectations of {tag, attr, children}
// children is an array of indices of return values from expectations
module.exports = function expectXmlNodes(element, expectations) {
  var returnValues = []

  expectations.forEach(function(expectation) {
    var tag = expectation.tag
    var attr = expectation.attr
    var children = expectation.children

    if (children) {
      children = children.map(function(index) {
        return returnValues[index]
      })
    }

    var call = findCall(element, tag, attr, children)
    var msg = tag + ' with attr ' + JSON.stringify(attr) + ' and children ' + children

    expect(call, msg).to.exist
    returnValues.push(call.returnValue)
  })

  return returnValues
}
