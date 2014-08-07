builder = require 'xml'
Plotter = require './plotter'

gerberToSvg = (gerber) ->
  p = new Plotter gerber
  try
    xmlObject = p.plot()
  catch e
    console.log "error at gerber line #{p.parser.line}"
    throw e
  # return the string
  builder xmlObject, { indent: '  ' }

module.exports = gerberToSvg
