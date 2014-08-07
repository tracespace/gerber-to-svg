builder = require 'xml'
Plotter = require './plotter'

gerberToSvg = (gerber) ->
  p = new Plotter gerber
  xmlObject = p.plot()
  # return the string
  builder xmlObject

module.exports = gerberToSvg
