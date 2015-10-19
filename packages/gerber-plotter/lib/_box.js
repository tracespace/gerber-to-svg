// bounding box utilities and helpers
// bouding boxes are arrays of the format: [xMin, yMin, xMax, yMax]
'use strict'

// returns a new bounding box that is infinitely small and centered on nothing
var newBox = function() {
  return [Infinity, Infinity, -Infinity, -Infinity]
}

// adds the two bounding boxes and returns a new one
var add = function(box, target) {
  return [
    Math.min(box[0], target[0]),
    Math.min(box[1], target[1]),
    Math.max(box[2], target[2]),
    Math.max(box[3], target[3])
  ]
}

module.exports = {
  new: newBox,
  add: add
}
