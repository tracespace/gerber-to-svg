# svg plotter class

# is a transform stream
TransformStream = require('stream').Transform
# warning object
Warning = require './warning'
# unique id generator
unique = require './unique-id'
# aperture macro class
Macro = require './macro-tool'
# standard tool functions
tool = require './standard-tool'
# coordinate scale factor
coordFactor = require('./svg-coord').factor

# constants
HALF_PI = Math.PI / 2
THREEHALF_PI = 3 * HALF_PI
TWO_PI = 2 * Math.PI
# assumed units
ASSUMED_UNITS = 'in'

class Plotter extends TransformStream
  constructor: (opts = {}) ->
    @units = opts.units
    @notation = opts.notation

    # defined tools
    @tools = {}

    # object mode transform
    super {objectMode: true}

  # main transform method; called on incoming parser objects
  _transform: (chunk, encoding, done) ->
    # check if there's a set command
    for state, val of chunk.set
      # set the plotters state as required
      # if setting current tool, make sure it exists and region mode is off
      if state is 'currentTool'
        unless @tools[val]?
          @emit 'warning', new Warning("tool #{val} is undefined", chunk.line)
        if @region
          done new Error """
            line #{chunk.line} - cannot change tool while region mode is on
          """
          return

      # units and notation should not be overridden if already defined
      if state is 'units' or state is 'backupUnits' or state is 'notation'
        @[state] ?= val
      # everything else just sets the property
      else
        @[state] = val

    done()

  # constructor: (@reader, @parser, opts = {}) ->
  #   # parse options object
  #   # options can be used for units and notation
  #   @units = opts.units ? null
  #   @notation = opts.notation ? null
  #   # tools and macros
  #   @macros = {}
  #   @tools = {}
  #   @currentTool = ''
  #   # array for pad and mask definitions and image group
  #   @defs = []
  #   @group = { g: { _: [] } }
  #   # current layer and its polarity
  #   @polarity = 'D'
  #   @current = []
  #   # step and repeat, initially set to no repeat
  #   @stepRepeat = { x: 1, y: 1, i: 0, j: 0 }
  #   @srOverClear = false
  #   @srOverCurrent = []
  #   # operating mode
  #   @mode = null
  #   @quad = null
  #   @lastOp = null
  #   @region = false
  #   @done = false
  #   # operation state (position and current region or trace path)
  #   @pos = { x: 0, y: 0 }
  #   @path = []
  #   # bounding boxes of plotted image and image wide stroke and fill props
  #   @attr = {
  #     'stroke-linecap': 'round'
  #     'stroke-linejoin': 'round'
  #     'stroke-width': 0
  #     stroke: '#000'
  #   }
  #   @bbox = {
  #     xMin: Infinity, yMin: Infinity, xMax: -Infinity, yMax: -Infinity
  #   }
  #   @layerBbox = {
  #     xMin: Infinity, yMin: Infinity, xMax: -Infinity, yMax: -Infinity
  #   }
  #
  # # add a tool to the tool list
  # addTool: (code, params) ->
  #   if @tools[code]? then throw new Error "cannot reassign tool #{code}"
  #   # get the tool
  #   if params.macro? then t = @macros[params.macro].run code, params.mods
  #   else t = tool code, params
  #   # set the object in the tools collection
  #   @tools[code] = {
  #     trace: t.trace
  #     pad: (obj for obj in t.pad)
  #     flash: (x, y) -> { use: { x: x, y: y, 'xlink:href': "##{t.padId}" } }
  #     flashed: false
  #     bbox: (x = 0, y = 0) -> {
  #       xMin: x + t.bbox[0]
  #       yMin: y + t.bbox[1]
  #       xMax: x + t.bbox[2]
  #       yMax: y + t.bbox[3]
  #     }
  #   }
  #   # set the current tool to the one just defined
  #   @changeTool code
  #   # since this was a tool change, finish the path
  #
  # # change the tool
  # changeTool: (code) ->
  #   # finish any in progress path
  #   @finishPath()
  #   # throw an error if in region mode or if tool does not exist
  #   if @region then throw new Error 'cannot change tool when in region mode'
  #   # throw if tool doesn't exist if it's a gerber. if it's a drill, just
  #   # let it slide
  #   unless @tools[code]?
  #     unless @parser?.fmat then throw new Error "tool #{code} is not defined"
  #   # change the tool if it exists
  #   else @currentTool = code
  #
  # # handle a command that comes in from the parser
  # command: (c) ->
  #   # if the command is a macro command, it's going to appear alone
  #   if c.macro?
  #     m = new Macro c.macro, @parser.format.places
  #     @macros[m.name] = m
  #     return
  #
  #   # if there's a set command
  #   for state, val of c.set
  #     # if the region mode changes, then we need to finish the current path
  #     if state is 'region' then @finishPath()
  #     switch state
  #       # change the tool if it was a tool change
  #       when 'currentTool' then @changeTool val
  #       # units and notation should not be overridden if already defined
  #       when 'units', 'notation' then @[state] ?= val
  #       # everything else just sets the property
  #       else @[state] = val
  #
  #   # if there's a tool command
  #   if c.tool? then @addTool code, params for code, params of c.tool
  #
  #   # if there's an operate command, then IT'S TIME TO OPERATE
  #   if c.op? then @operate c.op
  #
  #   # if it's a new command, then we're making a new layer or step repeat
  #   if c.new?
  #     # finish the in progress layer
  #     @finishLayer()
  #     # set the new params
  #     if c.new.layer?
  #       @polarity = c.new.layer
  #     else if c.new.sr?
  #       @finishSR()
  #       @stepRepeat = c.new.sr
  #
  #
  # # go through the gerber file and return an xml object with the svg
  # plot: ->
  #   until @done
  #     # grab the next command. if it returns false we've hit end of file
  #     block = @reader.nextBlock()
  #     if block is false
  #       # if it's not a drill file
  #       unless @parser?.fmat?
  #         throw new Error 'end of file encountered before M02 command'
  #       else
  #         throw new Error 'end of drill file before M00/M30 command'
  #     else
  #       @command @parser.parseCommand block
  #   # finish and return the xml object
  #   @finish()
  #
  # finish: ->
  #   @finishPath()
  #   @finishLayer()
  #   @finishSR()
  #   # set default fill and stroke to current color in the group
  #   @group.g.fill = 'currentColor'; @group.g.stroke = 'currentColor'
  #   # flip vertically
  #   @group.g.transform = "translate(0,#{@bbox.yMin + @bbox.yMax}) scale(1,-1)"
  #
  # # finish step repeat method
  # # really only does anything if clear layers overlap
  # finishSR: ->
  #   if @srOverClear and @srOverCurrent
  #     maskId = "gerber-sr-mask_#{unique()}"
  #     m = { mask: { color: '#000', id: maskId, _: [] } }
  #     m.mask._.push {
  #       rect: {
  #         fill: '#fff'
  #         x: @bbox.xMin
  #         y: @bbox.yMin
  #         width: @bbox.xMax - @bbox.xMin
  #         height: @bbox.yMax - @bbox.yMin
  #       }
  #     }
  #     # loop through the repeats
  #     for x in [ 0...@stepRepeat.x * @stepRepeat.i ] by @stepRepeat.i
  #       for y in [ 0...@stepRepeat.y * @stepRepeat.j ] by @stepRepeat.j
  #         for layer in @srOverCurrent
  #           u = { use: {} }
  #           u.use.x = x if x isnt 0
  #           u.use.y = y if y isnt 0
  #           u.use['xlink:href'] = '#' + (layer.C ? layer.D)
  #           if layer.D? then u.use.fill = '#fff'
  #           m.mask._.push u
  #     # clear the flag and current array
  #     @srOverClear = false; @srOverCurrent = []
  #     # push the mask to the defs
  #     @defs.push m
  #     # mask the current group
  #     @group.g.mask = "url(##{maskId})"
  #
  # finishLayer: ->
  #   # finish any in progress path
  #   @finishPath()
  #   # only do something if there's stuff in the current layer
  #   unless @current.length then return
  #   # check for a step repeat
  #   if @stepRepeat.x > 1 or @stepRepeat.y > 1
  #     # wrap current up in a group with an sr id
  #     srId = "gerber-sr_#{unique()}"
  #     @current = [ { g: { id: srId, _: @current } } ]
  #     # warn if polarity is clear and steps overlap the bbox
  #     if @srOverClear or
  #     @stepRepeat.i < @layerBbox.xMax - @layerBbox.xMin or
  #     @stepRepeat.j < @layerBbox.yMax - @layerBbox.yMin
  #       obj = {}; obj[@polarity] = srId
  #       @srOverCurrent.push obj
  #       if @polarity is 'C'
  #         @srOverClear = true
  #         @defs.push @current[0]
  #     for x in [ 0...@stepRepeat.x ]
  #       for y in [ 0...@stepRepeat.y ]
  #         unless x is 0 and y is 0
  #           u = { use: { 'xlink:href': "##{srId}" } }
  #           u.use.x = x * @stepRepeat.i if x isnt 0
  #           u.use.y = y * @stepRepeat.j if y isnt 0
  #           @current.push u
  #     # adjust the bbox
  #     @layerBbox.xMax += (@stepRepeat.x - 1) * @stepRepeat.i
  #     @layerBbox.yMax += (@stepRepeat.y - 1) * @stepRepeat.j
  #
  #   # add the layerBbox to the doc bbox
  #   @addBbox @layerBbox, @bbox
  #   @layerBbox = {
  #     xMin: Infinity, yMin: Infinity, xMax: -Infinity, yMax: -Infinity
  #   }
  #   # if dark polarity
  #   if @polarity is 'D'
  #     # is there an existing group that's been cleared, then we need to wrap
  #     # insert the group at the beginning of current
  #     if @group.g.mask? then @current.unshift @group
  #     # set the group
  #     if not @group.g.mask? and @group.g._.length
  #       @group.g._.push c for c in @current
  #     else @group = { g: { _: @current } }
  #   # else clear polarity
  #   else if @polarity is 'C' and not @srOverClear
  #     # make a mask
  #     id = "gerber-mask_#{unique()}"
  #     # shift in the bbox rect to keep everything
  #     w = @bbox.xMax - @bbox.xMin; h = @bbox.yMax - @bbox.yMin
  #     @current.unshift {
  #      rect: {x: @bbox.xMin, y: @bbox.yMin, width: w, height: h, fill: '#fff'}
  #     }
  #     # push the masks to the definitions
  #     @defs.push { mask: { id: id, color: '#000', _: @current}}
  #     # add the mask to the group
  #     @group.g.mask = "url(##{id})"
  #   # empty out current
  #   @current = []
  #
  # finishPath: ->
  #   if @path.length
  #     p = { path: {} }
  #     # if we're in region mode, check for start and end match and close
  #     if @region then @path.push 'Z'
  #     # else, apply the stroke properties
  #     else p.path[key] = val for key, val of @tools[@currentTool].trace
  #     # stick the path data in, push to the current layer, and empty the path
  #     p.path.d = @path
  #     @current.push p
  #     @path = []
  #
  # # operate method takes the operation object
  # operate: (op) ->
  #   # get and set the lastOp as necessary
  #   if op.do is 'last'
  #     op.do = @lastOp
  #     console.warn 'modal operation codes are deprecated'
  #   else @lastOp = op.do
  #   # get the start position
  #   sx = @pos.x; sy = @pos.y
  #   # move the plotter position
  #   # coordinates are modal, so adapt accordingly
  #   if @notation is 'I'
  #     @pos.x += op.x ? 0; @pos.y += op.y ? 0
  #   else @pos.x = op.x ? @pos.x; @pos.y = op.y ? @pos.y
  #   # get the end position
  #   ex = @pos.x; ey = @pos.y
  #   # get the current tool
  #   t = @tools[@currentTool]
  #
  #   # do a check for units and notation (ensures format is properly set)
  #   unless @units?
  #     if @backupUnits?
  #       @units = @backupUnits
  #       console.warn "units set to '#{@units}' according to
  #                     deprecated command G7#{if @units is 'in' then 0 else 1}"
  #     else
  #       @units = ASSUMED_UNITS
  #       console.warn 'no units set; assuming inches'
  #   unless @notation?
  #     # if drill file, assume absolute notation
  #     if @parser?.fmat? then @notation = 'A'
  #     # else throw error
  #     else throw new Error 'format has not been set'
  #
  #   # switch through the actual operation
  #   # a move adds a move to the path if there is one, else we've already moved
  #   if op.do is 'move' and @path.length then @path.push 'M', ex, ey
  #   # a flash adds a pad to the current layer
  #   else if op.do is 'flash'
  #     # end any in progress path
  #     @finishPath()
  #     # check that region mode isn't on
  #     if @region then throw new Error 'cannot flash while in region mode'
  #     # add the pad to the definitions if necessary, and then flash the layer
  #     unless t.flashed
  #       @defs.push shape for shape in t.pad
  #       t.flashed = true
  #     @current.push t.flash ex, ey
  #     # update the bounding box
  #     @addBbox t.bbox(ex, ey), @layerBbox
  #   # finally, an interpolate makes a trace or defines a region
  #   # right here, though, it's mostly just gonna add stuff to @path
  #   else if op.do is 'int'
  #     # if we're not in region mode, check if the tool is strokable
  #     if not @region and not t.trace
  #       throw new Error "#{@currentTool} is not a strokable tool"
  #     # if there's no path right now, we'd better start one
  #     if @path.length is 0
  #       # start the path
  #       @path.push 'M', sx, sy
  #       # start the bbox
  #       bbox = unless @region then t.bbox sx, sy else {
  #         xMin: sx, yMin: sy, xMax: sx, yMax: sy
  #       }
  #       @addBbox bbox, @layerBbox
  #     # check for a mode, and assume linear if necessary
  #     unless @mode?
  #       @mode = 'i'
  #       console.warn 'no interpolation mode set. Assuming linear (G01)'
  #
  #     # let's draw something
  #     if @mode is 'i'
  #       @drawLine sx, sy, ex, ey
  #     else
  #       @drawArc sx, sy, ex, ey, op.i ? 0, op.j ? 0
  #
  # # draw a line with the start and end point
  # drawLine: (sx, sy, ex, ey) ->
  #   t = @tools[@currentTool]
  #   # add to the bbox
  #   bbox = unless @region then t.bbox ex, ey else {
  #     xMin: ex, yMin: ey, xMax: ex, yMax: ey
  #   }
  #   @addBbox bbox, @layerBbox
  #   # check for a rectangular or circular tool
  #   # circular tool will have a stroke-width set, and is easy
  #   if @region or t.trace['stroke-width'] >= 0 then @path.push 'L', ex, ey
  #   # rectagular tools are complicated, though
  #   # we're going to use implicit linetos after movetos for ease
  #   else
  #     # width and height of tool
  #     halfWidth = t.pad[0].rect.width / 2
  #     halfHeight = t.pad[0].rect.height / 2
  #     # corners of the start and end rects
  #     sxm = sx - halfWidth
  #     sxp = sx + halfWidth
  #     sym = sy - halfHeight
  #     syp = sy + halfHeight
  #     exm = ex - halfWidth
  #     exp = ex + halfWidth
  #     eym = ey - halfHeight
  #     eyp = ey + halfHeight
  #     # get the quadrant we're in
  #     theta = Math.atan2 ey - sy, ex - sx
  #     # quadrant I
  #     if 0 <= theta < HALF_PI
  #       @path.push 'M',sxm,sym,sxp,sym,exp,eym,exp,eyp,exm,eyp,sxm,syp,'Z'
  #     # quadrant II
  #     else if HALF_PI <= theta <= Math.PI
  #       @path.push 'M',sxm,sym,sxp,sym,sxp,syp,exp,eyp,exm,eyp,exm,eym,'Z'
  #     # quadrant III
  #     else if -Math.PI <= theta < -HALF_PI
  #       @path.push 'M',sxp,sym,sxp,syp,sxm,syp,exm,eyp,exm,eym,exp,eym,'Z'
  #     # quadrant IV
  #     else if -HALF_PI <= theta < 0
  #       @path.push 'M',sxm,sym,exm,eym,exp,eym,exp,eyp,sxp,syp,sxm,syp,'Z'
  #
  # # draw an arc with the start point, end point, and center offset
  # drawArc: (sx, sy, ex, ey, i, j) ->
  #   # lets try this for arc point comparison epsilon
  #   # this value seems strict enough to prevent invalid arcs but forgiving
  #   # enough to let most gerbers draw
  #   arcEps = 1.5 * coordFactor * 10 ** (-1 * (@parser?.format.places[1] ? 7))
  #   t = @tools[@currentTool]
  #   # throw an error if the tool is rectangular
  #   if not @region and not t.trace['stroke-width']
  #  throw  Error "cannot stroke an arc with non-circular tool #{@currentTool}"
  #   # throw an error if quadrant mode was not set
  #   unless @quad? then throw new Error 'arc quadrant mode has not been set'
  #   #
  #   # get the radius of the arc from the offsets
  #   r = Math.sqrt i ** 2 + j ** 2
  #   # get the sweep flag (svg sweep flag is 0 for cw and 1 for ccw)
  #   sweep = if @mode is 'cw' then 0 else 1
  #   # large arc flag is if arc > 180 deg. this doesn't line up with gerber, so
  #   # we gotta calculate the arc length if we're in multi quadrant mode
  #   large = 0
  #   # get some arc angles for bounding box, large flag, and arc check
  #   # valid candidates for center
  #   validCen = []
  #   # potential candidates
  #   cand = [ [sx + i, sy + j] ]
  #   if @quad is 's'
  #     cand.push [sx - i, sy - j], [sx - i, sy + j], [sx + i, sy - j]
  #   # loop through the candidates and find centers that make sense
  #   for c in cand
  #     dist = Math.sqrt (c[0] - ex) ** 2 + (c[1] - ey) ** 2
  #     if (Math.abs r - dist) < arcEps then validCen.push { x: c[0], y: c[1] }
  #   # now let's calculate some angles
  #   thetaE = 0
  #   thetaS = 0
  #   cen = null
  #   # at most, we'll have two candidates
  #   # check the points to make sure we have a valid arc
  #   for c in validCen
  #     # find the angles and make positive
  #     thetaE = Math.atan2 ey - c.y, ex - c.x
  #     if thetaE < 0 then thetaE += TWO_PI
  #     thetaS = Math.atan2 sy - c.y, sx - c.x
  #     if thetaS < 0 then thetaS += TWO_PI
  #     # adjust angles so math comes out right
  #     # in cw, the angle of the start should always be greater than the end
  #     if @mode is 'cw' and thetaS < thetaE then thetaS += TWO_PI
  #     # in ccw, the start angle should be less than the end angle
  #     else if @mode is 'ccw' and thetaE < thetaS then thetaE += TWO_PI
  #     # calculate the sweep angle (abs value for cw)
  #     theta = Math.abs(thetaE - thetaS)
  #     # in single quadrant mode, center is good if it's less than 90
  #     if @quad is 's' and theta <= HALF_PI then cen = c
  #     else if @quad is 'm'
  #       # if the sweep angle is >= 180, then its an svg large arc
  #       if theta >= Math.PI then large = 1
  #       # take the center
  #       cen = { x: c.x, y: c.y }
  #     # break if we've found a center
  #     if cen? then break
  #   # if we didn't find a center, then it's an invalid arc
  #   unless cen?
  #     console.warn "start #{sx},#{sy} #{@mode} to end #{ex},#{ey} with center
  #       offset #{i},#{j} is an impossible arc in
  #       #{if @quad is 's' then 'single' else 'multi'} quadrant mode with
  #       epsilon set to #{arcEps}"
  #     return
  #   # get the radius of the tool for bbox calcs
  #   rTool = if @region then 0 else t.bbox().xMax
  #   # switch start and end angles to CCW to make things easier
  #   # this ensures thetaS is always less than thetaE in these calculations
  #   if @mode is 'cw' then [thetaE, thetaS] = [thetaS, thetaE]
  #   # maxima targets for bounding box
  #   xp = if thetaS > 0 then TWO_PI else 0
  #   yp = HALF_PI + (if thetaS > HALF_PI then TWO_PI else 0)
  #   xn = Math.PI + (if thetaS > Math.PI then TWO_PI else 0)
  #   yn = THREEHALF_PI + (if thetaS > THREEHALF_PI then TWO_PI else 0)
  #   # minimum x is either at the negative x axis or an endpoint
  #   if thetaS <= xn <= thetaE then xMin = cen.x - r - rTool
  #   else xMin = (Math.min sx, ex) - rTool
  #   # max x is going to be at positive x or endpoint
  #   if thetaS <= xp <= thetaE then xMax = cen.x + r + rTool
  #   else xMax = (Math.max sx, ex) + rTool
  #   # minimum y is either at negative y axis or an endpoint
  #   if thetaS <= yn <= thetaE then yMin = cen.y - r - rTool
  #   else yMin = (Math.min sy, ey) - rTool
  #   # max y is going to be at positive y or endpoint
  #   if thetaS <= yp <= thetaE then yMax = cen.y + r + rTool
  #   else yMax = (Math.max sy, ey) + rTool
  #   # check for zerolength arc
  #   zeroLength = (Math.abs(sx - ex) < arcEps) and (Math.abs(sy - ey) < arcEps)
  #   # check for special case: full circle
  #   if @quad is 'm' and zeroLength
  #     # we'll need two paths (180 deg each)
  #     @path.push 'A', r, r, 0, 0, sweep, ex + 2 * i, ey + 2 * j
  #     # bbox is going to just be a rectangle
  #     xMin = cen.x - r - rTool
  #     yMin = cen.y - r - rTool
  #     xMax = cen.x + r + rTool
  #     yMax = cen.y + r + rTool
  #   # add the arc to the path
  #   @path.push 'A', r, r, 0, large, sweep, ex, ey
  #   # close the path if it was a zero length single quadrant arc
  #   @path.push 'Z' if @quad is 's' and zeroLength
  #   # add the bounding box
  #   @addBbox { xMin: xMin, yMin: yMin, xMax: xMax, yMax: yMax }, @layerBbox
  #
  # addBbox: (bbox, target) ->
  #   if bbox.xMin < target.xMin then target.xMin = bbox.xMin
  #   if bbox.yMin < target.yMin then target.yMin = bbox.yMin
  #   if bbox.xMax > target.xMax then target.xMax = bbox.xMax
  #   if bbox.yMax > target.yMax then target.yMax = bbox.yMax

module.exports = Plotter
