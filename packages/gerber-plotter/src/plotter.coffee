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
# assumed format
ASSUMED_UNITS = 'in'

# bounding box helper function
addBbox = (bbox, target) ->
  if bbox.xMin < target.xMin then target.xMin = bbox.xMin
  if bbox.yMin < target.yMin then target.yMin = bbox.yMin
  if bbox.xMax > target.xMax then target.xMax = bbox.xMax
  if bbox.yMax > target.yMax then target.yMax = bbox.yMax

class Plotter extends TransformStream
  constructor: (opts = {}) ->
    @units = opts.units
    @notation = opts.notation

    # defined tools and macros
    @tools = {}
    @macros = {}

    # layer properties
    @stepRepeat = {x: 1, y: 1, i: 0, j: 0}

    # plotter state variables
    @x = 0
    @y = 0
    @firstOperation = true

    # current image
    @polarity = 'D'
    @defs = []
    @current = []
    @layerBbox = {
      xMin: Infinity
      yMin: Infinity
      xMax: -Infinity
      yMax: -Infinity
    }

    # step and repeat, initially set to no repeat
    @stepRepeat = { x: 1, y: 1, i: 0, j: 0 }
    @srOverClear = false
    @srOverCurrent = []

    # current trace and group
    @path = []
    @group = {g: {_: []}}

    # overall image
    @bbox = {
      xMin: Infinity
      yMin: Infinity
      xMax: -Infinity
      yMax: -Infinity
    }

    # object mode transform
    super {objectMode: true}

  # main transform method; called on incoming parser objects
  _transform: (chunk, encoding, done) ->
    # check for different commands
    if chunk.set?
      @handleSet chunk.set, chunk.line, done
    else if chunk.new?
      @handleNew chunk.new, chunk.line, done
    else if chunk.tool?
      @handleTool chunk.tool, chunk.line, done
    else if chunk.macro?
      @handleMacro chunk.macro, chunk.line, done
    else if chunk.op?
      @handleOperation chunk.op, chunk.line, done
    else
      done()

  # this is called when the incoming stream ends
  _flush: (done) ->
    # finish the plot
    @finish()

    # get image dimensions
    unless @group.g._.length
      @bbox = {xMin: 0, yMin: 0, xMax: 0, yMax: 0}
    else
      children = [
        {defs: {_: @defs}}
        @group
      ]

    width = @bbox.xMax - @bbox.xMin
    height = @bbox.yMax - @bbox.yMin

    # create an xml object
    xml = {
      svg: {
        xmlns: 'http://www.w3.org/2000/svg'
        version: '1.1'
        'xmlns:xlink': 'http://www.w3.org/1999/xlink'
        width: "#{width / coordFactor}#{@units}"
        height: "#{height / coordFactor}#{@units}"
        viewBox: [@bbox.xMin, @bbox.yMin, width, height]
        'stroke-linecap': 'round'
        'stroke-linejoin': 'round'
        'stroke-width': 0
        stroke: '#000'
        _: children ? []
      }
    }

    # push it and we're done
    @push xml

    done()

  # handle a set command to set the plotter's state as required
  handleSet: (set, line, done) ->
    for state, val of set
      # if setting current tool, make sure it exists and region mode is off
      if state is 'currentTool'
        unless @tools[val]?
          @emit 'warning', new Warning("tool #{val} is undefined", line)
        if @region
          return done new Error """
            line #{line} - cannot change tool while region mode is on
          """

        # if all is good, change the tool
        @changeTool val

      # units and notation should not be overridden if already defined
      else if state is 'units' or state is 'backupUnits' or state is 'notation'
        @[state] ?= val
      # everything else just sets the property
      else
        # finish any in progress path if we're changing region mode
        if state is 'region' then @finishPath()

        @[state] = val

    done()

  # handle new layer commands
  handleNew: (newLayer, line, done) ->
    # finish the current layer before
    @finishLayer()

    # handle a new layer accordingly
    if newLayer.sr?
      @finishSR()
      @stepRepeat = newLayer.sr
    else if newLayer.layer?
      @polarity = newLayer.layer
    else
      throw new Error "#{newLayer} is a poorly formatted or unknown new command"

    done()

  # add a tool to the tool list
  handleTool: (toolCommand, line, done) ->
    code = Object.keys(toolCommand)[0]
    params = toolCommand[code]

    if @tools[code]?
      return done new Error "line #{line} - tool #{code} was previously defined"

    if params.macro?
      macro = @macros[params.macro]
      handleMacroRunWarning = (w) =>
        w.message = """
          warning from macro #{params.macro} run at line #{line} - #{w.message}
        """
        @emit 'warning', w

      macro.on 'warning', handleMacroRunWarning
      t = macro.run code, params.mods
      macro.removeListener 'warning', handleMacroRunWarning

    else
      t = tool code, params

    # set the object in the tools collection
    @tools[code] = {
      code: code
      trace: t.trace
      pad: t.pad
      flash: (x, y) -> {use: {x: x, y: y, 'xlink:href': "##{t.padId}"}}
      flashed: false
      bbox: (x = 0, y = 0) -> {
        xMin: x + t.bbox[0]
        yMin: y + t.bbox[1]
        xMax: x + t.bbox[2]
        yMax: y + t.bbox[3]
      }
    }

    # set the current tool to the one just defined and finish
    @changeTool code
    done()

  # handle a new macro command
  handleMacro: (macroCommand, line, done) ->
    name = Object.keys(macroCommand)[0]
    blocks = macroCommand[name]
    macro = new Macro blocks
    @macros[name] = macro
    done()

  # chenge the current tool
  changeTool: (code) ->
    # end the current path before changing the tool
    @finishPath()

    @currentTool = @tools[code]

  prepareForFirstOperation: (line) ->
    @firstOperation = false

    unless @units?
      msg = "line #{line} - "
      if @backupUnits?
        @units = @backupUnits
        msg += "units set to #{@units} by deprecated G70/1"
      else
        @units = ASSUMED_UNITS
        msg += "no units set before first move; assuming #{ASSUMED_UNITS}"

      @emit 'warning', new Warning msg

    unless @notation?
      @notation = 'A'
      msg = "line #{line} - no coordinate notation set before first move;
        assuming absolute"

      @emit 'warning', new Warning msg

  handleOperation: (operation, line, done) ->
    # do a check for units and notation (ensures format is properly set)
    if @firstOperation then @prepareForFirstOperation line

    # move the plotter position
    sX = @x
    sY = @y
    if @notation is 'I'
      operation.x = (operation.x ? 0) + @x
      operation.y = (operation.y ? 0) + @y
    @x = operation.x ? @x
    @y = operation.y ? @y

    # handle modal operation codes, despite the fact that the are deprecated
    if operation.do is 'last'
      @emit 'warning', new Warning "line #{line} - modal operation codes are
        deprecated and not guarenteed to render properly"
      operation.do = @lastOperation
    else
      @lastOperation = operation.do

    if operation.do is 'flash'
      # # check that region mode isn't on
      if @region
        return done new Error "line #{line} - cannot flash while in region mode"

      # end any in progress path
      @finishPath()

      # add the pad to the definitions if necessary
      unless @currentTool.flashed
        @defs.push shape for shape in @currentTool.pad
        @currentTool.flashed = true

      # flash the layer and update the current layer's bounding box
      @current.push @currentTool.flash @x, @y
      addBbox @currentTool.bbox(@x, @y), @layerBbox

    else if operation.do is 'int'
      # make sure the current tool is strokable if we're not in region mode
      if not @region and not @currentTool.trace
        return done new Error """
          line #{line} - #{@currentTool.code} is not a strokable tool
        """

      # ensure we have an interpolation mode
      unless @mode?
        @mode = 'i'
        @emit 'warning', new Warning "line #{line} - interpolation mode was not
          set before first stroke; assuming linear"

      # start the path if needed
      unless @path.length then @path.push 'M', sX, sY

      # draw a line or arc
      if @mode is 'i'
        @drawLine sX, sY, line

      else
        # error if the tool is rectangular and region mode is off
        if not @region and not @currentTool.trace['stroke-width']?
          return done new Error "line #{line} - cannot stroke an arc with
            non-circular tool #{@currentTool.code}"

        # ensure we have a quadrant mode
        unless @quad?
          return done new Error "line #{line} - quadrant mode was not set
            before first arc draw"

        # otherwise we're good to draw an arc
        @drawArc sX, sY, operation.i, operation.j, line

    # else operation is a move
    else if @path.length
      @path.push 'M', @x, @y

    done()

  # draw a line from a start point to the current position
  drawLine: (sX, sY, lineNumber) ->
    # add start point and end point to the bbox
    if @region
      startBbox = {xMin: sX, yMin: sY, xMax: sX, yMax: sY}
      endBbox = {xMin: @x, yMin: @y, xMax: @x, yMax: @y}
    else
      startBbox = @currentTool.bbox sX, sY
      endBbox = @currentTool.bbox @x, @y
    addBbox startBbox, @layerBbox
    addBbox endBbox, @layerBbox

    # write to the path
    # if it's a circle, then there will be a stroke-width and the line is easy
    if @region or @currentTool.trace['stroke-width']?
      @path.push 'L', @x, @y

    # rectagular tools are complicated, though
    # we're going to use implicit linetos after movetos for ease
    else
      # width and height of tool
      halfWidth = @currentTool.pad[0].rect.width / 2
      halfHeight = @currentTool.pad[0].rect.height / 2
      # corners of the start and end rects
      sxm = sX - halfWidth
      sxp = sX + halfWidth
      sym = sY - halfHeight
      syp = sY + halfHeight
      exm = @x - halfWidth
      exp = @x + halfWidth
      eym = @y - halfHeight
      eyp = @y + halfHeight
      # get the quadrant we're in
      theta = Math.atan2 @y - sY, @x - sX
      # quadrant I
      if 0 <= theta < HALF_PI
        @path.push 'M',sxm,sym,sxp,sym,exp,eym,exp,eyp,exm,eyp,sxm,syp,'Z'
      # quadrant II
      else if HALF_PI <= theta <= Math.PI
        @path.push 'M',sxm,sym,sxp,sym,sxp,syp,exp,eyp,exm,eyp,exm,eym,'Z'
      # quadrant III
      else if -Math.PI <= theta < -HALF_PI
        @path.push 'M',sxp,sym,sxp,syp,sxm,syp,exm,eyp,exm,eym,exp,eym,'Z'
      # quadrant IV
      else if -HALF_PI <= theta < 0
        @path.push 'M',sxm,sym,exm,eym,exp,eym,exp,eyp,sxp,syp,sxm,syp,'Z'
      else
        throw new Error "rectangular stroke angle calculation yielded: #{theta}"

  # draw an arc to the path with the given start point and center offset
  drawArc: (sX, sY, i, j, lineNumber) ->
    # set offsets to default
    i ?= 0
    j ?= 0

    # get the radius of the arc from the offsets
    r = Math.sqrt i ** 2 + j ** 2
    # get the sweep flag (svg sweep flag is 0 for cw and 1 for ccw)
    sweep = if @mode is 'cw' then 0 else 1
    # large arc flag is if arc > 180 deg. this doesn't line up with gerber, so
    # we gotta calculate the arc length if we're in multi quadrant mode
    large = 0

    # get some arc angles for bounding box, large flag, and arc check
    # valid candidates for center
    validCenters = []
    # potential candidates
    centerCandidates = [[sX + i, sY + j]]
    # in single quadrant mode, are offset signs are implicit, so we need to
    # check all possible combinations
    if @quad is 's'
      centerCandidates.push [sX - i, sY - j], [sX - i, sY + j], [sX + i, sY - j]

    # loop through the candidates and find centers that make sense
    for c in centerCandidates
      dist = Math.sqrt (c[0] - @x) ** 2 + (c[1] - @y) ** 2
      if (Math.abs r - dist) < @epsilon
        validCenters.push {x: c[0], y: c[1]}

    # now let's calculate some angles
    thetaE = 0
    thetaS = 0
    cen = null
    # at most, we'll have two candidates
    # check the points to make sure we have a valid arc
    for c in validCenters
      # find the angles and make positive
      thetaE = Math.atan2 @y - c.y, @x - c.x
      if thetaE < 0 then thetaE += TWO_PI
      thetaS = Math.atan2 sY - c.y, sX - c.x
      if thetaS < 0 then thetaS += TWO_PI

      # adjust angles so math comes out right
      # in cw, the angle of the start should always be greater than the end
      if @mode is 'cw' and thetaS < thetaE
        thetaS += TWO_PI
      # in ccw, the start angle should be less than the end angle
      else if @mode is 'ccw' and thetaE < thetaS
        thetaE += TWO_PI

      # calculate the sweep angle (abs value for cw)
      theta = Math.abs(thetaE - thetaS)
      # in single quadrant mode, center is good if it's less than 90
      if @quad is 's' and theta <= HALF_PI
        cen = c
      else if @quad is 'm'
        # if the sweep angle is >= 180, then its an svg large arc
        if theta >= Math.PI then large = 1
        # take the center
        cen = {x: c.x, y: c.y}

      # break the loop if we've found a valid center
      if cen? then break

    # if we didn't find a center, then it's an invalid arc
    unless cen?
      @emit 'warning', new Warning "line #{lineNumber} - #{@mode} arc from
        (#{sX}, #{sY}) to (#{@x}, #{@y}) with center offset (#{i}, #{j}) is an
        impossible arc in #{if @quad is 's' then 'single' else 'multi'} quadrant
        mode with epsilon set to #{@epsilon}"
      return

    # get the radius of the tool for bbox calcs
    rTool = if @region then 0 else @currentTool.bbox().xMax

    # switch start and end angles to CCW to make things easier
    # this ensures thetaS is always less than thetaE in these calculations
    if @mode is 'cw' then [thetaE, thetaS] = [thetaS, thetaE]
    # maxima targets for bounding box
    xp = if thetaS > 0 then TWO_PI else 0
    yp = HALF_PI + (if thetaS > HALF_PI then TWO_PI else 0)
    xn = Math.PI + (if thetaS > Math.PI then TWO_PI else 0)
    yn = THREEHALF_PI + (if thetaS > THREEHALF_PI then TWO_PI else 0)

    # minimum x is either at the negative x axis or an endpoint
    if thetaS <= xn <= thetaE
      xMin = cen.x - r - rTool
    else
      xMin = (Math.min sX, @x) - rTool

    # max x is going to be at positive x or endpoint
    if thetaS <= xp <= thetaE
      xMax = cen.x + r + rTool
    else
      xMax = (Math.max sX, @x) + rTool

    # minimum y is either at negative y axis or an endpoint
    if thetaS <= yn <= thetaE
      yMin = cen.y - r - rTool
    else
      yMin = (Math.min sY, @y) - rTool

    # max y is going to be at positive y or endpoint
    if thetaS <= yp <= thetaE
      yMax = cen.y + r + rTool
    else
      yMax = (Math.max sY, @y) + rTool

    # check for zerolength arc
    xDiff = Math.abs sX - @x
    yDiff = Math.abs sY - @y
    zeroLength = (xDiff < @epsilon) and (yDiff < @epsilon)
    # check for special case: full circle
    if @quad is 'm' and zeroLength
      # we'll need two paths (180 deg each)
      @path.push 'A', r, r, 0, 0, sweep, @x + 2 * i, @y + 2 * j
      # bbox is going to just be a rectangle
      xMin = cen.x - r - rTool
      yMin = cen.y - r - rTool
      xMax = cen.x + r + rTool
      yMax = cen.y + r + rTool

    # add the arc to the path
    @path.push 'A', r, r, 0, large, sweep, @x, @y
    # close the path if it was a zero length single quadrant arc
    @path.push 'Z' if @quad is 's' and zeroLength

    # add the bounding box
    addBbox {xMin: xMin, yMin: yMin, xMax: xMax, yMax: yMax}, @layerBbox

  # finish the in progress path
  finishPath: ->
    if @path.length
      p = {path: {d: @path}}

      # if we're in region mode, close, else apply stroke properties
      if @region
        @path.push 'Z'
      else
        p.path[key] = val for key, val of @currentTool.trace

      # push to the current layer and empty the path
      @current.push p
      @path = []

  finishLayer: ->
    # finish any in progress path
    @finishPath()

    # only do something if there's stuff in the current layer
    unless @current.length then return

    # check for a step repeat
    if @stepRepeat.x > 1 or @stepRepeat.y > 1
      # wrap current up in a group with an sr id
      srId = "gerber-sr_#{unique()}"
      @current = [ { g: { id: srId, _: @current } } ]

      # warn if polarity is clear and steps overlap the bbox
      if @srOverClear or
      @stepRepeat.i < @layerBbox.xMax - @layerBbox.xMin or
      @stepRepeat.j < @layerBbox.yMax - @layerBbox.yMin
        obj = {}; obj[@polarity] = srId
        @srOverCurrent.push obj
        if @polarity is 'C'
          @srOverClear = true
          @defs.push @current[0]

      for x in [ 0...@stepRepeat.x ]
        for y in [ 0...@stepRepeat.y ]
          unless x is 0 and y is 0
            u = { use: { 'xlink:href': "##{srId}" } }
            u.use.x = x * @stepRepeat.i if x isnt 0
            u.use.y = y * @stepRepeat.j if y isnt 0
            @current.push u

      # adjust the bbox
      @layerBbox.xMax += (@stepRepeat.x - 1) * @stepRepeat.i
      @layerBbox.yMax += (@stepRepeat.y - 1) * @stepRepeat.j

    # add the layerBbox to the doc bbox
    addBbox @layerBbox, @bbox
    @layerBbox = {
      xMin: Infinity, yMin: Infinity, xMax: -Infinity, yMax: -Infinity
    }

    # if dark polarity
    if @polarity is 'D'
      # is there an existing group that's been cleared, then we need to wrap
      # insert the group at the beginning of current
      if @group.g.mask? then @current.unshift @group

      # set the group
      if not @group.g.mask? and @group.g._.length
        @group.g._.push c for c in @current
      else
        @group = { g: { _: @current } }

    # else clear polarity
    else if @polarity is 'C' and not @srOverClear
      # make a mask
      id = "gerber-mask_#{unique()}"
      # shift in the bbox rect to keep everything
      w = @bbox.xMax - @bbox.xMin
      h = @bbox.yMax - @bbox.yMin
      @current.unshift {
        rect: {x: @bbox.xMin, y: @bbox.yMin, width: w, height: h, fill: '#fff'}
      }

      # push the masks to the definitions
      @defs.push { mask: { id: id, color: '#000', _: @current}}
      # add the mask to the group
      @group.g.mask = "url(##{id})"

    # empty out current
    @current = []

  # finish step repeat method
  # really only does anything if clear layers overlap
  finishSR: ->
    if @srOverClear and @srOverCurrent
      maskId = "gerber-sr-mask_#{unique()}"
      m = { mask: { color: '#000', id: maskId, _: [] } }
      m.mask._.push {
        rect: {
          fill: '#fff'
          x: @bbox.xMin
          y: @bbox.yMin
          width: @bbox.xMax - @bbox.xMin
          height: @bbox.yMax - @bbox.yMin
        }
      }

      # loop through the repeats
      for x in [ 0...@stepRepeat.x * @stepRepeat.i ] by @stepRepeat.i
        for y in [ 0...@stepRepeat.y * @stepRepeat.j ] by @stepRepeat.j
          for layer in @srOverCurrent
            u = { use: {} }
            u.use.x = x if x isnt 0
            u.use.y = y if y isnt 0
            u.use['xlink:href'] = '#' + (layer.C ? layer.D)
            if layer.D? then u.use.fill = '#fff'
            m.mask._.push u

      # clear the flag and current array
      @srOverClear = false
      @srOverCurrent = []

      # push the mask to the defs
      @defs.push m

      # mask the current group
      @group.g.mask = "url(##{maskId})"

  finish: ->
    @finishLayer()
    @finishSR()
    # set default fill and stroke to current color in the group
    @group.g.fill = 'currentColor'; @group.g.stroke = 'currentColor'
    # flip vertically
    @group.g.transform = "translate(0,#{@bbox.yMin + @bbox.yMax}) scale(1,-1)"

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

module.exports = Plotter
