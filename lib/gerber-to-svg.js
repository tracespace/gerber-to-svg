// gerber to svg transform stream
'use strict'

var events = require('events')
var isString = require('lodash.isstring')
var gerberParser = require('gerber-parser')
var gerberPlotter = require('gerber-plotter')

var PlotterToSvg = require('./plotter-to-svg')

var parseOptions = function(options) {
  if (isString(options)) {
    return {id: options}
  }

  var id = options.id
  var className = options.class || ''
  var color = options.color || ''
  // var pretty

  if (id == null) {
    throw new Error('id required for gerber-to-svg')
  }

  return {
    id: id,
    class: className,
    color: color
  }
}

var gerberToSvg = function(gerber, options, done) {
  var opts = parseOptions(options)

  var parser = gerberParser()
  var plotter = gerberPlotter()
  var svgStream = new PlotterToSvg(opts.id, opts.class, opts.color)

  parser.on('warning', function handleParserWarning(w) {
    svgStream.warn(w)
  })
  plotter.on('warning', function handlePlotterWarning(w) {
    svgStream.warn(w)
  })

  if (gerber.pipe) {
    gerber.setEncoding('utf8')
    gerber.pipe(parser)
  }
  else {
    // write the gerber string after listeners have been attached etc
    process.nextTick(function writeStringToParser() {
      parser.write(gerber)
      parser.end()
    }, 0)
  }

  parser.pipe(plotter).pipe(svgStream)

  if (done == null) {
    return svgStream
  }

  // return a simple event emitter instead of a stream if in callback mode
  var converter = new events.EventEmitter()
  svgStream.on('warning', function passAlongStreamWarning(w) {
    converter.emit('warning', w)
  })

  var result = ''

  svgStream.on('readable', function collectStreamData() {
    var data
    do {
      data = svgStream.read() || ''
      result += data
    } while (data)
  })

  svgStream.on('end', function callConversionDone() {
    done(null, result)
  })

  return converter
}

module.exports = gerberToSvg
