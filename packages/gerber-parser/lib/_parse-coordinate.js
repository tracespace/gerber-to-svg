// cordinate parser function
// takes in a string with X_____Y_____I_____J_____ and a format object
// returns an object of {x: number, y: number, etc} for coordinates it finds

// # convert to gerber integer
// getSvgCoord = require('./svg-coord').get
//
// module.exports = ( coord, format ) ->
//   unless coord? then return {}
//   unless format.zero? and format.places? then throw new Error 'format undefined'
//
//   parse = {}
//   result = {}
//   # pull out the x, y, i, and j
//   parse.x = coord.match(/X[+-]?[\d\.]+/)?[0]?[1..]
//   parse.y = coord.match(/Y[+-]?[\d\.]+/)?[0]?[1..]
//   parse.i = coord.match(/I[+-]?[\d\.]+/)?[0]?[1..]
//   parse.j = coord.match(/J[+-]?[\d\.]+/)?[0]?[1..]
//   # loop through matched coordinates
//   for key, val of parse
//     result[key] = getSvgCoord val, format if val?
//   # return the result
//   result
