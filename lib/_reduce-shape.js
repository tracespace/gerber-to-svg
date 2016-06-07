// reduce a shape array into a string to place is defs
'use strict'

var element = require('./xml-element-string')
var util = require('./_util')
var shift = util.shift
var createMask = util.createMask
var maskLayer = util.maskLayer

var circle = function(id, cx, cy, r, width) {
  width = (width != null) ? shift(width) : null
  var fill = (width != null) ? 'none' : null

  return element('circle', {
    id: id,
    cx: shift(cx),
    cy: shift(cy),
    r: shift(r),
    'stroke-width': width,
    fill: fill
  })
}

var rect = function(id, cx, cy, r, width, height) {
  r = (r) ? shift(r) : null

  return element('rect', {
    id: id,
    x: shift(cx - width / 2),
    y: shift(cy - height / 2),
    rx: r,
    ry: r,
    width: shift(width),
    height: shift(height)
  })
}

var polyPoints = function(result, point, i, points) {
  var pointString = shift(point[0]) + ',' + shift(point[1])
  return (result + pointString + ((i < (points.length - 1)) ? ' ' : ''))
}

var poly = function(id, points) {
  return element('polygon', {
    id: id,
    points: points.reduce(polyPoints, '')
  })
}

var clip = function(id, shapes, ring) {
  var maskId = id + '_mask'
  var maskUrl = 'url(#' + maskId + ')'

  var mask = element(
    'mask',
    {id: maskId, stroke: '#fff'},
    circle(null, ring.cx, ring.cy, ring.r, ring.width))

  var groupChildren = shapes.map(function(shape) {
    return (shape.type === 'rect')
      ? rect(null, shape.cx, shape.cy, shape.r, shape.width, shape.height)
      : poly(null, shape.points)
  })

  var group = element('g', {id: id, mask: maskUrl}, groupChildren)

  return mask + group
}

var reduceShapeArray = function(prefix, code, shapeArray) {
  var padId = prefix + '_pad-' + code
  var maskIdPrefix = padId + '_'

  var image = shapeArray.reduce(function(result, shape) {
    var svg
    var id = (shapeArray.length === 1) ? padId : null

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
          result.maskId = nextMaskId
          result.maskBox = shape.box.slice(0)
          result.layers = [maskLayer(nextMaskId, result.layers)]
        }
        else {
          var mask = createMask(
            result.maskId,
            result.maskBox,
            result.maskChildren)

          result.masks.push(mask)
          result.maskChildren = []
        }

        return result
    }

    var current = (result.last === 'dark')
      ? result.layers
      : result.maskChildren

    current.push(svg)

    return result
  }, {
    count: 0,
    last: 'dark',
    layers: [],
    maskId: '',
    maskBox: [],
    maskChildren: [],
    masks: []})

  if (image.last === 'clear') {
    image.masks.push(createMask(
      image.maskId,
      image.maskBox,
      image.maskChildren))
  }

  if (shapeArray.length > 1) {
    image.layers = element('g', {id: padId}, image.layers.slice(0))
  }

  return image.masks.concat(image.layers)
}

module.exports = reduceShapeArray
