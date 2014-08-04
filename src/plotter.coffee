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
    @region = { on: false }
    @quad = null

  plot: () ->
    until @done
      current = @parser.nextCommand()
      # if it's a parameter command
      if current[0] is '%' then @parameter current else @operate current[0]

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
            flash: { use: { _attr: { 'xlink:href': '#'+ad.tool.padId } } }
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
        @region.on = true
      else if code is 'G37'
        @region.on = false
      else if code is 'G74'
        @quad = 's'
      else if code is 'G75'
        @quad = 'm'
      # check for comments or deprecated, else throw
      else unless code.match /^G(0?4)|(5[45])|(7[01])|(9[01])/
        throw new SyntaxError 'invalid operation G code'
      valid = true
    # now let's check for a coordinate block
    if block.match /^G0?[123](X\d+)?(Y\d+)?D0?[123]$/
      console.log block

  # take a coordinate string with format given by the format spec
  # return an absolute position
  coordinate: (coord) ->
    unless @format.set then throw new SyntaxError 'format undefined'
    result = { x: 0, y: 0 }
    # pull out the x and y
    x = coord.match(/X\d+/)?[0]?[1..]
    y = coord.match(/Y\d+/)?[0]?[1..]
    # leading zero suppression
    if @format.zero is 'L'
      divisor = Math.pow 10, @format.places[1]
      xDivisor = divisor
      yDivisor = divisor
    # else trailing zero suppression
    else if @format.zero is 'T'
      xDivisor = Math.pow 10, (x.length - @format.places[0])
      yDivisor = Math.pow 10, (y.length - @format.places[0])
    else throw new SyntaxError 'invalid zero suppression format'
    # calculate the result
    result.x = if x? then (Number(x) / xDivisor) else @position.x
    result.y = if y? then (Number(y) / yDivisor) else @position.y
    # adjust to absolute if incremental coordinates
    if @format.notation is 'I'
      result.x += if x? then @position.x else 0
      result.y += if y? then @position.y else 0
    # return
    result

module.exports = Plotter
