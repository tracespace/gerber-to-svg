# stream capture for testing
# from http://stackoverflow.com/a/18543419/3826558

module.exports = (stream) ->
  oldWrite = stream.write;
  buf = '';
  stream.write = (chunk, encoding, callback) ->
    # chunk is a string or buffer
    buf += chunk.toString()
    oldWrite.apply stream, arguments

  return {
    unhook: -> stream.write = oldWrite
    captured: -> buf
  }
