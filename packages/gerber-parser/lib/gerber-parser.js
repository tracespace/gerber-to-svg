// generic file parser for gerber and drill files
'use strict'

const Transform = require('stream').Transform

const applyOptions = require('./_apply-options')
const determineFiletype = require('./_determine-filetype')
const getNext = require('./_get-next-block')
const parseGerber = require('./_parse-gerber')
const warning = require('./_warning')

const LIMIT = 65535

const transform = function(chunk, encoding, done) {
  // determine filetype within 65535 characters
  if (!this.format.filetype) {
    const filetype = determineFiletype(chunk, this.index, LIMIT)
    this.index += chunk.length

    if (!filetype) {
      if (this.index >= LIMIT) {
        return done(new Error('unable to determine filetype'))
      }
      // this.stash.push(chunk)
      return done()
    }
    else {
      this.format.filetype = filetype
      this.index = 0
    }
  }

  const filetype = this.format.filetype
  while (this.index < chunk.length) {
    const next = getNext(filetype, chunk, this.index)
    this.index += next.read
    this.line += next.lines

    parseGerber(this, next.block)
  }

  this.index = 0
  done()
}

const _push = function(data) {
  data.line = this.line
  this.push(data)
}

const _warn = function(message) {
  this.emit('warning', warning(message, this.line))
}

const parser = function(opts) {
  // create a transform stream
  const stream = new Transform({
    decodeStrings: false,
    readableObjectMode: true,
    transform
  })

  // parser methods
  stream._push = _push
  stream._warn = _warn

  // parser properties
  stream.stash = []
  stream.line = 0
  stream.index = 0
  stream.format = {places: [], zero: null, filetype: null}

  // apply options and return
  applyOptions(opts, stream.format)
  return stream
}

module.exports = parser
