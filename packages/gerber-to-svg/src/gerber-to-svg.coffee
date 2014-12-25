# gerber-to-svg
# this bad boy is the entry point

builder = require './obj-to-xml'
Plotter = require './plotter'

# coordinate scale
coordFactor = require('./svg-coord').factor

DEFAULT_OPTS = {
  drill: false
  pretty: false
  object: false
  warnArr: null
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
  # or we got a string, so plot the thing
  # get the correct reader and parser
  if opts.drill
    Reader = require './drill-reader'
    Parser = require './drill-parser'
  else
    Reader = require './gerber-reader'
    Parser = require './gerber-parser'
  # create the plotter
  p = new Plotter gerber, Reader, Parser
  # capture console.warn if necessary
  oldWarn = null
  root = null
  if Array.isArray opts.warnArr
    root = window ? global
    root.console = {} if not root.console?
    oldWarn = root.console.warn
    root.console.warn = (chunk) -> opts.warnArr.push chunk.toString()
  try
    # try to plot
    xmlObject = p.plot()
  catch error
    throw new Error "Error at line #{p.reader.line} - #{error.message}"
  finally
    # unhook the warning capture if it was hooked
    if oldWarn? and root? then root.console.warn = oldWarn
    

  # make sure the bbox is valid
  unless p.bbox.xMin >= p.bbox.xMax then width = p.bbox.xMax - p.bbox.xMin
  else
    p.bbox.xMin = 0
    p.bbox.xMax = 0
    width = 0
  unless  p.bbox.yMin >= p.bbox.yMax then height = p.bbox.yMax - p.bbox.yMin
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
      width: "#{width/coordFactor}#{p.units}"
      height: "#{height/coordFactor}#{p.units}"
      viewBox: [ p.bbox.xMin, p.bbox.yMin, width, height ]
      _: []
    }
  }
  # add attributes
  xml.svg[a] = val for a, val of p.attr
  # push the defs if there are any
  if p.defs.length then xml.svg._.push { defs: { _: p.defs } }
  # flip the image group in the y and translate back to origin
  if p.group.g._.length then xml.svg._.push p.group
  # return the string or the object if that flag is set
  unless opts.object then builder xml, { pretty: opts.pretty } else xml
