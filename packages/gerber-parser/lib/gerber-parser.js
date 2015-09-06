// generic file parser for gerber and drill files
'use strict'

const Transform = require('stream').Transform

const applyOptions = require('./_apply-options')
const determineFiletype = require('./_determine-filetype')
const getNext = require('./get-next-block')
const parseGerber = require('./_parse-gerber')
const warning = require('./_warning')

const LIMIT = 65535

const _transform = function(chunk, encoding, done) {
  // determine filetype within 65535 characters
  if (!this.format.filetype) {
    const filetype = determineFiletype(chunk, this._index, LIMIT)
    this._index += chunk.length

    if (!filetype) {
      if (this._index >= LIMIT) {
        return done(new Error('unable to determine filetype'))
      }
      this._stash += chunk
      return done()
    }
    else {
      this.format.filetype = filetype
      this._index = 0
    }
  }

  const filetype = this.format.filetype
  const toProcess = this._stash + chunk
  this._stash = ''
  while (this._index < toProcess.length) {
    const next = getNext(filetype, toProcess, this._index)
    this._index += next.read
    this.line += next.lines
    this._stash += next.rem

    if (next.block) {
      parseGerber(this, next.block)
    }
  }

  this._index = 0
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
    readableObjectMode: true
  })

  // parser methods
  stream._transform = _transform
  stream._push = _push
  stream._warn = _warn

  // parser properties
  stream._stash = ''
  stream._index = 0
  stream.line = 0
  stream.format = {places: [], zero: null, filetype: null}

  // apply options and return
  applyOptions(opts, stream.format)
  return stream
}

module.exports = parser
