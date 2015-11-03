// utilities to create a graph of path segments and traverse that graph
'use strict'

var forEach = require('lodash.foreach')
var fill = require('lodash.fill')

var pointsEqual = function(point, target) {
  return ((point[0] === target[0]) && (point[1] === target[1]))
}

var segmentsAreAdjacent = function(segment, target) {
  return (
    pointsEqual(segment.start, target.start) ||
    pointsEqual(segment.end, target.end) ||
    pointsEqual(segment.start, target.end) ||
    pointsEqual(segment.end, target.start))
}

var reverseSegment = function(segment) {
  var reversed = {type: segment.type, start: segment.end, end: segment.start}

  if (segment.type === 'arc') {
    reversed.center = segment.center
    reversed.radius = segment.radius
    reversed.dir = (segment.dir === 'cw') ? 'ccw' : 'cw'
  }

  return reversed
}

var PathGraph = function() {
  this._segments = []
  this._adjacency = []
}

PathGraph.prototype.add = function(newSeg) {
  var newSegIndex = this._segments.length
  this._adjacency[newSegIndex] = []

  forEach(this._segments, function(seg, index) {
    if (segmentsAreAdjacent(seg, newSeg)) {
      this._adjacency[index].push(newSegIndex)
      this._adjacency[newSegIndex].push(index)
    }
  }, this)

  this._segments.push(newSeg)
}

PathGraph.prototype.traverse = function() {
  var seen = fill(Array(this._segments.length), false)
  var discovered = []
  var result = []

  var next
  var nextSegment
  var lastEnd = []
  while (result.length < this._segments.length) {
    next = seen.indexOf(false)
    discovered.push(next)

    while (discovered.length) {
      next = discovered.pop()

      if (!seen[next]) {
        seen[next] = true

        forEach(this._adjacency[next], function(seg) {
          if (!seen[seg]) {
            discovered.push(seg)
          }
        })

        nextSegment = this._segments[next]

        // reverse segment if necessary
        if (pointsEqual(lastEnd, nextSegment.end)) {
          nextSegment = reverseSegment(nextSegment)
        }

        lastEnd = nextSegment.end
        result.push(nextSegment)
      }
    }
  }

  return result
}

module.exports = PathGraph
