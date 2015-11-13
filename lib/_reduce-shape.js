// reduce a shape array into a string to place is defs
'use strict'

var reduce = require('lodash.reduce')

// shift the decimal place
var shift = function(number) {
  return (1000 * number)
}

var reduceShapeArray = function(prefix, code, shapeArray) {
  var id = prefix + '_pad-' + code

  return reduce(shapeArray, function(result, shape) {
    if (shape.type === 'circle') {
      result += [
        '<circle id="' + id + '" ',
        'cx="' + shift(shape.cx), '" ',
        'cy="' + shift(shape.cy), '" ',
        'r="' + shift(shape.r) + '"/>'].join('')
    }

    else if (shape.type === 'rect') {
      result += [
        '<rect id="' + id + '" ',
        'x="' + shift(shape.cx - shape.width / 2), '" ',
        'y="' + shift(shape.cy - shape.height / 2), '" ',
        'rx="' + shift(shape.r) + '" ry="' + shift(shape.r) + '" ',
        'width="' + shift(shape.width), '" ',
        'height="' + shift(shape.height), '"/>'].join('')
    }

    return result
  }, '')
}

module.exports = reduceShapeArray
