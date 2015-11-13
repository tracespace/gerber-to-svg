// transform stream to take plotter objects and convert them to an SVG string
'use strict'

var stream = require('readable-stream')

var reduceShapeArray = require('./_reduce-shape')

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

var _transform = function(chunk, encoding, done) {
  if (chunk.type === 'shape') {
    this.defs += reduceShapeArray(this._prefix, chunk.tool, chunk.shape)
  }
  done()
}

var _flush = function(done) {
  this._result += 'width="0" height="0" viewBox="0 0 0 0">' + SVG_END

  this.push(this._result)
  done()
}

var plotterToSvg = function(id, className, color) {
  var svgStream = new stream.Transform({
    writableObjectMode: true,
    transform: _transform,
    flush: _flush
  })

  svgStream._prefix = id

  svgStream.defs = ''
  svgStream.layer = ''

  svgStream._result = startSvg(id, className, color)
  svgStream._color = 'currentColor'

  return svgStream
}

module.exports = plotterToSvg
