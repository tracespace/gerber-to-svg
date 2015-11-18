// transform stream to take plotter objects and convert them to an SVG string
'use strict'

var Transform = require('readable-stream').Transform
var inherits = require('inherits')

var reduceShapeArray = require('./_reduce-shape')
var flashPad = require('./_flash-pad')

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
    'stroke-width="0" '].join('')
}

var SVG_END = '</svg>'

var PlotterToSvg = function(id, className, color) {
  Transform.call(this, {writableObjectMode: true})

  this.defs = ''
  this.layer = ''

  this._prefix = id
  this._result = startSvg(id, className, color)
  this._color = 'currentColor'
}

inherits(PlotterToSvg, Transform)

PlotterToSvg.prototype._transform = function(chunk, encoding, done) {
  switch (chunk.type) {
    case 'shape':
      this.defs += reduceShapeArray(this._prefix, chunk.tool, chunk.shape)
      break

    case 'pad':
      this.layer += flashPad(this._prefix, chunk.tool, chunk.x, chunk.y)
      break
  }

  done()
}

PlotterToSvg.prototype._flush = function(done) {
  this._result += 'width="0" height="0" viewBox="0 0 0 0">' + SVG_END

  this.push(this._result)
  done()
}

module.exports = PlotterToSvg
