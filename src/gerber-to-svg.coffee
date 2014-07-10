builder = require 'xmlbuilder'
plotter = require './plotter'

class GerberToSvg
  constructor: ->
    console.log "GerberToSvg object created"
    @svg = builder.create 'svg',
      { version: '1.0', encoding: 'UTF-8', standalone: true },
      { pubid: null, sysid: null },
      { headless: true }

    @svg.att {
      xmlns: 'http://www.w3.org/2000/svg'
      version: '1.1'
      'xmlns:xlink': 'http://www.w3.org/1999/xlink'
    }

  convert: (gerber) ->
    @svg.end()

module.exports = new GerberToSvg
