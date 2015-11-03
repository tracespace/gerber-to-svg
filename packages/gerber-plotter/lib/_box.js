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

// adds a point to a bounding box
var addPoint = function(box, point) {
  return [
    Math.min(box[0], point[0]),
    Math.min(box[1], point[1]),
    Math.max(box[2], point[0]),
    Math.max(box[3], point[1])
  ]
}

var addCircle = function(box, r, cx, cy) {
  return [
    Math.min(box[0], cx - r),
    Math.min(box[1], cy - r),
    Math.max(box[2], cx + r),
    Math.max(box[3], cy + r)
  ]
}

var translate = function(box, delta) {
  var dx = delta[0]
  var dy = delta[1]
  
  return [
    box[0] + dx,
    box[1] + dy,
    box[2] + dx,
    box[3] + dy
  ]
}

module.exports = {
  new: newBox,
  add: add,
  addPoint: addPoint,
  addCircle: addCircle,
  translate: translate
}
