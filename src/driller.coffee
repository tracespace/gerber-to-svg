# until plotter gets refactored, this will be a thin wrapper around the plotter
# to get it to generate drill files

Plotter = require './plotter'
Reader = require './drill-reader'
Parser = require './drill-parser'

class Driller extends Plotter
  constructor: (file= '') ->
    # call Plotter's constructor
    super file
    # overrite parser and add the drill reader
    @reader = new Reader file
    @parser = new Parser

  # rewrite plot
  plot: ->
    # loop until the reader returns false
    while block = @reader.nextBlock()
      c = @parser.parseCommand block
      # take care of any sets first
      if c.set? then this[key] = val for key, val of c.set

      # then tool definitions
      # hack it into recognizing excellon tool definitions
      if c.tool?
        @parameter [ '%', "AD#{c.tool.code}C,#{c.tool.shape.dia}", '%' ]

      # finally check for drill hits
      if c.op? and c.op.do is 'flash'
        if @notation is 'inc'
          @position.x += c.op.x ? 0
          @position.y += c.op.y ? 0
        else
          @position.x = c.op.x if c.op.x?
          @position.y = c.op.y if c.op.y?
        # add the pad to defs if necessary
        if @tools[@currentTool].pad
          @defs.push obj for obj in @tools[@currentTool].pad
          @tools[@currentTool].pad = false
        # add the pad to the layer
        @layer.current[@layer.type]._
          .push @tools[@currentTool].flash @position.x, @position.y
        # update the board's bounding box
        @addBbox @tools[@currentTool].bbox @position.x, @position.y

module.exports = Driller
