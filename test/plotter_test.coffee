# test suite for plotter class
Plotter = require '../src/plotter'
# stream hook for testing for warnings
streamCapture = require './stream-capture'
stderr = -> streamCapture(process.stderr)

describe 'Plotter class', ->
  p = null
  beforeEach -> p = new Plotter

  describe 'setting internal plotter state', ->
    describe 'units', ->
      it 'should set the units to mm and in', ->
        p.command { set: { units: 'mm' } }
        p.units.should.eql 'mm'
        p = new Plotter
        p.command { set: { units: 'in' } }
        p.units.should.eql 'in'
      it 'should throw if the units try to get redefined', ->
        p.command { set: { units: 'mm' } }
        (-> p.command { set: { units: 'in' } }).should.throw /redefine units/
      it 'should set the backup units', ->
        p.command { set: { backupUnits: 'mm' } }
        p.backupUnits.should.eql 'mm'
      it 'should set the backup units', ->
        p.command { set: { backupUnits: 'in' } }
        p.backupUnits.should.eql 'in'
    describe 'notation', ->
      it 'should set the notation mode', ->
        p.command { set: { notation: 'A' } }
        p.notation.should.eql 'A'
        p = new Plotter
        p.command { set: { notation: 'I' } }
        p.notation.should.eql 'I'
      it 'should throw an error if the notation tries to get redefined', ->
        p.command { set: { notation: 'A' } }
        (-> p.command { set: { notation: 'I' } }).should.throw /redefine/
    describe 'changing the tool', ->
      it 'should change to tool to an existing tool', ->
        p.tools.D10 = {}
        p.command { set: { currentTool: 'D10' } }
        p.currentTool.should.eql 'D10'
      it 'should throw if the tool doesnt exist', ->
        (-> p.command { set: { currentTool: 'D10' } }).should.throw /tool/
      it 'should throw if region mode is on', ->
        p.region = true
        p.tools.D10 = {}
        (-> p.command { set: { currentTool: 'D10' } }).should.throw /tool/
    it 'should the interpolation mode', ->
      p.command { set: { mode: 'i' } }
      p.mode.should.eql 'i'
      p.command { set: { mode: 'cw' } }
      p.mode.should.eql 'cw'
      p.command { set: { mode: 'ccw' } }
      p.mode.should.eql 'ccw'
    it 'should set the arc quadrant mode', ->
      p.command { set: { quad: 's' } }
      p.quad.should.eql 's'
      p.command { set: { quad: 'm' } }
      p.quad.should.eql 'm'
    it 'should set the region mode', ->
      p.command { set: { region: true } }
      p.region.should.eql true
      p.command { set: { region: false } }
      p.region.should.eql false
    it 'should set the file end flag', ->
      p.command { set: { done: true } }
      p.done.should.be.true

  describe 'defining new tools', ->
    it 'should add a standard tool to the tools object', ->
      p.command { tool: { D10: { dia: 10 } } }
      p.tools.D10.trace.should.containEql {
        fill: 'none'
        'stroke-width': 10
      }
      p.tools.D10.pad.should.containDeep [ { circle: { r: 5 } } ]
      p.tools.D10.flash(1.0, 3.6).should.containDeep { use: {x: 1, y: 3.6 } }
      p.tools.D10.bbox(1.0, 3.6).should.eql {
        xMin: -4, yMin: -1.4, xMax: 6, yMax: 8.6
      }
    describe 'tool macros', ->
      beforeEach -> p.command { macro: [ 'AMRECT1', '21,1,$1,$2,0,0,0' ] }
      it 'should add the macro to the macros list', ->
        p.macros.RECT1.name.should.eql 'RECT1'
      it 'should add macro tools to the tools object', ->
        p.command { tool: { D10: { macro: 'RECT1', mods: [ 2, 1 ] } } }
        p.tools.D10.pad.should.containDeep [ { rect: { width: 2, height: 1 } }  ]

  describe 'operating', ->
    beforeEach ->
      p.units = 'in'
      p.notation = 'A'
      p.mode = 'i'
      p.command { tool: { D11: { width: 2, height: 1 } } }
      p.command { tool: { D10: { dia: 2 } } }

    describe 'making sure format is set', ->
      it 'should use the backup units if units were not set', ->
        p.units = null
        p.backupUnits = 'in'
        hook = stderr()
        p.command { op: { do: 'int', x: 1, y: 1 } }
        hook.captured().should.match /units .* deprecated/
        hook.unhook()
        p.units.should.eql 'in'

      it 'should throw if units and backup units are not set', ->
        p.units = null
        (-> p.command { op: { do: 'int', x: 1, y: 1 } })
          .should.throw /units/

      it 'should throw if notation is not set', ->
        p.notation = null
        (-> p.command { op: { do: 'int', x: 1, y: 1 } })
          .should.throw /format/

    it 'should move the plotter position with absolute notation', ->
      p.command { op: { do: 'int', x: 1, y: 2 } }
      p.pos.should.eql { x: 1, y: 2 }
      p.command { op: { do: 'move', x: 3, y: 4 } }
      p.pos.should.eql { x: 3, y: 4 }
      p.command { op: { do: 'flash', x: 5, y: 6 } }
      p.pos.should.eql { x: 5, y: 6 }
      p.command { op: { do: 'flash', y: 7 } }
      p.pos.should.eql { x: 5, y: 7 }
      p.command { op: { do: 'flash', x: 8 } }
      p.pos.should.eql { x: 8, y: 7 }
      p.command { op: { do: 'flash' } }
      p.pos.should.eql { x: 8, y: 7 }
    it 'should move the plotter with incremental notation', ->
      p.notation = 'I'
      p.command { op: { do: 'int', x: 1, y: 2 } }
      p.pos.should.eql { x: 1, y: 2 }
      p.command { op: { do: 'move', x: 3, y: 4 } }
      p.pos.should.eql { x: 4, y: 6 }
      p.command { op: { do: 'flash', x: 5, y: 6 } }
      p.pos.should.eql { x: 9, y: 12 }
      p.command { op: { do: 'flash', y: 7 } }
      p.pos.should.eql { x: 9, y: 19 }
      p.command { op: { do: 'flash', x: 8 } }
      p.pos.should.eql { x: 17, y: 19 }
      p.command { op: { do: 'flash' } }
      p.pos.should.eql { x: 17, y: 19 }
    describe 'flashing pads', ->
      it 'should add a pad with a flash', ->
        p.command { set: { currentTool: 'D10' } }
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        p.defs.should.containDeep [ { circle: { r: 1 } } ]
        p.current.should.containDeep [ { use: { x: 2, y: 2 } } ]
      it 'should add pads to the bbox', ->
        p.command { set: { currentTool: 'D10' } }
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        p.bbox.should.eql { xMin: 1, yMin: 1, xMax: 3, yMax: 3 }
        p.command { op: { do: 'flash', x: -2, y: -2 } }
        p.bbox.should.eql { xMin: -3, yMin: -3, xMax: 3, yMax: 3 }
        p.command { op: { do: 'flash', x: 3, y: 3 } }
        p.bbox.should.eql { xMin: -3, yMin: -3, xMax: 4, yMax: 4 }
      it 'should throw an error if in region mode', ->
        p.region = true
        (-> p.command { op: { do: 'flash', x: 2, y: 2 } }).should.throw /region/
    describe 'paths', ->
      it 'should start a new path with an interpolate', ->
        p.command { op: { do: 'int', x: 5, y: 5 } }
        p.path.should.eql [ 'M', 0, 0, 'L', 5, 5 ]
        p.bbox.should.eql { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }
      it 'should throw an error for unstrokable tool outside region mode', ->
        p.command { tool: { D13: { dia: 5, verticies: 5 } } }
        (-> p.command { op: { do: 'int' } }).should.throw /strokable tool/
      it 'should assume linear interpolation if none was specified', ->
        p.mode = null
        hook = stderr()
        p.command { op: { do: 'int', x: 5, y: 5 } }
        hook.captured().should.match /assuming linear/i
        hook.unhook()
        p.mode.should.eql 'i'
      describe 'adding to a linear path', ->
        beforeEach ->
          p.path = [ 'M', 0, 0, 'L', 5, 5 ]
          p.bbox = { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }
        it 'should add a lineto with an int', ->
          p.command { op: { do: 'int', x: 10, y: 10 } }
          p.path.should.eql [ 'M', 0, 0, 'L', 5, 5, 'L', 10, 10 ]
          { xMin: -1, yMin: -1, xMax: 11, yMax: 11 }
        it 'should add a moveto with a move', ->
          p.command { op: { do: 'move', x: 10, y: 10 } }
          p.path.should.eql [ 'M', 0, 0, 'L', 5, 5, 'M', 10, 10 ]
          p.bbox.should.eql { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }
      describe 'ending the path', ->
        beforeEach -> p.path = [ 'M', 0, 0, 'L', 5, 5 ]
        it 'should end the path on a flash', ->
          p.command { op: { do: 'flash', x: 2, y: 2 } }
          p.path.should.eql []
          p.current.should.containDeep [{ path: { d: ['M', 0, 0, 'L', 5, 5] } }]
        it 'should end the path on a tool change', ->
          p.command { set: { currentTool: 'D10' } }
          p.path.should.eql []
          p.current.should.containDeep [{ path: { d: ['M', 0, 0, 'L', 5, 5] } }]
        it 'should end the path on a polarity change', ->
          p.command { new: { layer: 'C' } }
          p.path.should.eql []
          p.current.should.containDeep [{ path: { d: ['M', 0, 0, 'L', 5, 5] } }]
        it 'should end the path on a step repeat', ->
          p.command { new: { sr: { x: 2, y: 2, i: 1, j: 2 } } }
          p.path.should.eql []
          p.current.should.containDeep [{ path: { d: ['M', 0, 0, 'L', 5, 5] } }]
        it 'should end the path on file end', ->
          p.finish()
          p.path.should.eql []
          p.current.should.containDeep [{ path: { d: ['M', 0, 0, 'L', 5, 5] } }]

      #describe 'adding an arc to the path', ->

      describe 'region mode', ->
        it 'should allow any tool to create a region', ->
          p.command { tool: { D13: { dia: 5, verticies: 5 } } }
          p.command { set: { region: true } }
          (-> p.command { op: { do: 'int', x: 5, y: 5 } }).should.not.throw()
        it 'should not take the tool into account when calculating the bbox', ->
          p.command { set: { region: true } }
          p.command { op: { do: 'int', x: 5, y: 5 } }
          p.bbox.should.eql { xMin: 0, yMin: 0, xMax: 5, yMax: 5 }
        it 'should add a path element to the current layer', ->
          p.command { set: { region: true } }
          p.command { op: { do: 'int', x: 5, y: 5 } }
          p.command { op: { do: 'int', x: 0, y: 5 } }
          p.command { op: { do: 'int', x: 0, y: 0 } }
          p.finishPath()
          p.current.should.containEql {
            path: { d: ['M', 0, 0, 'L', 5, 5, 'L', 0, 5, 'L', 0, 0, 'Z' ] }
          }
