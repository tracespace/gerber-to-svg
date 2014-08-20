# gerber parser class

class GerberParser
  # constructor takes in file string
  constructor: (@file) ->
    # track progress
    @index = 0
    # track line number
    @line = 1

  # get the next commmand
  nextCommand: () ->
    if @index >= @file.length then return false
    blocks = []
    current = ''
    parameter = false
    done = false
    until done or @index is @file.length
      char = @file[@index]
      if char is '%'
        if not parameter then parameter = true else done = true
        if current.length is 0 then blocks.push '%'
        else throw new Error "% after #{current} doesn't make sense"
      else if char is '*'
        blocks.push current
        current = ''
        unless parameter then done = true
      else if ' ' <= char <= '~'
        current += char
      else if char is '\n'
        @line++
      @index++
    blocks

module.exports = GerberParser
