// helper utilities
'use strict'

// shift the decimal place to SVG coordinates (units * 1000)
// also round to 7 decimal places
var shift = function(number) {
  return Math.round(10000000000 * number) / 10000000
}

// create an attribute assignment for SVG
var attr = function(attr, val) {
  return (attr + '="' + val + '"')
}

module.exports = {
  shift: shift,
  attr: attr
}
