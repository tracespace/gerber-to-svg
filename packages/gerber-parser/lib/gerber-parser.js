// generic file parser for gerber and drill files
'use strict'

var Transform = require('stream').Transform

var applyOptions = require('./_apply-options')
var determineFiletype = require('./_determine-filetype')
var getNext = require('./get-next-block')
var parseGerber = require('./_parse-gerber')
var parseDrill = require('./_parse-drill')
var warning = require('./_warning')

var LIMIT = 65535

var _transform = function(chunk, encoding, done) {
  var filetype = this.format.filetype

  // determine filetype within 65535 characters
  if (!filetype) {
    filetype = determineFiletype(chunk, this._index, LIMIT)
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

  var toProcess = this._stash + chunk
  this._stash = ''

  while (this._index < toProcess.length) {
    var next = getNext(filetype, toProcess, this._index)
    this._index += next.read
    this.line += next.lines
    this._stash += next.rem

    if (next.block) {
      if (filetype === 'gerber') {
        parseGerber(this, next.block)
      }
      else {
        parseDrill(this, next.block)
      }
    }
  }

  this._index = 0
  done()
}

var _push = function(data) {
  data.line = this.line
  this.push(data)
}

var _warn = function(message) {
  this.emit('warning', warning(message, this.line))
}

var parser = function(opts) {
  // create a transform stream
  var stream = new Transform({
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
