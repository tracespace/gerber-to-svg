// operate the plotter
'use strict'

var filter = require('lodash.filter')
var find = require('lodash.find')

var boundingBox = require('./_box')

var HALF_PI = Math.PI / 2
var TWO_PI = Math.PI * 2

// flash operation
// returns a bounding box for the operation
var flash = function(coord, tool, plotter) {
  // push the pad shape if needed
  if (!tool.flashed) {
    tool.flashed = true
    plotter.push({type: 'shape', tool: tool.code, shape: tool.pad})
  }

  plotter.push({type: 'pad', tool: tool.code, x: coord[0], y: coord[1]})
  return boundingBox.translate(tool.box, coord)
}

var drawArc = function(start, end, offset, tool, mode, arc, region, epsilon, pathGraph) {
  // get the radius of the arc from the offsets
  var r = Math.sqrt(Math.pow(offset[0], 2) + Math.pow(offset[1], 2))

  // potential candidates for the arc center
  // in single quadrant mode, all offset signs are implicit, so we need to check a few
  var centerCandidates = []
  var xCandidates = []
  var yCandidates = []

  if (offset[0] && (arc === 's')) {
    xCandidates.push(start[0] + offset[0], start[0] - offset[0])
  }
  else {
    xCandidates.push(start[0] + offset[0])
  }

  if (offset[1] && (arc === 's')) {
    yCandidates.push(start[1] + offset[1], start[1] - offset[1])
  }
  else {
    yCandidates.push(start[1] + offset[1])
  }

  for (var i = 0; i < xCandidates.length; i++) {
    for (var j = 0; j < yCandidates.length; j++) {
      centerCandidates.push([xCandidates[i], yCandidates[j]])
    }
  }

  // find valid centers by comparing the distance to start and end for equality with the radius
  var validCenters = filter(centerCandidates, function(c) {
    var startDist = Math.sqrt(Math.pow(c[0] - start[0], 2) + Math.pow(c[1] - start[1], 2))
    var endDist = Math.sqrt(Math.pow(c[0] - end[0], 2) + Math.pow(c[1] - end[1], 2))

    return ((Math.abs(startDist - r) <= epsilon) && (Math.abs(endDist - r) <= epsilon))
  })

  // now use the sweep direction to find the correct center of the (at most) two valid centers
  var center = (arc === 's') ? find(validCenters, function(c) {
    var dyStart = start[1] - c[1]
    var dxStart = start[0] - c[0]
    var dyEnd = end[1] - c[1]
    var dxEnd = end[0] - c[0]

    var thetaStart = Math.atan2(dyStart, dxStart)
    var thetaEnd = Math.atan2(dyEnd, dxEnd)

    thetaStart = (thetaStart >= 0) ? thetaStart : (thetaStart + TWO_PI)
    thetaEnd = (thetaEnd >= 0) ? thetaEnd : (thetaEnd + TWO_PI)

    // console.log(c)
    // console.log(thetaStart, thetaEnd)
    // in clockwise, start must be greater than end unless it sweeps over the origin
    if (
    (mode === 'cw') &&
    ((thetaStart > thetaEnd) || (Math.abs(thetaStart + TWO_PI - thetaEnd) <= HALF_PI))) {
      return true
    }

    if (
    (mode === 'ccw') &&
    ((thetaEnd > thetaStart) || (Math.abs(thetaEnd + TWO_PI - thetaStart) <= HALF_PI))) {
      return true
    }

    return false
  }) : validCenters[0]

  if (center != null) {
    pathGraph.add({
      type: 'arc',
      start: start,
      end: end,
      center: center,
      radius: r,
      dir: mode
    })
  }

  return boundingBox.new()
  //
  //       # adjust angles so math comes out right
  //       # in cw, the angle of the start should always be greater than the end
  //       if @mode is 'cw' and thetaS < thetaE
  //         thetaS += TWO_PI
  //       # in ccw, the start angle should be less than the end angle
  //       else if @mode is 'ccw' and thetaE < thetaS
  //         thetaE += TWO_PI
  //
  //       # calculate the sweep angle (abs value for cw)
  //       theta = Math.abs(thetaE - thetaS)
  //       # in single quadrant mode, center is good if it's less than 90
  //       if @quad is 's' and theta <= HALF_PI
  //         cen = c
  //       else if @quad is 'm'
  //         # if the sweep angle is >= 180, then its an svg large arc
  //         if theta >= Math.PI then large = 1
  //         # take the center
  //         cen = {x: c.x, y: c.y}
  //
  //       # break the loop if we've found a valid center
  //       if cen? then break
}

var drawLine = function(start, end, tool, region, pathGraph) {
  pathGraph.add({type: 'line', start: start, end: end})

  if (!region) {
    var startBox = boundingBox.translate(tool.box, start)
    var endBox = boundingBox.translate(tool.box, end)
    return boundingBox.add(startBox, endBox)
  }

  var box = boundingBox.new()
  box = boundingBox.addPoint(box, start)
  box = boundingBox.addPoint(box, end)
  return box
}

// interpolate operation
// returns a bounding box for the operation
var interpolate = function(start, end, offset, tool, mode, arc, region, epsilon, pathGraph) {
  if (mode === 'i') {
    return drawLine(start, end, tool, region, pathGraph)
  }

  return drawArc(start, end, offset, tool, mode, arc, region, epsilon, pathGraph)
}

// takes the start point, the op type, the op coords, the tool, and the push function
// returns the new plotter position
var operate = function(
  type, coord, start, tool, mode, arc, region, pathGraph, epsilon, plotter) {

  var end = [
    ((coord.x != null) ? coord.x : start[0]),
    ((coord.y != null) ? coord.y : start[1])
  ]

  var offset = [
    ((coord.i != null) ? coord.i : 0),
    ((coord.j != null) ? coord.j : 0)
  ]

  var box
  switch (type) {
    case 'flash':
      box = flash(end, tool, plotter)
      break

    case 'int':
      box = interpolate(
        start, end, offset, tool, mode, arc, region, epsilon, pathGraph)
      break

    default:
      box = boundingBox.new()
      break
  }

  return {
    pos: end,
    box: box
  }
}

module.exports = operate
