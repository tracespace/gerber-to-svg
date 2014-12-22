# gerber parser class
# keeps track of coordinate format
# takes a gerber block object and acts accordingly

# parse coordinate function
parseCoord = require './coord-parser'

# constants
# regular expression to match a coordinate
reCOORD = /([XYIJ][+-]?\d+){1,4}/g

class GerberParser
  constructor: ->
    # coordinate format (places and zero suppression)
    @format = { zero: null, places: null }

  # parse a format block
  parseFormat: (p, c) ->
    zero = if p[2] is 'L' or p[2] is 'T' then p[2] else null
    nota = if p[3] is 'A' or p[3] is 'I' then p[3] else null
    if p[4] is 'X' and p[7] is 'Y' and p[5..6] is p[8..9] and
    p[5] < 8 and p[6] < 8
      places = [ +p[5], +p[6] ]
    if not places? or not nota? or not zero?
      throw new Error "invalid format specification"
    @format.zero = zero; @format.places = places
    unless c.set? then c.set = {}
    c.set.notation = nota

  # parse a aperture definition block
  parseToolDef: (p, c) ->
    unless c.tool? then c.tool = {}
    code = p.match(/^ADD\d{2,}/)?[0][2..]
    # get the shape and modifiers
    [shape, mods] = p[2+code.length..].split ','
    mods = mods?.split 'X'
    # remove leading zeros from tool code
    code = code[0] + code[2..] while code[1] is '0'
    switch shape
      # circle
      when 'C'
        if mods.length > 2 then hole = { width: +mods[1], height: +mods[2] }
        else if mods.length > 1 then hole = { dia: +mods[1] }
        c.tool[code] = { dia: +mods[0] }
        if hole? then c.tool[code].hole = hole
      # rectangle, obround
      when 'R', 'O'
        if mods.length > 3 then hole = { width: +mods[2], height: +mods[3] }
        else if mods.length > 2 then hole = { dia: +mods[2] }
        c.tool[code] = {width: +mods[0], height: +mods[1] }
        if shape is 'O' then c.tool[code].obround = true
        if hole? then c.tool[code].hole = hole
      # polygon
      when 'P'
        if mods.length > 4 then hole = { width: +mods[3], height: +mods[4] }
        else if mods.length > 3 then hole = { dia: +mods[3] }
        c.tool[code] = { dia: +mods[0], verticies: +mods[1] }
        if mods.length > 2 then c.tool[code].degrees = +mods[2]
        if hole? then c.tool[code].hole = hole
      # else aperture macro
      else
        mods = (+m for m in (mods ? []))
        c.tool[code] = { macro: shape, mods: mods }

  # parse a block for the command
  parseCommand: (block = {}) ->
    # command
    c = {}
    # we're either going to have a parameter or a block
    if param = block.param
      # param will be an array of blocks, so let's loop through them
      for p in param
        # parameter code is first two letters
        switch code = p[0..1]
          # format set
          when 'FS'
            @parseFormat p, c
          # unit set
          when 'MO'
            u = p[2..3]
            unless c.set? then c.set = {}
            if u is 'IN' then c.set.units = 'in'
            else if u is 'MM' then c.set.units = 'mm'
            else throw new Error "#{p} is an invalid units setting"
          # aperture definition
          when 'AD'
            @parseToolDef p, c
          # aperture macro
          # aperture macro can only appear alone in a parameter block, so return
          when 'AM'
            return { macro: param }
          # new level polarity
          when 'LP'
            unless c.new? then c.new = {}
            c.new.layer = p[2] if p[2] is 'D' or p[2] is 'C'
            unless c.new.layer? then throw new Error 'invalid level polarity'
          # new step repeat
          when 'SR'
            unless c.new? then c.new = {}
            x = p.match(/X[+-]?[\d\.]+/)?[0][1..] ? 1
            y = p.match(/Y[+-]?[\d\.]+/)?[0][1..] ? 1
            i = p.match(/I[+-]?[\d\.]+/)?[0][1..]
            j = p.match(/J[+-]?[\d\.]+/)?[0][1..]
            # check for valid numbers and such
            if x<1 or y<1 or (x>1 and not i? or i<0) or (y>1 and not j? or j<0)
              throw new Error 'invalid step repeat'
            c.new.sr = { x: +x, y: +y }
            if i? then c.new.sr.i = +i
            if j? then c.new.sr.j = +j
    else if block = block.block
      # check for M02 (file done) code
      if block is 'M02' then return { set: { done: true } }
      # check for G codes
      else if block[0] is 'G'
        # grab the gcode and start a switch case
        switch code = block[1..].match(/^\d{1,2}/)?[0]
          # ignore comments
          when '4', '04' then return {}
          # interpolation mode
          when '1', '01', '2', '02', '3', '03'
            code = code[code.length-1]
            m = if code is '1' then 'i' else if code is '2' then 'cw' else 'ccw'
            c.set = { mode: m }
          # G36 and 37 set the region mode on and off respectively
          when '36', '37' then c.set = { region: code is '36' }
          # G70 and 71 set the backup units to inches and mm respectively
          when '70', '71'
            c.set = { backupUnits: if code is '70' then 'in' else 'mm' }
          when '74', '75'
            c.set = { quad: if code is '74' then 's' else 'm' }
      # check for coordinate operations
      # not an else if because G codes for mode set can go inline with
      # interpolate blocks
      coord = parseCoord block.match(reCOORD)?[0], @format
      if op = block.match(/D0?[123]$/)?[0] or Object.keys(coord).length
        if op? then op = op[op.length-1]
        op = switch op
          when '1' then 'int'
          when '2' then 'move'
          when '3' then 'flash'
          else 'last'
        c.op = { do: op }
        c.op[axis] = val for axis, val of coord
      # check for a tool change
      # this might be on the same line as a legacy G54
      else if tool = block.match(/D\d+$/)?[0]
        c.set = { currentTool: tool }

    # return the command
    c
module.exports = GerberParser
