# drill file reader class
# data blocks are split by line, so it's pretty straightforward

class DrillReader
  constructor: (drillFile) ->
    @line = 0
    @blocks = drillFile.split /\r?\n/

  nextBlock: ->
    if @line < @blocks.length then @blocks[++@line - 1] else false

# export the module
module.exports = DrillReader
