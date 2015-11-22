// helper utilities
'use strict'

// shift the decimal place to SVG coordinates (units * 1000)
// also round to 7 decimal places
var shift = function(number) {
  return Math.round(10000000000 * number) / 10000000
}

// create an attribute assignment for SVG
var attr = function(attr, val) {
  return (attr + '="' + val + '"')
}

var boundingRect = function(box, fill) {
  var xAttr = attr('x', shift(box[0])) + ' '
  var yAttr = attr('y', shift(box[1])) + ' '
  var widthAttr = attr('width', shift(box[2] - box[0])) + ' '
  var heightAttr = attr('height', shift(box[3] - box[1])) + ' '
  var fillAttr = attr('fill', fill)

  return '<rect ' + xAttr + yAttr + widthAttr + heightAttr + fillAttr + '/>'
}

var maskLayer = function(maskId, layer) {
  var maskUrl = 'url(#' + maskId + ')'
  var maskAttr = attr('mask', maskUrl)

  return '<g ' + maskAttr + '>' + layer + '</g>'
}

var startMask = function(maskId, box) {
  var mask = '<mask ' + attr('id', maskId) + ' fill="#000" stroke="#000">'
  mask += boundingRect(box, '#fff')

  return mask
}

module.exports = {
  shift: shift,
  attr: attr,
  boundingRect: boundingRect,
  maskLayer: maskLayer,
  startMask: startMask
}
