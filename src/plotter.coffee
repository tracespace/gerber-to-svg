# svg plotter class

# use the gerber parser class to parse the file
Parser = require './gerber-parser'
# unique id generator
unique = require './unique-id'
# aperture macro class
Macro = require './macro-tool'
# standard tool functions
tool = require './standard-tool'

# parse a aperture definition command and return the object
parseAD = (block) ->
  # first get the code
  code = (block.match /^ADD\d+/)?[0]?[2..]
  # throw an error early if code is bad
  unless code? and parseInt(code[1..], 10) > 9
    throw new SyntaxError "#{code} is an invalid tool code (must be >= 10)"
  # get the tool
  ad = null
  am = false
  switch block[2+code.length...4+code.length]
    when 'C,'
      mods = block[4+code.length..].split 'X'
      params = { dia: parseFloat mods[0] }
      if mods.length > 2 then params.hole = {
        width: parseFloat mods[2]
        height: parseFloat mods[1]
      }
      else if mods.length > 1 then params.hole = { dia: parseFloat mods[1] }
      ad = tool code, params
    when 'R,'
      mods = block[4+code.length..].split 'X'
      params = { width: parseFloat(mods[0]), height: parseFloat(mods[1]) }
      if mods.length > 3 then params.hole = {
        width: parseFloat mods[3]
        height: parseFloat mods[2]
      }
      else if mods.length > 2 then params.hole = { dia: parseFloat mods[2] }
      ad = tool code, params
    when 'O,'
      mods = block[4+code.length..].split 'X'
      params = { width: parseFloat(mods[0]), height: parseFloat(mods[1]) }
      if mods.length > 3 then params.hole = {
        width: parseFloat mods[3]
        height: parseFloat mods[2]
      }
      else if mods.length > 2 then params.hole = { dia: parseFloat mods[2] }
      params.obround = true
      ad = tool code, params
    when 'P,'
      mods = block[4+code.length..].split 'X'
      params = {
        dia: parseFloat(mods[0])
        verticies: parseFloat(mods[1])
      }
      if mods[2]? then params.degrees = parseFloat mods[2]
      if mods.length > 4 then params.hole = {
        width: parseFloat mods[4]
        height: parseFloat mods[3]
      }
      else if mods.length > 3 then params.hole = { dia: parseFloat mods[3] }
      ad = tool code, params
    else
      def = block[2+code.length..]
      name = (def.match /[a-zA-Z_$][a-zA-Z_$.]{0,126}(?=,)?/)?[0]
      unless name then throw new SyntaxError 'invalid definition with macro'
      mods = (def[name.length+1..]).split 'X'
      if mods.length is 1 and mods[0] is '' then mods = null
      am = { name: name, mods: mods }
  # return the tool and the tool code
  { macro: am, tool: ad, code: code }

class Plotter
  constructor: (file = '') ->
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
    @group = { g: [ { _attr: { id: "#{@gerberId}-layer-0" } } ] }
    @layer = {
      level: 0
      type: 'g'
      current: @group
    }
    # are we done with the file yet? no
    @done = false
    # unit system and coordinate format system
    @units = null
    @format = { set: false, zero: null, notation: null, places: null }
    @position = { x: 0, y: 0 }
    # operating mode
    @mode = null
    @trace = { region: false, path: '' }
    @quad = null
    # bounding box
    @bbox = { xMin: Infinity, yMin: Infinity, xMax: -Infinity, yMax: -Infinity }

  # go through the gerber file and return an xml object with the svg
  plot: () ->
    until @done
      # grab the next command
      current = @parser.nextCommand()
      console.log "next command is #{current}"
      # if it's a parameter command
      if current[0] is '%' then @parameter current else @operate current[0]
    # finish and return the xml object
    @finish()

  finish: () ->
    @finishTrace()
    width = parseFloat (@bbox.xMax - @bbox.xMin).toPrecision 10
    height = parseFloat (@bbox.yMax - @bbox.yMin).toPrecision 10
    xml = {
      svg: [
        {
          _attr: {
            id: @gerberId
            width: "#{width}#{@units}"
            height: "#{height}#{@units}"
            viewBox: "#{@bbox.xMin} #{@bbox.yMin} #{width} #{height}"
          }
        }
      ]
    }
    if @defs.length then xml.svg.push { defs: @defs }
    xml.svg.push @group
    # return xml
    xml

  parameter: (blocks) ->
    done = false
    if blocks[0] is '%' and blocks[blocks.length-1] isnt '%'
      throw new SyntaxError '@parameter should only be called with paramters'
    blocks = blocks[1..]
    index = 0
    until done
      block = blocks[index]
      switch block[0...2]
        when 'FS'
          invalid = false
          if @format.set
            throw new SyntaxError 'format spec cannot be redefined'
          try
            if block[2] is 'L' or block[2] is 'T' then @format.zero = block[2]
            else invalid = true
            if block[3] is 'A' or block[3] is 'I'
              @format.notation = block[3]
            else invalid = true
            if block[4] is 'X' and block[7] is 'Y' and
            block[5..6] is block[8..9]
              @format.places = [ parseInt(block[5],10), parseInt(block[6],10) ]
              if @format.places[0]>7 or @format.places[1]>7 then invalid = true
            else invalid = true
          catch error
            invalid = true
          if invalid then throw new SyntaxError 'invalid format spec'
          else @format.set = true
        when 'MO'
          u = block[2..]
          unless @units?
            if u is 'MM' then @units = 'mm' else if u is 'IN' then @units = 'in'
            else throw new SyntaxError "#{u} are unrecognized units"
          else throw new SyntaxError "gerber file may not redifine units"
        when 'AD'
          ad = parseAD blocks[index]
          if @tools[ad.code]? then throw new SyntaxError 'duplicate tool code'
          if ad.macro
            ad.tool = @macros[ad.macro.name].run ad.code, ad.macro.mods
          @tools[ad.code] = {
            stroke: ad.tool.trace
            flash: (x, y) ->
              {
                use: {
                  _attr: {
                    x: "#{x}", y: "#{y}", 'xlink:href': '#'+ad.tool.padId
                  }
                }
              }
            bbox: (x, y) ->
              {
                xMin: x + ad.tool.bbox[0]
                yMin: y + ad.tool.bbox[1]
                xMax: x + ad.tool.bbox[2]
                yMax: y + ad.tool.bbox[3]
              }
          }
          @defs.push obj for obj in ad.tool.pad
        when 'AM'
          m = new Macro blocks[...-1]
          @macros[m.name] = m
          done = true
        when 'SR'
          throw new Error 'step repeat unimplimented'
        when 'LP'
          p = block[2]
          unless p is 'D' or p is 'C'
            throw new SyntaxError "#{block} is an unrecognized level polarity"
          # if switching from clear to dark
          if p is 'D' and @layer.type is 'mask'
            groupId = "#{@gerberId}-layer-#{++@layer.level}"
            @group = { g: [ { _attr: { id: groupId } }, @group ] }
            @layer.current = @group
            @layer.type = 'g'
          # else if switching from dark to clear
          else if p is 'C' and @layer.type is 'g'
            maskId = "#{@gerberId}-layer-#{++@layer.level}"
            @defs.push { mask: [ { _attr: { id: maskId } } ] }
            @layer.current.g[0]._attr.mask = "url(##{maskId})"
            @layer.current = @defs[@defs.length-1]
            @layer.type = 'mask'
          # undefine the position per gerber spec
          @position.x = null
          @position.y = null

      if blocks[++index] is '%' then done = true

  operate: (block) ->
    valid = false
    # code for operations
    code = block[0..2]
    # check for end of file or deprecated M command
    if block[0] is 'M'
      if code is 'M02'
        @done = true
        block = ''
      else unless (code is 'M00' or code is 'M01')
        throw new SyntaxError 'invalid operation M code'
      valid = true
    # else check for a G code
    else if block[0] is 'G'
      # set interpolation mode
      if block.match /^G0?1/
        @mode = 'i'
      else if block.match /^G0?2/
        @mode = 'cw'
      else if block.match /^G0?3(?![67])/
        @mode = 'ccw'
      # set region mode
      else if code is 'G36'
        @finishTrace()
        @trace.region = true
      else if code is 'G37'
        @finishTrace()
        @trace.region = false
      else if code is 'G74'
        @quad = 's'
      else if code is 'G75'
        @quad = 'm'
      # check for comments or deprecated, else throw
      else unless code.match /^G(0?4)|(5[45])|(7[01])|(9[01])/
        throw new SyntaxError 'invalid operation G code'
      valid = true
    # else check for a tool change
    else if block[0] is 'D' and not block.match /D0?[123]$/
      unless @tools[block]?
        throw new SyntaxError "tool #{block} does not exist"
      if @trace.region
        throw new SyntaxError "cannot change tool while region mode is on"
      @currentTool = block

    # now let's check for a coordinate block
    if block.match /^(G0?[123])?([XYIJ][+-]?\d+){0,4}D0?[123]$/
      # if the last char is a 2, we've got a move
      op = block[block.length - 1]
      coord = (block.match /[XYIJ][+-]?\d+/g)?.join ''
      start = { x: @position.x, y: @position.y }
      end = @move coord
      # if it's a 3, we've got a flash
      if op is '3'
        # finish any in progress path
        @finishTrace()
        # add the pad to the layer
        @layer.current[@layer.type]
          .push @tools[@currentTool].flash @position.x, @position.y
        # update the board's bounding box
        @addBbox @tools[@currentTool].bbox @position.x, @position.y

      # finally, if it's a 1, we've got an interpolate
      else if op is '1'
        # if there's no path yet, we need to move to the current point
        unless @trace.path
          @trace.path = "M#{start.x} #{start.y}"
          # also add the start to the bounding box
          if @trace.region
            @addBbox {
              xMin: start.x, yMin: start.y, xMax: start.x, yMax: start.y
            }
          else
            @addBbox @tools[@currentTool].bbox start.x, start.y
        # check what kind of interpolate we're doing
        # linear interpolation adds an absolute line to the path
        if @mode is 'i'
          # add the segment to the path
          @trace.path += "L#{end.x} #{end.y}"
          # add the segment to the bbox
          if @trace.region
            @addBbox {
              xMin: end.x, yMin: end.y, xMax: end.x, yMax: end.y
            }
          else
            @addBbox @tools[@currentTool].bbox end.x, end.y
        # are interpolation adds an eliptical (circular) arc to the path
        else if @mode is 'cw' or @mode is 'ccw'
          r = Math.sqrt end.i**2 + end.j**2
          sweep = if @mode is 'cw' then 0 else 1
          # svg large arc flag hinges at 180 rather than 90
          large = if @quad is 's' then 0 else
            cen = { x: start.x + end.i, y: start.y + end.j }
            # check the arc angle
            thetaE = Math.atan2 end.y-cen.y, end.x-cen.x
            if thetaE < 0 then thetaE = 2*Math.PI + thetaE
            thetaS = Math.atan2 start.y-cen.y, start.x-cen.x
            if thetaS < 0 then thetaS = 2*Math.PI + thetaS
            theta = Math.abs thetaE - thetaS
            # get the arc for CW vs CCW
            if @mode is 'ccw' then theta = 2*Math.PI - theta
            # check for the special condition of a full circle
            if (Math.abs(start.x - end.x) < 0.000001) and
            (Math.abs(start.y - end.y) < 0.000001)
              # we'll need two paths (180 deg each)
              @trace.path +=
                "A#{r} #{r} 0 0 #{sweep} #{end.x+2*end.i} #{end.y+2*end.j}"
            # set the large arc flag if it's greater than 180 (pi radians)
            if theta >= Math.PI then 1 else 0
          # add the arc to the path
          @trace.path += "A#{r} #{r} 0 #{large} #{sweep} #{end.x} #{end.y}"
        # if there wasn't a mode set then we're in trouble
        else throw new SyntaxError 'cannot interpolate without a G01/2/3'
      else if op is '2'
        @finishTrace()
      else
        throw new SyntaxError "#{op} is an invalid operation (D) code"

  finishTrace: () ->
    # if there's a trace going on
    if @trace.path
      p = { path: { _attr: { d: @trace.path } } }
      # apply proper path attributes
      if @trace.region
        p.path._attr['stroke-width'] = '0'
        p.path._attr.fill = 'currentColor'
      else
        for key, val of @tools[@currentTool].stroke
          p.path._attr[key] = val
      # push the path to the current layer
      @layer.current[@layer.type].push p
      # empty the path out
      @trace.path = ''

  move: (coord) ->
    unless @units? then throw new Error 'units have not been set'
    newPosition = @coordinate coord
    @position.x = newPosition.x
    @position.y = newPosition.y
    # return the new position
    newPosition

  # take a coordinate string with format given by the format spec
  # return an absolute position
  coordinate: (coord) ->
    unless @format.set then throw new SyntaxError 'format undefined'
    result = { x: 0, y: 0 }
    # pull out the x, y, i, and j
    result.x = coord.match(/X[+-]?\d+/)?[0]?[1..]
    result.y = coord.match(/Y[+-]?\d+/)?[0]?[1..]
    result.i = coord.match(/I[+-]?\d+/)?[0]?[1..]
    result.j = coord.match(/J[+-]?\d+/)?[0]?[1..]
    # loop through matched coordinates
    for key, val of result
      if val?
        divisor = 1
        if val[0] is '+' or val[0] is '-'
          divisor = -1 if val[0] is '-'
          val = val[1..]
        if @format.zero is 'L' then divisor *= 10 ** @format.places[1]
        else if @format.zero is 'T'
          divisor *= 10 ** (val.length - @format.places[0])
        else throw new SyntaxError 'invalid zero suppression format'
        result[key] = Number(val) / divisor
        # incremental coordinate support
        if @format.notation is 'I' then result[key] += (@position[key] ? 0)
    # apply defaults to missing
    unless result.x? then result.x = @position.x
    unless result.y? then result.y = @position.y
    unless result.i? then result.i = 0
    unless result.j? then result.j = 0
    # return the result
    result

  addBbox: (bbox) ->
    if bbox.xMin < @bbox.xMin then @bbox.xMin = bbox.xMin
    if bbox.yMin < @bbox.yMin then @bbox.yMin = bbox.yMin
    if bbox.xMax > @bbox.xMax then @bbox.xMax = bbox.xMax
    if bbox.yMax > @bbox.yMax then @bbox.yMax = bbox.yMax

module.exports = Plotter
