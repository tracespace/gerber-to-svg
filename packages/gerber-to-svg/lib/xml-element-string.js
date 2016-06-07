// create an xml node string
'use strict'

var isString = require('lodash.isstring')

module.exports = function createXmlString(tag, attributes, children) {
  var childrenString = ''

  if (Array.isArray(children)) {
    childrenString = children.join('')
  }
  else if (isString(children)) {
    childrenString = children
  }

  var start = '<' + tag

  var middle = Object.keys(attributes).reduce(function(result, key) {
    var value = attributes[key]
    var attr = (value != null)
      ? (' ' + key + '="' + value + '"')
      : ''

    return result + attr
  }, '')

  var end = (childrenString)
    ? '>' + childrenString + '</' + tag + '>'
    : '/>'

  return start + middle + end
}
