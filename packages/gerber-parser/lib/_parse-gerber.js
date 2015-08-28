// parse gerber function
// takes a string, transform stream, and a done callback
'use strict'

const commands = require('./_commands')

// format spec regexp courtesy @summivox
// const reFORMAT = /%FS([LT]?)([AI]?)X([0-7])([0-7])Y\3\4\*%/

var parse = function(parser, block, line) {
  if (block === 'M02') {
    return commands.set(line, 'done', true)
  }

  return null

  // const format = block.match(reFORMAT)
  // if (format) {
  //   let zero = format[1]
  //   let notation = format[2]
  //   const leading = Number(format[3])
  //   const trailing = Number(format[4])

    // set zero if it hasn't already been set
    // if (parser.zero == null) {
    //   // if zero was not set, warn and assume leading
    //   if (!zero) {
    //     zero = 'L'
    //     transform._warn('zero suppression missing; assuming leading')
    //   }
    //   transform.zero = zero
    // }
    //
    // // ensure notation was set, if not, warn and set to absolute
    // if (!notation) {
    //   notation = 'A'
    //   transform._warn('coordinate notation missing, assuming absolute')
    // }
    //
    // // set places if they haven't been set already
    // if (transform.places == null) {
    //   transform.places = [leading, trailing]
    // }
    // // get the epsilon from actual places value
    // const epsilon = 1500 * Math.pow(10, -transform.places[1])
    //
    // transform._parsed({set: {notation, epsilon}})
  // }
}

module.exports = parse
