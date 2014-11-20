# cordinate parser function
# takes in a string with X_____Y_____I_____J_____ and a format object
# returns an object of { x: number, y: number etc} for coordinates it finds

module.exports = ( coord, format ) ->
  unless coord? then return {}
  unless format.zero? and format.places? then throw new Error 'format undefined'

  parse = {}
  result = {}
  # pull out the x, y, i, and j
  parse.x = coord.match(/X[+-]?[\d\.]+/)?[0]?[1..]
  parse.y = coord.match(/Y[+-]?[\d\.]+/)?[0]?[1..]
  parse.i = coord.match(/I[+-]?[\d\.]+/)?[0]?[1..]
  parse.j = coord.match(/J[+-]?[\d\.]+/)?[0]?[1..]
  # loop through matched coordinates
  for key, val of parse
    if val?
      # decimal numbers are parsed as is
      if (val.indexOf '.') isnt -1
        result[key] = Number(val)
      else
        divisor = 1
        if val[0] is '+' or val[0] is '-'
          divisor = -1 if val[0] is '-'
          val = val[1..]
        if format.zero is 'L' then divisor *= 10 ** format.places[1]
        else if format.zero is 'T'
          divisor *= 10 ** (val.length - format.places[0])
        else throw new Error 'invalid zero suppression format'
        result[key] = Number(val) / divisor
  # return the result
  result
