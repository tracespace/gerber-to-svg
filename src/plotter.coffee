# svg plotter class

# use the gerber parser class to parse the file
Parser = require './gerber-parser-old'
# unique id generator
unique = require './unique-id'
# aperture macro class
Macro = require './macro-tool'
# standard tool functions
tool = require './standard-tool'

# constants
HALF_PI = Math.PI/2
THREEHALF_PI = 3*HALF_PI
TWO_PI = 2*Math.PI

# given a rectangle's dimensions and path end, return a path string
rectangleStrokePath = (start, end, width, height) ->
  # helpers
  sxm = start.x - width/2
  sxp = start.x + width/2
  sym = start.y - height/2
  syp = start.y + height/2
  exm = end.x - width/2
  exp = end.x + width/2
  eym = end.y - height/2
  eyp = end.y + height/2
  # get the quadrant we're in
  theta = Math.atan2 end.y-start.y, end.x - start.x
  # quadrant I
  if 0 <= theta < HALF_PI
    "M#{sxm} #{sym}L#{sxp} #{sym}L#{exp} #{eym}L#{exp} #{eyp}L#{exm} #{eyp}
     L#{sxm} #{syp}Z"
  # quadrant II
  else if HALF_PI <= theta < Math.PI
    "M#{sxm} #{sym}L#{sxp} #{sym}L#{sxp} #{syp}L#{exp} #{eyp}L#{exm} #{eyp}
     L#{exm} #{eym}Z"
  # quadrant III
  else if -Math.PI <= theta < -HALF_PI
    "M#{sxp} #{sym}L#{sxp} #{syp}L#{sxm} #{syp}L#{exm} #{eyp}L#{exm} #{eym}
     L#{exp} #{eym}Z"
  # quadrant IV
  else if -HALF_PI <= theta < 0
    "M#{sxm} #{sym}L#{exm} #{eym}L#{exp} #{eym}L#{exp} #{eyp}L#{sxp} #{syp}
     L#{sxm} #{syp}Z"

class Plotter
  constructor: (file = '', @reader, @parser) ->
    # create a parser object
    @parser = new Parser file
    # tools
    @macros = {}
    @tools = {}
    @currentTool = ''
    # array for pad and mask definitions
    @defs = []
    # svg identification, image group, and current layers
    @gerberId = "gerber-#{unique()}"
    @group = { g: { id: "#{@gerberId}-layer-0", _: [] } }
    @layer = { level: 0, type: 'g', current: @group }
    # step and repeat, initially set to no repeat
    @stepRepeat = { x: 1, y: 1, xStep: null, yStep: null, block: 0 }
    # unit system
    @units = null
    # operating mode
    @mode = null
    @quad = null
    @region = false
    @done = false
    # operation state (position, current region or trace path, current layer)
    @pos = { x: 0, y: 0 }
    @path = []
    @current = []
    # bounding box of plotted image
    @bbox = { xMin: Infinity, yMin: Infinity, xMax: -Infinity, yMax: -Infinity }

  # add a tool to the tool list
  addTool: (code, params) ->
    if @tools[code]? then throw new Error "cannot reassign tool #{code}"
    # get the tool
    if params.macro? then t = @macros[params.macro].run code, params.mods
    else t = tool code, params
    # set the object in the tools collection
    @tools[code] = {
      trace: t.trace
      pad: (obj for obj in t.pad)
      flash: (x, y) -> { use: { x: x, y: y, 'xlink:href': '#'+t.padId } }
      bbox: (x=0, y=0) -> {
        xMin: x+t.bbox[0]
        yMin: y+t.bbox[1]
        xMax: x+t.bbox[2]
        yMax: y+t.bbox[3]
      }
    }
    # set the current tool to the one just defined
    @currentTool = code
    # since this was a tool change, finish the path

  # change the tool
  changeTool: (code) ->
    # finish any in progress path
    @finishPath()
    # throw an error if in region mode or if tool does not exist
    if @region then throw new Error "cannot change tool when in region mode"
    if not @tools[code]? then throw new Error "tool #{code} is not defined"
    # change the tool if it exists
    @currentTool = code

  # handle a command that comes in from the parser
  command: (c) ->
    # if the command is a macro command, it's going to appear alone
    if c.macro? then m = new Macro c.macro; @macros[m.name] = m; return

    # if there's a set command
    for state, val of c.set
      # check for some specific things that shouldn't happen
      if state is 'units' and @units?
        throw new Error 'cannot redefine units'
      else if state is 'notation' and @notation?
        throw new Error 'cannot redefine notation'
      # tool changes are the only special ones
      if state is 'currentTool' then @changeTool val
      # else just set the state
      else @[state] = val

    # if there's a tool command
    if c.tool? then @addTool code, params for code, params of c.tool

    # if there's an operate command, then IT'S TIME TO OPERATE
    if c.op? then @operate c.op

    # if it's a new command, then we're making a new layer or step repeat
    # finish any open path before we do
    if c.new?
      @finishPath()

  # go through the gerber file and return an xml object with the svg
  plot: () ->
    until @done
      # grab the next command. if it returns false we've hit the end of the file
      current = @parser.nextCommand()
      if current is false
        throw new Error 'end of file encountered before required M02 command'
      # if it's a parameter command
      if current[0] is '%' then @parameter current else @operate current[0]
    # finish and return the xml object
    @finish()

  finish: () ->
    @finishPath()
    #@finishStepRepeat()

  finishPath: ->
    if @path.length
      p = { path: {} }
      # if we're in region mode, check for start and end match and close
      if @region then @path.push 'Z'
      # else, apply the stroke properties
      else p.path[key] = val for key, val of @tools[@currentTool].trace
      # stick the path data in, push to the current layer, and empty the path
      p.path.d = @path
      @current.push p
      @path = []

  # operate method takes the operation and the end point
  operate: (op) ->
    # get the start position
    sx = @pos.x; sy = @pos.y
    # move the plotter position
    # coordinates are modal, so adapt accordingly
    if @notation is 'I'
      @pos.x += op.x ? 0; @pos.y += op.y ? 0
    else @pos.x = op.x ? @pos.x; @pos.y = op.y ? @pos.y
    # get the end position
    ex = @pos.x; ey = @pos.y
    # get the current tool
    t = @tools[@currentTool]

    # do a check for units and notation (ensures format is properly set)
    unless @units?
      if @backupUnits?
        @units = @backupUnits
        console.warn "Warning: units set to '#{@units}' according to
                      deprecated command G7#{if @units is 'in' then 0 else 1}"
      else throw new Error 'units have not been set'
    unless @notation? then throw new Error 'format has not been set'

    # switch through the actual operation
    # a move adds a move to the path if there is one, else we've already moved
    if op.do is 'move' and @path.length then @path.push 'M', ex, ey
    # a flash adds a pad to the current layer
    else if op.do is 'flash'
      # end any in progress path
      @finishPath()
      # check that region mode isn't on
      if @region then throw new Error 'cannot flash while in region mode'
      # add the pad to the definitions if necessary, and then flash the layer
      if t.pad then @defs.push shape for shape in t.pad; t.pad = false
      @current.push t.flash ex, ey
      # update the bounding box
      @addBbox t.bbox ex, ey
    # finally, an interpolate makes a trace or defines a region
    # right here, though, it's mostly just gonna add stuff to @path
    else if op.do is 'int'
      # if we're not in region mode, check if the tool is strokable
      if not @region and not t.trace
        throw new Error "#{@currentTool} is not a strokable tool"
      # if there's no path right now, we'd better start one
      if @path.length is 0
        # start the path
        @path.push 'M', sx, sy
        # start the bbox
        if not @region then @addBbox t.bbox sx, sy else @addBbox {
          xMin: sx, yMin: sy, xMax: sx, yMax: sy
        }
      # check for a mode, and assume linear if necessary
      if not @mode? then @mode = 'i'; console.warn 'Warning: no interpolation
        mode set. Assuming linear interpolation (G01)'

      # let's draw something
      if @mode is 'i'
        @drawLine sx, sy, ex, ey
      else
        @drawArc sx, sy, ex, ey, op.i, op.j

  drawLine: (sx, sy, ex, ey) ->
    t = @tools[@currentTool]
    # add to the bbox
    if not @region then @addBbox t.bbox ex, ey else @addBbox {
      xMin: ex, yMin: ey, xMax: ex, yMax: ey
    }
    # check for a rectangular or circular tool
    # circular tool will have a stroke-width set, and is easy
    if t.trace['stroke-width'] > 0 then @path.push 'L', ex, ey
    # rectagular tools are complicated, though
    else



      # # linear interpolation adds an absolute line to the path
      # if @mode is 'i'
      #   # add the segment to the path
      #   # if it's a round tool or we're in region mode, just add the point
      #   if @trace.region or @tools[@currentTool].stroke['stroke-linecap']?
      #     @trace.path += "L#{end.x} #{end.y}"
      #   # else we're stroking a rectangular aperture, so that's frustrating
      #   else
      #     width = @tools[@currentTool].pad[0].rect.width
      #     height = @tools[@currentTool].pad[0].rect.height
      #     @trace.path += rectangleStrokePath start, end, width, height
      #   # add the segment to the bbox
      #   if @trace.region
      #     @addBbox {
      #       xMin: end.x, yMin: end.y, xMax: end.x, yMax: end.y
      #     }
      #   else
      #     @addBbox @tools[@currentTool].bbox end.x, end.y
      # # are interpolation adds an eliptical (circular) arc to the path
      # else if @mode is 'cw' or @mode is 'ccw'
      #   # throw if tool isn't a circle
      #   if not @trace.region and
      #   not @tools[@currentTool].stroke['stroke-linecap'] is 'round'
      #     throw new Error "tool #{@currentTool} is not circular and cannot
      #                      stroke arcs"
      #   r = Math.sqrt end.i**2 + end.j**2
      #   sweep = if @mode is 'cw' then 0 else 1
      #   large = 0
      #   # if we're in single quadrant mode, work to get the center
      #   # signs are implicit on i and j in single quad, so test them
      #   cen = []
      #   thetaE = 0
      #   thetaS = 0
      #   if @quad is 's'
      #     for cx in [ start.x - end.i, start.x + end.i ]
      #       for cy in [start.y - end.j, start.y + end.j ]
      #         dist = Math.sqrt (cx-end.x)**2 + (cy-end.y)**2
      #         if (Math.abs r - dist) < 0.0000001 then cen.push {x: cx, y: cy }
      #   else if @quad is 'm'
      #     cen.push { x: start.x + end.i, y: start.y + end.j }
      #   # at most, we'll have two candidates
      #   # check the points to make sure we have a valid arc
      #   for c in cen
      #     thetaE = Math.atan2 end.y-c.y, end.x-c.x
      #     if thetaE < 0 then thetaE += TWO_PI
      #     thetaS = Math.atan2 start.y-c.y, start.x-c.x
      #     if thetaS < 0 then thetaS += TWO_PI
      #     # adjust angles so math comes out right
      #     if @mode is 'cw' and thetaS < thetaE then thetaS+=TWO_PI
      #     else if @mode is 'ccw' and thetaE < thetaS then thetaE+=TWO_PI
      #     # take it if it's less than 90
      #     theta = Math.abs(thetaE - thetaS)
      #     if @quad is 's' and Math.abs(thetaE - thetaS) > HALF_PI
      #       continue
      #     else
      #      if @quad is 'm' and theta >= Math.PI then large = 1
      #      cen = { x: c.x, y: c.y }
      #      break
      #   rTool = if @trace.region then 0 else @tools[@currentTool].bbox().xMax
      #   # switch calculations to CCW to make things easier
      #   if @mode is 'cw' then [thetaE, thetaS] = [thetaS, thetaE]
      #   # maxima targets
      #   xp = if thetaS > 0 then TWO_PI else 0
      #   yp = HALF_PI + (if thetaS > HALF_PI then TWO_PI else 0)
      #   xn = Math.PI + (if thetaS > Math.PI then TWO_PI else 0)
      #   yn = THREEHALF_PI + (if thetaS > THREEHALF_PI then TWO_PI else 0)
      #   # minimum x is either at the negative x axis or an endpoint
      #   if thetaS <= xn <= thetaE
      #     xMin = cen.x - r - rTool
      #   else
      #     xMin = (Math.min start.x, end.x) - rTool
      #   # max x is going to be at positive x or endpoint
      #   if thetaS <= xp <= thetaE
      #     xMax = cen.x + r + rTool
      #   else
      #     xMax = (Math.max start.x, end.x) + rTool
      #   # minimum y is either at negative y axis or an endpoint
      #   if thetaS <= yn <=thetaE
      #     yMin = cen.y - r - rTool
      #   else
      #     yMin = (Math.min start.y, end.y) - rTool
      #   # max y is going to be at positive y or endpoint
      #   if thetaS <= yp <= thetaE
      #     yMax = cen.y + r + rTool
      #   else
      #     yMax = (Math.max start.y, end.y) + rTool
      #   # check for special case: full circle
      #   if @quad is 'm' and (Math.abs(start.x - end.x) < 0.000001) and
      #   (Math.abs(start.y - end.y) < 0.000001)
      #     # we'll need two paths (180 deg each)
      #     @trace.path +=
      #       "A#{r} #{r} 0 0 #{sweep} #{end.x+2*end.i} #{end.y+2*end.j}"
      #     # bbox is going to just be a rectangle
      #     xMin = cen.x - r - rTool
      #     yMin = cen.y - r - rTool
      #     xMax = cen.x + r + rTool
      #     yMax = cen.y + r + rTool
      #   # add the arc to the path
      #   @trace.path += "A#{r} #{r} 0 #{large} #{sweep} #{end.x} #{end.y}"
      #   # add the bounding box
      #   @addBbox { xMin: xMin, yMin: yMin, xMax: xMax, yMax: yMax }


  finishStepRepeat: () ->
    if @stepRepeat.x isnt 1 or @stepRepeat.y isnt 1
      if @layer.level isnt 0
        throw new Error 'step repeat with clear levels is unimplimented'
      srId = @layer.current.g.id
      @layer.current = @group
      for x in [ 0...@stepRepeat.x ]
        for y in [ 0...@stepRepeat.y ]
          unless x is 0 and y is 0
            @layer.current[@layer.type]._.push {
              use: {
                x: x*@stepRepeat.xStep
                y: y*@stepRepeat.yStep
                'xlink:href': srId
              }
            }

  addBbox: (bbox) ->
    if bbox.xMin < @bbox.xMin then @bbox.xMin = bbox.xMin
    if bbox.yMin < @bbox.yMin then @bbox.yMin = bbox.yMin
    if bbox.xMax > @bbox.xMax then @bbox.xMax = bbox.xMax
    if bbox.yMax > @bbox.yMax then @bbox.yMax = bbox.yMax

module.exports = Plotter
