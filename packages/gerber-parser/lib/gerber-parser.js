// generic file parser for gerber and drill files
'use strict'

const Transform = require('stream').Transform
const util = require('util')

util.inherits(GerberParser, Transform)
function GerberParser(opts) {
  if (opts == null) {
    opts = {}
  }
  this.format = {
    zero: opts.zero || null,
    places: opts.places || null
  }

  // make sure places was set correctly
  if (this.format.places) {
    if ((this.format.places.length !== 2) ||
    (!Number.isFinite(this.format.places[0])) ||
    (!Number.isFinite(this.format.places[1]))) {
      throw new Error('parser places format must be an array of two numbers')
    }
  }

  // make sure zero was set correctly
  if (this.format.zero && (this.format.zero !== 'L') && (this.format.zero !== 'T')) {
    throw new Error("parser zero format must be either 'L' or 'T'")
  }

  Transform.call()
}

// _transform: (chunk, encoding, done) ->
//   if chunk.block?
//     @parseBlock chunk.block, chunk.line, done
//   else if chunk.param?
//     @parseParam chunk.param, chunk.line, done
//   else
//     done()

module.exports = GerberParser
