// gerber to svg transform stream
'use strict'

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
  var callbackMode = (done != null)

  var parser = gerberParser()
  var plotter = gerberPlotter()
  var converter = new PlotterToSvg(opts.id, opts.class, opts.color)

  parser.on('warning', function handleParserWarning(w) {
    converter.emit('warning', w)
  })
  plotter.on('warning', function handlePlotterWarning(w) {
    converter.emit('warning', w)
  })
  parser.once('error', function handleParserError(e) {
    converter.emit('error', e)
  })
  plotter.once('error', function handlePlotterError(e) {
    converter.emit('error', e)
  })

  // expose the filetype property of the parser for convenience
  parser.once('end', function() {
    converter.filetype = parser.format.filetype
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
    })
  }

  parser.pipe(plotter).pipe(converter)

  // collect result in callback mode
  if (callbackMode) {
    var result = ''

    converter.on('readable', function collectStreamData() {
      var data
      do {
        data = converter.read() || ''
        result += data
      } while (data)
    })

    converter.once('end', function callConversionDone() {
      done(null, result)
    })
  }

  return converter
}

module.exports = gerberToSvg
