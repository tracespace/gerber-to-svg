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
          # unit set
          when 'MO'
            u = p[2..3]
            unless c.set? then c.set = {}
            if u is 'IN' then c.set.units = 'in'
            else if u is 'MM' then c.set.units = 'mm'
            else throw new Error "#{p} is an invalid units setting"
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
      if op = block.match(/D0?[123]$/)?[0]
        op = op[op.length-1]
        op = if op is '1' then 'int' else if op is '2' then 'move' else 'flash'
        coord = parseCoord block.match(reCOORD)?[0], @format
        c.op = { do: op }
        c.op[axis] = val for axis, val of coord

    # return the command
    c
module.exports = GerberParser
