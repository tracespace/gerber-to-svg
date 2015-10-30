// operate the plotter
'use strict'

var boundingBox = require('./_box')

// flash operation
// returns new bounding box
var flash = function(coord, tool, plotter) {
  // push the pad shape if needed
  if (!tool.flashed) {
    tool.flashed = true
    plotter.push({type: 'shape', tool: tool.code, shape: tool.pad})
  }

  plotter.push({type: 'pad', tool: tool.code, x: coord[0], y: coord[1]})
  return boundingBox.translate(tool.box, coord[0], coord[1])
}

// interpolate operation
// returns a new bounding box
// var interpolate = function(end, offset, start, mode, quad, plotter) {
//   return boundingBox.new()
// }

// takes the start point, the op type, the op coords, the tool, and the push function
// returns the new plotter position
var operate = function(type, coord, start, tool, mode, quad, plotter) {
  var end = [
    ((coord.x != null) ? coord.x : start[0]),
    ((coord.y != null) ? coord.y : start[1])
  ]

  // var offset = [
  //   ((coord.i != null) ? coord.i : 0),
  //   ((coord.j != null) ? coord.j : 0)
  // ]

  var box
  switch (type) {
    case 'flash':
      box = flash(end, tool, plotter)
      break

    // case 'int':
    //   box = interpolate(end, offset, start, mode, quad, plotter)
    //   break

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
