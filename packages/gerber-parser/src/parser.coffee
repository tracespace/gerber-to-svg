# generic file parser for gerber and drill files

Transform = require('stream').Transform
isError = require('lodash.iserror')

class Parser extends Transform
  constructor: (formatOpts = {}) ->
    @format = {
      zero: formatOpts.zero ? null
      places: formatOpts.places ? null
    }
    super {
      readableObjectMode: true
      writableObjectMode: true
    }

    # make sure places was set correctly
    if @format.places?
      if @format.places.length isnt 2 or
      typeof @format.places[0] isnt 'number' or
      typeof @format.places[1] isnt 'number'
        throw new Error 'parser places format must be an array of two numbers'

    # make sure zero was set correctly
    if @format.zero? and @format.zero isnt 'L' and @format.zero isnt 'T'
      throw new Error "parser zero format must be either 'L' or 'T'"

  _transform: (chunk, encoding, done) ->
    if chunk.block?
      result = @parseBlock chunk.block, chunk.line
    else if chunk.param?
      result = @parseParam chunk.param, chunk.line

    err = if isError(result) then result else null

    if result? and not err? then result.line = chunk.line

    done(err, if err then {} else result)

module.exports = Parser
