// returns a pad shape array given a tool definition
'use strict'

var reduce = require('lodash.reduce')

var boundingBox = require('./_box')

var roundToPrecision = function(number) {
  return Math.round(number * 100000000) / 100000000
}

var degreesToRadians = function(degrees) {
  return degrees * Math.PI / 180
}

var rotatePointAboutOrigin = function(point, rot) {
  rot = degreesToRadians(rot)
  var sin = Math.sin(rot)
  var cos = Math.cos(rot)
  var x = point[0]
  var y = point[1]

  return [
    roundToPrecision(x * cos - y * sin),
    roundToPrecision(x * sin + y * cos)
  ]
}

var circle = function(dia, cx, cy, rot) {
  var r = dia / 2
  cx = cx || 0
  cy = cy || 0

  // rotate cx and cy if necessary
  if (rot && (cx || cy)) {
    var rotatedCenter = rotatePointAboutOrigin([cx, cy], rot)
    cx = rotatedCenter[0]
    cy = rotatedCenter[1]
  }

  return {
    shape: {type: 'circle', cx: cx, cy: cy, r: (dia / 2)},
    box: [-r + cx, -r + cy, r + cx, r + cy]
  }
}

var vect = function(x1, y1, x2, y2, width, rot) {
  // rotate the endpoints if necessary
  if (rot) {
    var start = rotatePointAboutOrigin([x1, y1], rot)
    var end = rotatePointAboutOrigin([x2, y2], rot)
    x1 = start[0]
    y1 = start[1]
    x2 = end[0]
    y2 = end[1]
  }

  var m = (y2 - y1) / (x2 - x1)
  var hWidth = width / 2
  var sin = hWidth
  var cos = hWidth
  if (m !== Infinity) {
    sin *= m / Math.sqrt(1 + Math.pow(m, 2))
    cos *= 1 / Math.sqrt(1 + Math.pow(m, 2))
  }
  else {
    cos = 0
  }

  // add all four corners to the ponts array and the box
  var points = []
  points.push([roundToPrecision(x1 + sin), roundToPrecision(y1 - cos)])
  points.push([roundToPrecision(x2 + sin), roundToPrecision(y2 - cos)])
  points.push([roundToPrecision(x2 - sin), roundToPrecision(y2 + cos)])
  points.push([roundToPrecision(x1 - sin), roundToPrecision(y1 + cos)])

  var box = reduce(points, function(result, p) {
    return boundingBox.addPoint(result, p)
  }, boundingBox.new())

  return {
    shape: {type: 'poly', points: points},
    box: box
  }
}

var rect = function(width, height, r, cx, cy, rot) {
  cx = cx || 0
  cy = cy || 0
  r = r || 0
  rot = rot || 0

  var hWidth = width / 2
  var hHeight = height / 2

  if (rot) {
    var x1 = cx - hWidth
    var x2 = cx + hWidth
    var y1 = cy
    var y2 = cy

    return vect(x1, y1, x2, y2, height, rot)
  }

  return {
    shape: {type: 'rect', cx: cx, cy: cy, r: r, width: width, height: height},
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

    box = boundingBox.addPoint(box, [x, y])
    points.push([x, y])
  }

  return {
    shape: {type: 'poly', points: points},
    box: box
  }
}

var runMacro = function(mods, blocks) {
  var emptyMacro = {shape: [], box: boundingBox.new()}

  return reduce(blocks, function(result, block) {
    var shapeAndBox

    switch (block.type) {
      case 'circle':
        shapeAndBox = circle(block.dia, block.cx, block.cy, block.rot)
        break

      case 'vect':
        shapeAndBox = vect(
          block.x1, block.y1, block.x2, block.y2, block.width, block.rot)
        break

      case 'rect':
        shapeAndBox = rect(block.width, block.height, 0, block.cx, block.cy, block.rot)
        break

      default:
        return result
    }

    return {
      shape: result.shape.concat(shapeAndBox.shape),
      box: boundingBox.add(result.box, shapeAndBox.box)
    }
  }, emptyMacro)
}

var padShape = function(tool, macros) {
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

  // else we got a macro
  // run the macro and return
  else {
    return runMacro({}, macros[toolShape])
  }

  // if we didn't return, we have a standard tool, so carry on accordingly
  shape.push(shapeAndBox.shape)
  box = boundingBox.add(box, shapeAndBox.box)

  if (tool.hole.length) {
    holeShape = (tool.hole.length === 1) ?
      circle(tool.hole[0]).shape :
      rect(tool.hole[0], tool.hole[1]).shape

    shape.push({type: 'layer', polarity: 'clear'}, holeShape)
  }

  return {shape: shape, box: box}
}

module.exports = padShape
