// creates the SVG for a pad flash
'use strict'

var util = require('./_util')
var shift = util.shift
var attr = util.attr

var flashPad = function(prefix, tool, x, y) {
  var toolId = '#' + prefix + '_pad-' + tool
  var xlinkAttr = attr('xlink:href', toolId)
  var xAttr = attr('x', shift(x))
  var yAttr = attr('y', shift(y))

  return '<use ' + xlinkAttr + ' ' + xAttr + ' ' + yAttr + '/>'
}

module.exports = flashPad
