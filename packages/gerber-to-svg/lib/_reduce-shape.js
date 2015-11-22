// reduce a shape array into a string to place is defs
'use strict'

var reduce = require('lodash.reduce')

var util = require('./_util')
var shift = util.shift
var attr = util.attr
var startMask = util.startMask
var maskLayer = util.maskLayer

var circle = function(id, cx, cy, r, width) {
  var idAttr = (id) ? (attr('id', id) + ' ') : ''
  var cxAttr = attr('cx', shift(cx)) + ' '
  var cyAttr = attr('cy', shift(cy)) + ' '
  var rAttr = attr('r', shift(r))
  var widthAttr = (width) ? (' ' + attr('stroke-width', shift(width))) : ''
  widthAttr += (width) ? (' ' + attr('fill', 'none')) : ''

  return '<circle ' + idAttr + cxAttr + cyAttr + rAttr + widthAttr + '/>'
}

var rect = function(id, cx, cy, r, width, height) {
  var idAttr = (id) ? (attr('id', id) + ' ') : ''
  var xAttr = attr('x', shift(cx - width / 2)) + ' '
  var yAttr = attr('y', shift(cy - height / 2)) + ' '
  var widthAttr = attr('width', shift(width)) + ' '
  var heightAttr = attr('height', shift(height))

  r = shift(r)
  var rAttr =  (r) ? (attr('rx', r) + ' ' + attr('ry', r) + ' ') : ''

  return '<rect ' + idAttr + xAttr + yAttr + rAttr + widthAttr + heightAttr + '/>'
}

var polyPoints = function(result, point, i, points) {
  var pointString = shift(point[0]) + ',' + shift(point[1])
  return (result + pointString + ((i < (points.length - 1)) ? ' ' : ''))
}

var poly = function(id, points) {
  var idAttr = (id) ? (attr('id', id) + ' ') : ''
  var pointsAttr = attr('points', reduce(points, polyPoints, ''))
  return '<polygon ' + idAttr + pointsAttr + '/>'
}

var clip = function(id, shapes, ring) {
  var maskId = id + '_mask'
  var mask = '<mask ' + attr('id', maskId) + ' ' + attr('stroke', '#fff') + '>'
  mask += circle(null, ring.cx, ring.cy, ring.r, ring.width) + '</mask>'


  var svg = '<g ' + attr('id', id) + ' ' + attr('mask', 'url(#' + maskId + ')') + '>'
  svg = reduce(shapes, function(result, shape) {
    if (shape.type === 'rect') {
      return (result + rect(null, shape.cx, shape.cy, shape.r, shape.width, shape.height))
    }

    return (result + poly(null, shape.points))
  }, svg)

  return mask + svg + '</g>'
}

var reduceShapeArray = function(prefix, code, shapeArray) {
  var id = prefix + '_pad-' + code
  var maskIdPrefix = id + '_'
  var start = ''
  var end = ''

  if (shapeArray.length > 1) {
    start = '<g ' + attr('id', id) + '>'
    end = '</g>'
    id = null
  }

  var image = reduce(shapeArray, function(result, shape) {
    var svg

    switch (shape.type) {
      case 'circle':
        svg = circle(id, shape.cx, shape.cy, shape.r)
        break

      case 'ring':
        svg = circle(id, shape.cx, shape.cy, shape.r, shape.width)
        break

      case 'rect':
        svg = rect(id, shape.cx, shape.cy, shape.r, shape.width, shape.height)
        break

      case 'poly':
        svg = poly(id, shape.points)
        break

      case 'clip':
        svg = clip(id, shape.shape, shape.clip)
        break

      case 'layer':
        result.count++
        result.last = shape.polarity
        // if the polarity is clear, wrap the group and start a mask
        if (shape.polarity === 'clear') {
          var nextMaskId = maskIdPrefix + result.count
          result.masks += startMask(nextMaskId, shape.box)
          result.layers = maskLayer(nextMaskId, result.layers)
        }
        else {
          result.masks += '</mask>'
        }
        return result
    }

    if (result.last === 'dark') {
      result.layers += svg
    }
    else {
      result.masks += svg
    }

    return result
  }, {count: 0, last: 'dark', layers: '', masks: ''})

  if (image.last === 'clear') {
    image.masks += '</mask>'
  }

  return image.masks + start + image.layers + end
}

module.exports = reduceShapeArray
