# drill block parser class
# keeps track of format stuff
# has a parseCommand method that takes a block and acts accordingly

# parse coordinate function
parseCoord = require './coord-parser'

# some command constants
INCH_COMMAND = { 'FMAT,1': 'M70', 'FMAT,2': 'M72'}
METRIC_COMMAND = 'M71'
ABS_COMMAND = 'G90'
INC_COMMAND = 'G91'

# drill coordinate
reCOORD = /([XY]-?\d*){1,2}/

# backup zero suppression and format
ZERO_BACKUP = 'L'
PLACES_BACKUP = [ 2, 4 ]

class DrillParser
  constructor: ->
    # format for parsing coordinates, set by each file
    # excellon specifies which zeros to keep, but here we're going to treat it
    # as suppression to match gerber
    @format = { zero: null, places: null }
    # format of the drill file
    # I don't think this is ever going to be used but whatever
    @fmat = 'FMAT,2'

  # parse a command block and return a command object
  parseCommand: (block) ->
    command = {}
    # check for comment
    if block[0] is ';' then return command

    # format 1 command
    # this will likely never happen
    if block is 'FMAT,1' then @fmat = block
    # end of file
    else if block is 'M30' or block is 'M00' then command.set = { done: true }
    # inches command
    else if block is INCH_COMMAND[@fmat] or block.match /INCH/
      # set the format to 2.4
      @format.places = [2, 4]
      # add set units object
      command.set = { units: 'in' }
    # metric command
    else if block is METRIC_COMMAND or block.match /METRIC/
      # set the format to 3.3
      @format.places = [3, 3]
      # add set units command object
      command.set = { units: 'mm' }
    # absolute notation
    else if block is ABS_COMMAND then command.set = { notation: 'abs' }
    # incremental notation
    else if block is INC_COMMAND then command.set = { notation: 'inc' }

    # tool definition
    else if ( code = block.match(/T\d+/)?[0] )
      # tool definition
      toolCode = "T#{Number code[1..]}"
      if ( dia = block.match(/C[\d\.]+(?=.*$)/)?[0] )
        dia = Number dia[1..]
        command.tool = {}
        command.tool[toolCode] = { dia: dia }
      else
        command.set = { currentTool: toolCode }

    # allow this to be tacked on the end of a command to be lenient
    # we're assuming trailing zero suppression, so we only care if the opposite
    # is specified (TZ for keep trailing zeros)
    if block.match /TZ/
      @format.zero = 'L'
    else if block.match /LZ/
      @format.zero = 'T'

    # finally, check for a drill command
    # some drill files may tack on tool changes at the end of files, so we'll
    # put this at the end, so any tool change will happen first
    if block.match reCOORD
      command.op = { do: 'flash' }
      # check for zero suppression
      unless @format.zero?
        console.warn 'no drill file zero suppression specified. assuming
          leading zero suppression (same as no zero suppression)'
        @format.zero = ZERO_BACKUP
      # check for format
      unless @format.places?
        console.warn 'no drill file units specified; assuming 2:4 inches format'
        @format.places = PLACES_BACKUP
      command.op[k] = v for k, v of parseCoord block, @format

    # return the command
    command

# export
module.exports = DrillParser
