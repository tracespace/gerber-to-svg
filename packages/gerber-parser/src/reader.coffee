# file reader base class
# transform stream

TransformStream = require('stream').Transform

class Reader extends TransformStream
  constructor: ->
    @current = []
    @line = 1
    @type = 'block'

    super {
      decodeStrings: false
      readableObjectMode: true
    }

  _transform: (chunk, encoding, callback) ->
    for char in chunk
      if char is '%'
        @type = if @type is 'block' then 'param' else 'block'
      else if char is '*'
        output = {line: @line}
        output[@type] = @current.join ''
        @push output
        @current = []
      else if ' ' <= char <= '~'
        @current.push char
      else if char is '\n'
        @line++

    callback()


module.exports = Reader
