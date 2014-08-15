###
@license copyright 2014 by mike cousins <mike@cousins.io> (http://cousins.io)
shared under the terms of the MIT license
view source at http://github.com/mcous/gerber-to-svg
###

builder = require './obj-to-xml'
Plotter = require './plotter'
Driller = require './driller'

DEFAULT_OPTS = {
  drill: false
  pretty: false
  object: false
}

module.exports = (gerber, options = {}) ->
  # options
  opts = {}
  opts[key] = val for key, val of DEFAULT_OPTS
  opts[key] = val for key, val of options
  # check if an svg object was passed int
  if typeof gerber is 'object'
    if gerber.svg? then return builder gerber, { pretty: opts.pretty }
    else throw new Error "non SVG object cannot be converted to an SVG string"
  # or we got a gerber string, so plot the thing
  p = if opts.drill then new Driller gerber else new Plotter gerber
  try
    xmlObject = p.plot()
  catch error
    throw new Error "Error at line #{p.parser.line} - #{error.message}"
  # make sure the bbox is valid
  unless p.bbox.xMin >= p.bbox.xMax
    width = parseFloat (p.bbox.xMax - p.bbox.xMin).toPrecision 10
  else
    p.bbox.xMin = 0
    p.bbox.xMax = 0
    width = 0
  unless  p.bbox.yMin >= p.bbox.yMax
    height = parseFloat (p.bbox.yMax - p.bbox.yMin).toPrecision 10
  else
    p.bbox.yMin = 0
    p.bbox.yMax = 0
    height = 0
  # create an xml object
  xml = {
    svg: {
      xmlns: 'http://www.w3.org/2000/svg'
      version: '1.1'
      'xmlns:xlink': 'http://www.w3.org/1999/xlink'
      width: "#{width}#{p.units}"
      height: "#{height}#{p.units}"
      viewBox: [ p.bbox.xMin, p.bbox.yMin, width, height ]
      id: p.gerberId
      _: []
    }
  }
  if p.defs.length then xml.svg._.push { defs: { _: p.defs } }
  # flip it in the y and translate back to origin
  if p.group.g._.length
    p.group.g.transform = "translate(0,#{p.bbox.yMin+p.bbox.yMax}) scale(1,-1)"
    xml.svg._.push p.group
  # return the string or the object if that flag is set
  unless opts.object then builder xml, { pretty: opts.pretty } else xml
