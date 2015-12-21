// gerber plotter
'use strict'

var TransformStream = require('readable-stream').Transform
var has = require('lodash.has')
var mapValues = require('lodash.mapvalues')
var clone = require('lodash.clone')

var PathGraph = require('./path-graph')
var applyOptions = require('./_apply-options')
var warning = require('./_warning')
var padShape = require('./_pad-shape')
var operate = require('./_operate')
var boundingBox = require('./_box')

var isFormatKey = function(key) {
  return (
    key === 'units' ||
    key === 'backupUnits' ||
    key === 'nota' ||
    key === 'backupNota')
}

var _finishPath = function() {
  if (this._path.length) {
    var path = this._path.traverse()
    this._path = new PathGraph()

    if (!this._region && (this._tool.trace.length === 1)) {
      this.push({type: 'stroke', width: this._tool.trace[0], path: path})
    }
    else {
      this.push({type: 'fill', path: path})
    }
  }
}

var _warn = function(message) {
  this.emit('warning', warning(message, this._line))
}

var _checkFormat = function() {
  if (!this.format.units) {
    this.format.units = this.format.backupUnits
    this._warn('units not set; using backup units: ' + this.format.units)
  }

  if(!this.format.nota) {
    this.format.nota = this.format.backupNota
    this._warn('notation not set; using backup notation: ' + this.format.nota)
  }
}

var _updateBox = function(box) {
  var stepRepLen = this._stepRep.length
  if (!stepRepLen) {
    this._box = boundingBox.add(this._box, box)
  }
  else {
    var repeatBox = boundingBox.repeat(box, this._stepRep[stepRepLen - 1])
    this._box = boundingBox.add(this._box, repeatBox)
  }
}

var _transform = function(chunk, encoding, done) {
  var cmd = chunk.cmd
  var key = chunk.key
  var val = chunk.val

  this._line = chunk.line

  if (this._done) {
    this._warn('ignoring extra command recieved after done command')

    return done()
  }

  // check for an operation
  if (cmd === 'op') {
    this._checkFormat()

    if (this.nota === 'I') {
      val = mapValues(val, function(value, key) {
        if (key === 'x') {
          return (this._pos[0] + value)
        }
        if (key === 'y') {
          return (this._pos[1] + value)
        }

        return value
      }, this)
    }

    if (key === 'last') {
      this._warn('modal operation commands are deprecated')
      key = this._lastOp
    }

    if (key === 'int') {
      if (this._mode == null) {
        this._warn('no interpolation mode specified; assuming linear')
        this._mode = 'i'
      }

      if ((this._arc == null) && (this._mode.slice(-2) === 'cw')) {
        this._warn('quadrant mode unspecified; assuming single quadrant')
        this._arc = 's'
      }
    }

    var result = operate(
      key,
      val,
      this._pos,
      this._tool,
      this._mode,
      this._arc,
      this._region,
      this._path,
      this._epsilon,
      this)

    this._lastOp = key
    this._pos = result.pos
    this._updateBox(result.box)
  }

  else if (cmd === 'set') {
    // if region change, finish the path
    if (key === 'region') {
      this._finishPath()
      this._region = val
    }

    // else we might need to set the format
    else if (isFormatKey(key) && !this._formatLock[key]) {
      this.format[key] = val
      if (key === 'units' || key === 'nota') {
        this._formatLock[key] = true
      }
    }

    // else if we're dealing with a tool change, finish the path and change
    else if (key === 'tool') {
      if (this._region) {
        this._warn('cannot change tool while region mode is on')
      }
      else if (!has(this._tools, val)) {
        this._warn('tool ' + val + ' is not defined')
      }
      else {
        this._finishPath()
        this._tool = this._tools[val]
      }
    }

    // else set interpolation or arc mode
    else {
      this['_' + key] = val
    }
  }

  // else tool commands
  else if (cmd === 'tool') {
    if (this._tools[key]) {
      this._warn('tool ' + key + ' is already defined; ignoring new definition')

      return done()
    }

    var shapeAndBox = padShape(val, this._macros)
    var tool = {
      code: key,
      trace: [],
      pad: shapeAndBox.shape,
      flashed: false,
      box: shapeAndBox.box
    }

    if (val.shape === 'circle' || val.shape === 'rect') {
      if (val.hole.length === 0) {
        tool.trace = val.val
      }
    }

    this._finishPath()
    this._tools[key] = tool
    this._tool = tool
  }

  // else macro command
  else if (cmd === 'macro') {
    // save the macro
    this._macros[key] = val
  }

  // else layer command
  else if (cmd === 'level') {
    this._finishPath()

    if (key === 'polarity') {
      this.push({
        type: 'polarity',
        polarity: (val === 'C') ? 'clear' : 'dark',
        box: clone(this._box)
      })
    }
    else {
      // calculate new offsets
      var offsets = []
      for (var x = 0; x < val.x; x++) {
        for (var y = 0; y < val.y; y++) {
          offsets.push([x * val.i, y * val.j])
        }
      }
      this._stepRep = offsets

      this.push({type: 'repeat', offsets: clone(this._stepRep), box: clone(this._box)})
    }
  }

  // else done command
  else if (cmd === 'done') {
    this._done = true
  }

  return done()
}

var _flush = function(done) {
  this._finishPath()

  this.push({type: 'size', box: this._box, units: this.format.units})
  done()
}

var plotter = function(options) {
  var stream = new TransformStream({
    readableObjectMode: true,
    writableObjectMode: true,
    transform: _transform,
    flush: _flush
  })

  stream._updateBox = _updateBox
  stream._finishPath = _finishPath
  stream._warn = _warn
  stream._checkFormat = _checkFormat

  stream.format = {
    units: null,
    backupUnits: 'in',
    nota: null,
    backupNota: 'A'
  }

  stream._formatLock = {
    units: false,
    backupUnits: false,
    nota: false,
    backupNota: false
  }

  stream._line = 0
  stream._done = false
  stream._tool = null
  stream._tools = {}
  stream._macros = {}
  stream._pos = [0, 0]
  stream._box = boundingBox.new()
  stream._mode = null
  stream._arc = null
  stream._region = false
  stream._path = new PathGraph()
  stream._epsilon = null
  stream._lastOp = null
  stream._stepRep = []

  applyOptions(options, stream.format, stream._formatLock)
  return stream
}

module.exports = plotter
