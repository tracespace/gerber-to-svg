###
@license copyright 2014 by mike cousins <mike@cousins.io> (http://cousins.io)
shared under the terms of the MIT license
view source at http://github.com/mcous/gerber-to-svg
###

builder = require './obj-to-xml'
Plotter = require './plotter'

gerberToSvg = (gerber) ->
  p = new Plotter gerber
  try
    xmlObject = p.plot()
  catch e
    console.log "error at gerber line #{p.parser.line}"
    throw e
  # return the string
  builder xmlObject, { pretty: true }

module.exports = gerberToSvg
