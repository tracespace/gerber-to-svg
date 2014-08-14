# drill block parser class
# keeps track of format stuff
# has a parseCommand method that takes a block and acts accordingly

class DrillParser
  constructor: ->
    # whether or not it's the header section
    @header = false
    # format for parsing coordinates, set by each file
    @format = { zero: 't', notation: null, places: null }

  # parse a command block and return a command object
  parseCommand: (block) ->
    # if we're not in a header
    if not @header
      # a M48 means we are now
      if block is 'M48' then @header = true
    # if we're in the header
    else
      # end of header
      if block is 'M95' or block is '%' then @header = false
      # inches command
      else if block.match /(INCH)/
        # set the format to 2.4
        @format.places = [2, 4]
        # return set units object
        return { set: { units: 'in' } }
      # metric command
      else if block.match /(METRIC)/
        # set the format to 3.3
        @format.places = [3, 3]
        # return set units command object
        return { set: { units: 'mm' } }
      # tool definition
      else if block[0] is 'T'
        # tool code
        code = block.match(/^T\d+/)?[0]
        dia = Number block.match(/[\d\.]+(?=$)/)
        return { tool: { code: code, shape: { dia: dia } } }

# export
module.exports = DrillParser
