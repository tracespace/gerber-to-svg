// reduce a shape array into a string to place is defs
'use strict'

var util = require('./_util')
var shift = util.shift
var createMask = util.createMask
var maskLayer = util.maskLayer

var element = function(tag, attr) {
  return {tag: tag, attr: attr}
}

var circle = function(cx, cy, r, width) {
  var attr = {
    cx: shift(cx),
    cy: shift(cy),
    r: shift(r)
  }

  if (width != null) {
    attr['stroke-width'] = shift(width)
    attr.fill = 'none'
  }

  return element('circle', attr)
}

var rect = function(cx, cy, r, width, height) {
  var attr = {
    x: shift(cx - width / 2),
    y: shift(cy - height / 2),
    width: shift(width),
    height: shift(height)
  }

  if (r) {
    attr.rx = shift(r)
    attr.ry = shift(r)
  }

  return element('rect', attr)
}

var poly = function(points) {
  var pointsAttr = points.map(function(point) {
    return point.map(shift).join(',')
  }).join(' ')

  return element('polygon', {points: pointsAttr})
}

var clip = function(id, shapes, ring, createElement) {
  var maskId = id + '_mask'
  var maskUrl = 'url(#' + maskId + ')'

  var circleNode = circle(ring.cx, ring.cy, ring.r, ring.width)

  var mask = createElement(
    'mask',
    {id: maskId, stroke: '#fff'},
    [createElement(circleNode.tag, circleNode.attr)])

  var groupChildren = shapes.map(function(shape) {
    var node = (shape.type === 'rect')
      ? rect(shape.cx, shape.cy, shape.r, shape.width, shape.height)
      : poly(shape.points)

    return createElement(node.tag, node.attr)
  })

  var layer = createElement('g', {id: id, mask: maskUrl}, groupChildren)

  return {mask: mask, layer: layer}
}

module.exports = function reduceShapeArray(prefix, code, shapeArray, createElement) {
  var id = prefix + '_pad-' + code
  var maskIdPrefix = id + '_'

  var image = shapeArray.reduce(function(result, shape) {
    var svg

    switch (shape.type) {
      case 'circle':
        svg = circle(shape.cx, shape.cy, shape.r)
        break

      case 'ring':
        svg = circle(shape.cx, shape.cy, shape.r, shape.width)
        break

      case 'rect':
        svg = rect(shape.cx, shape.cy, shape.r, shape.width, shape.height)
        break

      case 'poly':
        svg = poly(shape.points)
        break

      case 'clip':
        var clipNodes = clip(id, shape.shape, shape.clip, createElement)

        result.layers.push(clipNodes.layer)
        result.masks.push(clipNodes.mask)
        break

      case 'layer':
        result.count++
        result.last = shape.polarity

        // if the polarity is clear, wrap the group and start a mask
        if (shape.polarity === 'clear') {
          var nextMaskId = maskIdPrefix + result.count

          result.maskId = nextMaskId
          result.maskBox = shape.box.slice(0)
          result.maskChildren = []
          result.layers = [maskLayer(nextMaskId, result.layers, createElement)]
        }
        else {
          var mask = createMask(
            result.maskId,
            result.maskBox,
            result.maskChildren,
            createElement)

          result.masks.push(mask)
        }
        break
    }

    if (svg) {
      if (shapeArray.length === 1) {
        svg.attr.id = id
      }

      var svgElement = createElement(svg.tag, svg.attr)

      if (result.last === 'dark') {
        result.layers.push(svgElement)
      }
      else {
        result.maskChildren.push(svgElement)
      }
    }

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
      image.maskChildren,
      createElement))
  }

  if (shapeArray.length > 1) {
    image.layers = createElement('g', {id: id}, image.layers)
  }

  return image.masks.concat(image.layers)
}
