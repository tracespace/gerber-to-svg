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

      describe 'stroking a rectangular tool', ->
        beforeEach -> p.command { set: { currentTool: 'D11' } }
        # these are fun because they just drag the rectange without rotation
        # let's test each of the quadrants
        # width of tool is 2, height is 1
        it 'should handle a first quadrant move', ->
          p.command { op: { do: 'int', x: 5, y: 5 } }
          p.path.should.containDeep [
            'M', -1, -0.5, 1, -0.5, 6, 4.5, 6, 5.5, 4, 5.5, -1, 0.5, 'Z'
          ]
        it 'should handle a second quadrant move', ->
          p.command { op: { do: 'int', x: -5, y: 5 } }
          p.path.should.containDeep [
            'M', -1, -0.5, 1, -0.5, 1, 0.5, -4, 5.5, -6, 5.5, -6, 4.5, 'Z'
          ]
        it 'should handle a third quadrant move', ->
          p.command { op: { do: 'int', x: -5, y: -5 } }
          p.path.should.containDeep [
            'M', 1, 0.5, -1, 0.5, -6, -4.5, -6, -5.5, -4, -5.5, 1, -0.5, 'Z'
          ]
        it 'should handle a fourth quadrant move', ->
          p.command { op: { do: 'int', x: 5, y: -5 } }
          p.path.should.containDeep [
            'M', 1, 0.5, -1, 0.5, -1, -0.5, 4, -5.5, 6, -5.5, 6, -4.5, 'Z'
          ]
        it "should not have a stroke-width (it's filled instead)", ->
          p.command { op: { do: 'int', x: 5, y: 5 } }
          p.finishPath()
          p.current[0].should.have.key 'path'
          p.current[0].path.should.not.have.key 'stroke-width'


      describe 'adding an arc to the path', ->
        it 'should throw an error if the tool is not circular', ->
          p.command { set: { currentTool: 'D11', mode: 'cw', quad: 's' } }
          (-> p.command { op: { do: 'int', x: 1, y: 1, i: 1 } })
            .should.throw /arc with non-circular/
        it 'should not throw if non-circular tool in region mode', ->
          p.command { set:
            { currentTool: 'D11', mode: 'cw', region: true, quad: 's' }
          }
          (-> p.command { op: { do: 'int', x: 1, y: 1, i: 1 } })
            .should.not.throw()
        it 'should throw an error if quadrant mode has not been specified', ->
          (-> p.command { set: {mode: 'cw'}, op: {do: 'int', x: 1, y: 1, i: 1}})
            .should.throw /quadrant mode/
        describe 'single quadrant arc mode', ->
          beforeEach () -> p.command { set: { quad: 's' } }
          it 'should add a CW arc with a set to cw', ->
            p.command { set: { mode: 'cw'}, op: {do: 'int', x: 1, y: 1, i: 1} }
            p.path.should.containDeep [ 'A', 1, 1, 0, 0, 0, 1, 1 ]
          it 'should add a CCW arc with a G03', ->
            p.command { set: { mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, j: 1} }
            p.path.should.containDeep [ 'A', 1, 1, 0, 0, 1, 1, 1 ]
          it 'should warn for impossible arcs and add nothing to the path', ->
            hook = stderr()
            p.command { set: { mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, i: 1} }
            hook.captured().should.match /impossible arc/
            hook.unhook()
            p.path.should.not.containEql 'A'

        describe 'multi quadrant arc mode', ->
          beforeEach () -> p.command { set: { quad: 'm' } }
          it 'should add a CW arc with a G02', ->
            p.command { set: { mode: 'cw'}, op: {do: 'int', x: 1, y: 1, j: 1} }
            p.path.should.containDeep [ 'A', 1, 1, 0, 1, 0, 1, 1 ]
          it 'should add a CCW arc with a G03', ->
            p.command { set: { mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, i: 1} }
            p.path.should.containDeep [ 'A', 1, 1, 0, 1, 1, 1, 1 ]
          it 'should add 2 paths for full circle if start is end', ->
            p.command { set: { mode: 'cw'}, op: { do: 'int', i: 1 } }
            p.path.should.containDeep [
              'A', 1, 1, 0, 0, 0, 2, 0, 'A', 1, 1, 0, 0, 0, 0, 0
            ]
          it 'should warn for impossible arc and add nothing to the path', ->
            hook = stderr()
            p.command { set: { mode: 'cw' }, op: {do: 'int', x: 1, y: 1, j:-1 }}
            hook.captured().should.match /impossible arc/
            hook.unhook()
            p.path.should.not.containEql 'A'

        # tool is a dia 2 circle for these tests
        describe 'adjusting the bbox', ->
          it 'sweeping past 180 deg determines min X', ->
            p.command { op: { do: 'move', x: -0.7071, y: -0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: -0.7071, y: 0.7071, i: 0.7071, j: 0.7071 }
            }
            result = Math.abs -2-p.bbox.xMin
            result.should.be.lessThan 0.00001
          it 'sweeping past 270 deg determines min Y', ->
            p.command { op: { do: 'move', x: 0.7071, y: -0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: -0.7071, y: -0.7071, i: 0.7071, j: 0.7071 }
            }
            result = Math.abs -2-p.bbox.yMin
            result.should.be.lessThan 0.00001
          it 'sweeping past 90 deg determines max Y', ->
            p.command { op: { do: 'move', x: -0.7071, y: 0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.7071, y: 0.7071, i: 0.7071, j: 0.7071 }
            }
            result = Math.abs 2-p.bbox.yMax
            result.should.be.lessThan 0.00001
          it 'sweeping past 0 deg determines max X', ->
            p.command { op: { do: 'move', x: 0.7071, y: 0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.7071, y: -0.7071, i: 0.7071, j: 0.7071 }
            }
            result = Math.abs 2-p.bbox.xMax
            result.should.be.lessThan 0.00001
          it 'if its just hanging out, use the end points', ->
            p.command { op: { do: 'move', x: 0.5, y: 0.866 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.866, y: 0.5, i: 0.5, j: 0.866 }
            }
            p.bbox.xMin.should.equal -0.5
            p.bbox.yMin.should.equal -0.5
            p.bbox.xMax.should.equal 1.8660
            p.bbox.yMax.should.equal 1.8660

      describe 'region mode off', ->
        it 'should add the trace properties to the path when it ends', ->
          p.path = ['M', 0, 0, 'L', 5, 5 ]
          p.finishPath()
          p.current.should.containDeep [{
            path: { d: ['M', 0, 0, 'L', 5, 5], fill: 'none', 'stroke-width': 2 }
          }]
      describe 'region mode on', ->
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
