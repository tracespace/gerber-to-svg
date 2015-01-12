# generic file parser for gerber and drill files

class Parser
  constructor: (formatOpts = {}) ->
    @format = {
      zero: formatOpts.zero ? null
      places: formatOpts.places ? null
    }
    # make sure places was set correctly
    if @format.places?
      if (not Array.isArray @format.places) or
      @format.places.length isnt 2 or
      typeof @format.places[0] isnt 'number' or
      typeof @format.places[1] isnt 'number'
        throw new Error 'parser places format must be an array of two numbers'
    # make sure zero was set correctly
    if @format.zero?
      if typeof @format.zero isnt 'string' or
      (@format.zero isnt 'L' and @format.zero isnt 'T')
        throw new Error "parser zero format must be either 'L' or 'T'"

module.exports = Parser
