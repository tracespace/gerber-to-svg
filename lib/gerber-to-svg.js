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
  var toSvg = new PlotterToSvg(opts.id, opts.class, opts.color)

  var svgStream = parser.pipe(plotter).pipe(toSvg)

  if (gerber.pipe) {
    gerber.pipe(parser)
  }
  else {
    parser.write(gerber)
    parser.end()
  }

  if (done == null) {
    return svgStream
  }

  var converter = new events.EventEmitter()
  var result = ''

  svgStream.on('readable', function() {
    var data
    do {
      data = svgStream.read() || ''
      result += data
    } while (data)
  })

  svgStream.on('end', function() {
    done(null, result)
  })

  return converter
}

module.exports = gerberToSvg
