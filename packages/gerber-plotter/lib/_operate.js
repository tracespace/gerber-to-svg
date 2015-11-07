// operate the plotter
'use strict'

var filter = require('lodash.filter')
var reduce = require('lodash.reduce')
var forEach = require('lodash.foreach')

var boundingBox = require('./_box')

var HALF_PI = Math.PI / 2
var PI = Math.PI
var TWO_PI = Math.PI * 2
var THREE_HALF_PI = 3 * Math.PI / 2

// flash operation
// returns a bounding box for the operation
var flash = function(coord, tool, plotter) {
  plotter._finishPath()

  // push the pad shape if needed
  if (!tool.flashed) {
    tool.flashed = true
    plotter.push({type: 'shape', tool: tool.code, shape: tool.pad})
  }

  plotter.push({type: 'pad', tool: tool.code, x: coord[0], y: coord[1]})
  return boundingBox.translate(tool.box, coord)
}

// given a start, end, direction, arc quadrant mode, and list of potential centers, find the
// angles of the start and end points, the sweep angle, and the center
var findCenterAndAngles = function(start, end, mode, arc, centers) {
  var thetaStart
  var thetaEnd
  var sweep
  var candidate
  var center
  while (center == null && centers.length > 0) {
    candidate = centers.pop()
    thetaStart = Math.atan2(start[1] - candidate[1], start[0] - candidate[0])
    thetaEnd = Math.atan2(end[1] - candidate[1], end[0] - candidate[0])

    // in clockwise mode, ensure the start is greater than the end and check the sweep
    if (mode === 'cw') {
      thetaStart = (thetaStart >= thetaEnd) ? thetaStart : (thetaStart + TWO_PI)
    }
    // do the opposite for counter-clockwise
    else {
      thetaEnd = (thetaEnd >= thetaStart) ? thetaEnd : (thetaEnd + TWO_PI)
    }

    sweep = Math.abs(thetaStart - thetaEnd)

    // in single quadrant mode, the center is only valid if the sweep is less than 90 degrees
    if (arc === 's') {
      if (sweep <= HALF_PI) {
        center = candidate
      }
    }

    // in multiquandrant mode there's only one candidate; we're within spec to assume it's good
    else {
      center = candidate
    }
  }

  if (center == null) {
    return undefined
  }

  // ensure the thetas are [0, TWO_PI)
  thetaStart = (thetaStart >= 0) ? thetaStart : thetaStart + TWO_PI
  thetaStart = (thetaStart < TWO_PI) ? thetaStart : thetaStart - TWO_PI
  thetaEnd = (thetaEnd >= 0) ? thetaEnd : thetaEnd + TWO_PI
  thetaEnd = (thetaEnd < TWO_PI) ? thetaEnd : thetaEnd - TWO_PI

  return {
    center: center,
    sweep: sweep,
    start: start.concat(thetaStart),
    end: end.concat(thetaEnd)
  }
}

var arcBox = function(startPoint, endPoint, center, r, region, tool, dir) {
  var start
  var end

  // normalize direction to counter-clockwise
  if (dir === 'cw') {
    start = endPoint[2]
    end = startPoint[2]
  }
  else {
    start = startPoint[2]
    end = endPoint[2]
  }

  // get bounding box definition points
  var points = [startPoint, endPoint]

  // check for sweep past 0 degeres
  if (start > end) {
    points.push([center[0] + r, center[1]])
  }

  // check for sweep past 90 degrees
  if (start < HALF_PI && end > HALF_PI) {
    points.push([center[0], center[1] + r])
  }

  // check for sweep past 180 degrees
  if (start < PI && end > PI) {
    points.push([center[0] - r, center[1]])
  }

  // check for sweep past 270 degrees
  if (start < THREE_HALF_PI && end > THREE_HALF_PI) {
    points.push([center[0], center[1] - r])
  }

  return reduce(points, function(result, m) {
    if (!region) {
      var mBox = boundingBox.translate(tool.box, m)
      return boundingBox.add(result, mBox)
    }

    return boundingBox.addPoint(result, m)
  }, boundingBox.new())
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

  var cenAndAngles = findCenterAndAngles(start, end, mode, arc, validCenters)

  // edge case: matching start and end in multi quadrant mode is a full circle
  if ((arc === 'm') && (start[0] === end[0]) && (start[1] === end[1])) {
    cenAndAngles.sweep = 2 * Math.PI
  }

  var box = boundingBox.new()
  if (cenAndAngles != null) {
    pathGraph.add({
      type: 'arc',
      start: cenAndAngles.start,
      end: cenAndAngles.end,
      center: cenAndAngles.center,
      sweep: cenAndAngles.sweep,
      radius: r,
      dir: mode
    })

    box = arcBox(cenAndAngles.start, cenAndAngles.end, cenAndAngles.center, r,  region, tool, mode)
  }

  return box
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

// interpolate a rectangle and emit the fill immdeiately
var interpolateRect = function(start, end, tool, pathGraph, plotter) {
  var hWidth = tool.trace[0] / 2
  var hHeight = tool.trace[1] / 2
  var theta = Math.atan2(end[1] - start[1], end[0] - start[0])

  var sXMin = start[0] - hWidth
  var sXMax = start[0] + hWidth
  var sYMin = start[1] - hHeight
  var sYMax = start[1] + hHeight
  var eXMin = end[0] - hWidth
  var eXMax = end[0] + hWidth
  var eYMin = end[1] - hHeight
  var eYMax = end[1] + hHeight

  var points = []

  // no movement
  if (start[0] === end[0] && start[1] === end[1]) {
    points.push([sXMin, sYMin], [sXMax, sYMin], [sXMax, sYMax], [sXMin, sYMax])
  }

  // check for first quadrant move
  else if ((theta >= 0 && theta < HALF_PI)) {
    points.push(
      [sXMin, sYMin],
      [sXMax, sYMin],
      [eXMax, eYMin],
      [eXMax, eYMax],
      [eXMin, eYMax],
      [sXMin, sYMax])
  }

  // check for second quadrant move
  else if ((theta >= HALF_PI && theta < PI)) {
    points.push(
      [sXMax, sYMin],
      [sXMax, sYMax],
      [eXMax, eYMax],
      [eXMin, eYMax],
      [eXMin, eYMin],
      [sXMin, sYMin])
  }


  //       if 0 <= theta < HALF_PI
  //         @path.push 'M',sxm,sym,sxp,sym,exp,eym,exp,eyp,exm,eyp,sxm,syp,'Z'
  //       # quadrant II
  //       else if HALF_PI <= theta <= Math.PI
  //         @path.push 'M',sxm,sym,sxp,sym,sxp,syp,exp,eyp,exm,eyp,exm,eym,'Z'
  //       # quadrant III
  //       else if -Math.PI <= theta < -HALF_PI
  //         @path.push 'M',sxp,sym,sxp,syp,sxm,syp,exm,eyp,exm,eym,exp,eym,'Z'
  //       # quadrant IV
  //       else if -HALF_PI <= theta < 0
  //         @path.push 'M',sxm,sym,exm,eym,exp,eym,exp,eyp,sxp,syp,sxm,syp,'Z'

  forEach(points, function(p, i) {
    var j = (i < (points.length - 1)) ? i + 1 : 0
    pathGraph.add({type: 'line', start: p, end: points[j]})
  })

  plotter._finishPath()

  return boundingBox.add(
    boundingBox.translate(tool.box, start), boundingBox.translate(tool.box, end))
}

// interpolate operation
// returns a bounding box for the operation
var interpolate = function(
  start, end, offset, tool, mode, arc, region, epsilon, pathGraph, plotter) {

  if (mode === 'i') {
    // add a line to the path normally if region mode is on or the tool is a circle
    if ((region === true) || (tool.trace.length === 1)) {
      return drawLine(start, end, tool, region, pathGraph)
    }

    // else, the tool is a rectangle, which needs a special interpolation function
    return interpolateRect(start, end, tool, pathGraph, plotter)
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
        start, end, offset, tool, mode, arc, region, epsilon, pathGraph, plotter)
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
