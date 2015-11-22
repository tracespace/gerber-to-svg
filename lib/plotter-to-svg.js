// transform stream to take plotter objects and convert them to an SVG string
'use strict'

var Transform = require('readable-stream').Transform
var inherits = require('inherits')
var every = require('lodash.every')
var isFinite = require('lodash.isfinite')

var reduceShapeArray = require('./_reduce-shape')
var flashPad = require('./_flash-pad')
var createPath = require('./_create-path')
var util = require('./_util')
var attr = util.attr
var shift = util.shift
var maskLayer = util.maskLayer
var startMask = util.startMask

var startSvg = function(id, className, color) {
  return [
    ('<svg id="' + id + '" '),
    ((className) ? ('class="' + className + '" ') : ''),
    ((color) ? ('color="' + color + '" ') : ''),
    'xmlns="http://www.w3.org/2000/svg" ',
    'version="1.1" ',
    'xmlns:xlink="http://www.w3.org/1999/xlink" ',
    'stroke-linecap="round" ',
    'stroke-linejoin="round" ',
    'stroke-width="0" ',
    'fill-rule="evenodd" '].join('')
}

var SVG_END = '</svg>'

var PlotterToSvg = function(id, className, color) {
  Transform.call(this, {writableObjectMode: true})

  this.defs = ''
  this.layer = ''
  this.viewBox = [0, 0, 0, 0]
  this.width = '0'
  this.height = '0'

  this._mask = ''
  this._layerCount = 0
  this._lastLayer = 0
  this._prefix = id
  this._result = startSvg(id, className, color)
  this._color = 'currentColor'
}

inherits(PlotterToSvg, Transform)

PlotterToSvg.prototype.warn = function(warning) {
  this.emit('warning', warning)
}

PlotterToSvg.prototype._transform = function(chunk, encoding, done) {
  switch (chunk.type) {
    case 'shape':
      this.defs += reduceShapeArray(this._prefix, chunk.tool, chunk.shape)
      break

    case 'pad':
      this._draw(flashPad(this._prefix, chunk.tool, chunk.x, chunk.y))
      break

    case 'fill':
      this._draw(createPath(chunk.path))
      break

    case 'stroke':
      this._draw(createPath(chunk.path, chunk.width))
      break

    case 'polarity':
      this._handleNewPolarity(chunk.polarity, chunk.box)
      break

    case 'size':
      this._handleSize(chunk.box, chunk.units)
  }

  done()
}

PlotterToSvg.prototype._flush = function(done) {
  this._result += attr('width', this.width) + ' ' + attr('height', this.height) + ' '
  this._result += attr('viewBox', this.viewBox.join(' ')) + '>'

  // finish any in-progress mask
  if (this._mask) {
    this._handleNewPolarity('dark')
  }

  // add the defs
  if (this.defs) {
    this._result += '<defs>' + this.defs + '</defs>'
  }

  // add the layer
  if (this.layer) {
    var yTranslate = this.viewBox[3] + 2 * this.viewBox[1]
    var transform = 'translate(0,' + yTranslate + ') scale(1,-1)'
    var transformAttr = attr('transform', transform) + ' '
    var strokeAndFill = attr('fill', this._color) + ' ' + attr('stroke', this._color)
    this._result += '<g ' + transformAttr + strokeAndFill + '>' + this.layer + '</g>'
  }

  this._result += SVG_END
  this.push(this._result)
  done()
}

PlotterToSvg.prototype._handleNewPolarity = function(polarity, box) {
  // if clear polarity, wrap the layer and start a mask
  if (polarity === 'clear') {
    var maskId = this._prefix + '_layer-' + (++this._layerCount)
    this.layer = maskLayer(maskId, this.layer)
    this._mask = startMask(maskId, box)
  }
  // else, finish the mask and add it to the defs
  else if (this._mask) {
    this.defs += this._mask + '</mask>'
    this._mask = ''
  }
}

PlotterToSvg.prototype._handleSize = function(box, units) {
  if (every(box, isFinite)) {
    var x = shift(box[0])
    var y = shift(box[1])
    var width = shift(box[2] - box[0])
    var height = shift(box[3] - box[1])

    this.viewBox = [x, y, width, height]
    this.width = (width / 1000) + units
    this.height = (height / 1000) + units
    this.units = units
  }
}

PlotterToSvg.prototype._draw = function(object) {
  if (!this._mask) {
    this.layer += object
  }
  else {
    this._mask += object
  }
}

module.exports = PlotterToSvg
