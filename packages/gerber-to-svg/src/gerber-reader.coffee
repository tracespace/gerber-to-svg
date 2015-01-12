# gerber file reader
# takes in a gerber string, and when nextBlock is called, returns the next
# command block. Also keeps track of gerber file line number

class GerberReader
  constructor: (@gerberFile = '') ->
    @line = 0
    # read the gerber character by charcter
    @charIndex = 0
    @end = @gerberFile.length

  # get the next block in the sequence
  # return it as an object as either { block: 'string' } or
  # { param: [ 'string1', 'string2', ... , 'stringN' ] }
  nextBlock: ->
    # check for file end
    return false if @index >= @end
    # current block
    current = ''
    # parameter flag / array
    parameter = false
    # if line index is 0, update because we're now officially in the first line
    if @line is 0 then @line++
    # loop the file ends
    until @charIndex >= @end
      char = @gerberFile[@charIndex++]
      # check for parameter start
      if char is '%'
        if not parameter then parameter = [] else return { param: parameter }
      # check for block end
      else if char is '*'
        if parameter then parameter.push current; current = ''
        else return { block: current }
      # check for new (or that we're in the first line)
      else if char is '\n' then @line++
      # check for valid file character
      else if ' ' <= char <= '~' then current += char
    # if we get here, the file has ended
    return false

  getLine: ->
    @line

module.exports = GerberReader
