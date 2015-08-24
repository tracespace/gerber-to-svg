// cordinate parser function
// takes in a string with X_____Y_____I_____J_____ and a format object
// returns an object of {x: number, y: number, etc} for coordinates it finds
'use strict'

// convert to normalized number
const normalize = require('./_normalize-coord')

const MATCH = {
  x: /X([+-]?[\d\.]+)/,
  y: /Y([+-]?[\d\.]+)/,
  i: /I([+-]?[\d\.]+)/,
  j: /J([+-]?[\d\.]+)/
}

const parse = function(coord, format) {
  if (coord == null) {
    return {}
  }

  if ((format.zero == null) || (format.places == null)) {
    throw new Error('cannot parse coordinate with format undefined')
  }

  let parse = {}

  // pull out the x, y, i, and j
  for (let c of Object.keys(MATCH)) {
    let match = coord.match(MATCH[c])
    if (match) {
      parse[c] = normalize(match[1], format)
    }
  }

  return parse
}

module.exports = parse
