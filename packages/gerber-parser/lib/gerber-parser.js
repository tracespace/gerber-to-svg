// generic file parser for gerber and drill files
'use strict'

const Transform = require('stream').Transform
const applyOptions = require('./_apply-options')

const transform = function(chunk, encoding, done) {
  this.push({error: 'not implemented'})
  done()
}

const parser = function(opts) {
  // create a transform stream
  let stream = new Transform({
    decodeStrings: false,
    readableObjectMode: true,
    transform
  })

  // apply options and return
  applyOptions(opts, stream)
  return stream
}

module.exports = parser
