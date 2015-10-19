// returns a pad shape array given a tool definition
'use strict'

var boundingBox = require('./_box')

var circle = function(dia, cx, cy) {
  var r = dia / 2
  cx = cx || 0
  cy = cy || 0

  return {
    shape: {type: 'circle', cx: cx, cy: cy, r: (dia / 2)},
    box: [-r + cx, -r + cy, r + cx, r + cy]
  }
}

var rect = function(width, height, r, cx, cy) {
  cx = cx || 0
  cy = cy || 0
  r = r || 0

  var hWidth = width / 2
  var hHeight = height / 2
  return {
    shape: {type: 'rect', cx: cx, cy: cy, rx: r, ry: r, width: width, height: height},
    box: [-hWidth + cx, -hHeight + cy, hWidth + cx, hHeight + cy]
  }
}

var regularPolygon = function(dia, nPoints, rot, cx, cy) {
  cx = cx || 0
  cy = cy || 0

  var points = []
  var box = boundingBox.new()

  var r = dia / 2
  var offset = rot * Math.PI / 180
  var step = 2 * Math.PI / nPoints
  var theta
  var x
  var y
  for (var n = 0; n < nPoints; n++) {
    theta = step * n + offset
    x = r * Math.cos(theta)
    y = r * Math.sin(theta)

    box = boundingBox.add(box, [x, y, x, y])
    points.push([x, y])
  }

  return {
    shape: {type: 'poly', cx: cx, cy: cy, points: points},
    box: box
  }
}

var padShape = function(tool) {
  var shape = []
  var box = boundingBox.new()
  var toolShape = tool.shape
  var params = tool.val
  var holeShape
  var shapeAndBox

  if (toolShape === 'circle') {
    shapeAndBox = circle(params[0])
  }

  else if (toolShape === 'rect') {
    shapeAndBox = rect(params[0], params[1])
  }

  else if (toolShape === 'obround') {
    shapeAndBox = rect(params[0], params[1], (Math.min(params[0], params[1]) / 2))
  }

  else if (toolShape === 'poly') {
    shapeAndBox = regularPolygon(params[0], params[1], params[2])
  }

  if (shapeAndBox) {
    shape.push(shapeAndBox.shape)
    box = boundingBox.add(box, shapeAndBox.box)
  }

  if (tool.hole.length) {
    holeShape = (tool.hole.length === 1) ?
      circle(tool.hole[0]).shape :
      rect(tool.hole[0], tool.hole[1]).shape

    shape.push({type: 'layer', polarity: 'clear'}, holeShape)
  }

  return {shape: shape, box: box}
}

module.exports = padShape
