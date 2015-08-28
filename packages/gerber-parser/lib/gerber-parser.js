// generic file parser for gerber and drill files
'use strict'

const Transform = require('stream').Transform

const applyOptions = require('./_apply-options')
const determineFiletype = require('./_determine-filetype')
const getNext = require('./_get-next-block')
const parseGerber = require('./_parse-gerber')

const LIMIT = 65535

const transform = function(chunk, encoding, done) {
  // determine filetype within 65535 characters
  if (!this.filetype) {
    this.filetype = determineFiletype(chunk, this.index, LIMIT)
    this.index += chunk.length

    if (!this.filetype) {
      if (this.index >= LIMIT) {
        return done(new Error('unable to determine filetype'))
      }
      // this.stash.push(chunk)
      return done()
    }
    else {
      this.index = 0
    }
  }

  while (this.index < chunk.length) {
    const next = getNext(this.filetype, chunk, this.index)
    this.index += next.read
    this.line += next.lines

    const block = parseGerber(this, next.block, this.line)
    if (block) {
      this.push(block)
    }
  }

  this.index = 0
  done()
}

const parser = function(opts) {
  // create a transform stream
  const stream = new Transform({
    decodeStrings: false,
    readableObjectMode: true,
    transform
  })

  // parser properties
  stream.stash = []
  stream.line = 0
  stream.index = 0

  // apply options and return
  applyOptions(opts, stream)
  return stream
}

module.exports = parser
