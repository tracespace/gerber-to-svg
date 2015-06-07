# test suite for plotter class
expect = require('chai').expect
Plotter = require '../src/plotter'
DrillParser = require '../src/drill-parser'
# stream hook for testing for warnings
warnings = require './warn-capture'

describe 'Plotter class', ->
  p = null
  beforeEach ->
    p = new Plotter()

  describe 'setting internal plotter state', ->

    describe 'units', ->
      it 'should set the units to mm and in', ->
        p.write {set: {units: 'mm'}}
        expect(p.units).to.eql 'mm'

        p = new Plotter()
        p.write {set: {units: 'in'}}
        expect(p.units).to.eql 'in'

      it 'should not redefine the units', ->
        p.write {set: {units: 'mm'}}
        p.write {set: {units: 'in'}}
        expect(p.units).to.eql 'mm'

      it 'should should allow the user to overide the units', ->
        p = new Plotter {units: 'mm'}
        expect(p.units).to.eql 'mm'
        p.write {set: {units: 'in'}}
        expect(p.units).to.eql 'mm'
        p = new Plotter {units: 'in'}
        expect(p.units).to.eql 'in'
        p.write {set: {units: 'mm'}}
        expect(p.units).to.eql 'in'

      it 'should set the backup units', ->
        p.write {set: {backupUnits: 'mm'}}
        expect(p.backupUnits).to.eql 'mm'
        p = new Plotter()
        p.write {set: {backupUnits: 'in'}}
        expect(p.backupUnits).to.eql 'in'

      it 'should not redefine the backupUnits', ->
        p.write {set: {backupUnits: 'in'}}
        p.write {set: {backupUnits: 'mm'}}
        expect(p.backupUnits).to.eql 'in'

    describe 'notation', ->

      it 'should set the notation mode', ->
        p.write {set: {notation: 'A'}}
        expect(p.notation).to.eql 'A'
        p = new Plotter()
        p.write {set: {notation: 'I'}}
        expect(p.notation).to.eql 'I'

      it 'should allow the user to override the notation', ->
        p = new Plotter {notation: 'A'}
        expect(p.notation).to.eql 'A'
        p.write {set: {notation: 'I'}}
        expect(p.notation).to.eql 'A'
        p = new Plotter {notation: 'I'}
        expect(p.notation).to.eql 'I'
        p.write {set: {notation: 'A'}}
        expect(p.notation).to.eql 'I'

      it 'should not redefine the notation', ->
        p.write {set: {notation: 'A'}}
        p.write {set: {notation: 'I'}}
        expect(p.notation).to.eql 'A'

    describe 'changing the tool', ->

      it 'should change to tool to an existing tool', ->
        p.tools.D10 = {}
        p.write {set: {currentTool: 'D10'}}
        expect(p.currentTool).to.equal p.tools.D10

      it 'should error if the tool doesnt exist', (done) ->
        p.once 'warning', (w) ->
          expect(w.message).to.match /tool D10/
          expect(w.line).to.equal 4
          done()

        p.write {set: {currentTool: 'D10'}, line: 4}

      it 'should error if region mode is on', (done) ->
        p.once 'error', (e) ->
          expect(e.message).to.match /line 3 .*tool.*region/
          done()

        p.region = true
        p.tools.D10 = {}
        p.write {set: {currentTool: 'D10'}, line: 3}

    it 'should set the interpolation mode', ->
      p.write {set: {mode: 'i'}}
      expect(p.mode).to.eql 'i'
      p.write {set: {mode: 'cw'}}
      expect(p.mode).to.eql 'cw'
      p.write {set: {mode: 'ccw'}}
      expect(p.mode).to.eql 'ccw'

    it 'should set the arc quadrant mode', ->
      p.write {set: {quad: 's'}}
      expect(p.quad).to.eql 's'
      p.write {set: {quad: 'm'}}
      expect(p.quad).to.eql 'm'

    it 'should set the region mode', ->
      p.write {set: {region: true}}
      expect(p.region).to.eql true
      p.write {set: {region: false}}
      expect(p.region).to.eql false

    it 'should set the file end flag', ->
      p.write {set: {done: true}}
      expect(p.done).to.be.true

  it 'should handle empty objects in the stream without complaint', (done) ->
    p.on 'error', -> throw new Error 'complained'
    p.on 'warning', -> throw new Error 'complained'

    p.write {set: {units: 'in'}}
    p.write {}
    p.write {set: backupUnits: 'in'}
    expect(p.units).to.eql 'in'
    expect(p.backupUnits).to.eql 'in'

    setTimeout done, 10

  describe 'new layer commands', ->

    it.skip 'should finish any in progress layer', ->
      p.current = ['stuff']
      p.write {new: {sr: {x: 2, y: 3, i: 7, j: 2}}}
      expect(p.current).to.be.empty
      p.current = ['more', 'stuff']
      p.write {new: {layer: 'C'}}
      expect(p.current).to.be.empty

    it 'should set step repeat params', ->
      expect(p.stepRepeat).to.eql {x: 1, y: 1, i: 0, j: 0}
      p.write {new: {sr: {x: 2, y: 3, i: 7, j: 2}}}
      expect(p.stepRepeat).to.eql {x: 2, y: 3, i: 7, j: 2}
      p.write {new: {sr: {x: 1, y: 1}}}
      expect(p.stepRepeat).to.eql {x: 1, y: 1}

    it 'should set polarity param', ->
      p.write {new: {layer: 'C'}}
      expect(p.polarity).to.eql 'C'
      p.write {new: {layer: 'D'}}
      expect(p.polarity).to.eql 'D'

    it 'should throw if it gets an bad new command', ->
      expect(-> p.write {new: {foo: 'bar'}}).to.throw /unknown new command/

  describe 'defining new tools', ->

    it 'should add a standard tool to the tools object', ->
      p.write {tool: {D10: {dia: 10}}}
      expect(p.tools.D10.trace).to.contain {
        fill: 'none'
        'stroke-width': 10
      }
      expect(p.tools.D10.pad).to.have.length 1
      expect(p.tools.D10.pad[0].circle.r).to.eql 5
      flash = p.tools.D10.flash(1.0, 3.6)
      expect(flash.use.x).to.eql 1
      expect(flash.use.y).to.eql 3.6
      expect(flash.use['xlink:href']).to.match /D10/
      expect(p.tools.D10.bbox(1.0, 3.6)).to.eql {
        xMin: -4, yMin: -1.4, xMax: 6, yMax: 8.6
      }

    it 'should set the current tool to the new tool', ->
      p.write {tool: {D10: {dia: 10}}}
      expect(p.currentTool).to.equal p.tools.D10

    it 'should error if the tool already exists', (done) ->
      p.once 'error', (e) ->
        expect(e.message).to.match /line 8 .*D10.*previously defined/
        done()

      p.write {tool: {D10: {dia: 10}}, line: 7}
      p.write {tool: {D10: {dia: 8}}, line: 8}

    describe 'tool macros', ->

      beforeEach ->
        p.parser = {format: {places: [2, 4]}}
        p.write {macro: {RECT1: ['21,1,$1,$2,0,0,0']}}

      it 'should add the macro to the macros list', ->
        expect(p.macros.RECT1).to.exist

      it.skip 'should add macro tools to the tools object', ->
        p.write {tool: {D10: {macro: 'RECT1', mods: [2, 1]}}}
        expect(p.tools.D10.pad[0]).to.have.key 'rect'

  describe.skip 'operating', ->

    beforeEach ->
      p.units = 'in'
      p.notation = 'A'
      p.mode = 'i'
      p.write {tool: {D11: {width: 2, height: 1}}}
      p.write {tool: {D10: {dia: 2}}}

    describe.skip 'making sure format is set', ->

      it.skip 'should use the backup units if units were not set', ->
        p.units = null
        p.backupUnits = 'in'
        warnings.hook()
        p.write {op: {do: 'int', x: 1, y: 1}}
        expect(warnings.unhook()).to.match /units .* deprecated/
        expect(p.units).to.eql 'in'

      it.skip 'should assume inches if units and backup units are not set', ->
        p.units = null
        warnings.hook()
        p.write {op: {do: 'int', x: 1, y: 1}}
        expect(warnings.unhook()).to.match /no units/
        expect(p.units).to.eql 'in'

      it.skip 'should throw if notation is not set', ->
        p.notation = null
        expect(-> p.write {op: {do: 'int', x: 1, y: 1}})
          .to.throw /format/

      it.skip 'should assume notation is absolute if unset in a drill file', ->
        p = new Plotter null, new DrillParser()
        p.units = 'in'
        p.write {tool: {T1: {dia: 1}}}
        expect(-> p.write {op:{do: 'flash', x: 1, y: 1}}).to.not.throw()
        expect(p.notation).to.eql 'A'

    it.skip 'should move the plotter position with absolute notation', ->
      p.write {op: {do: 'int', x: 1, y: 2}}
      expect(p.pos).to.eql {x: 1, y: 2}
      p.write {op: {do: 'move', x: 3, y: 4}}
      expect(p.pos).to.eql {x: 3, y: 4}
      p.write {op: {do: 'flash', x: 5, y: 6}}
      expect(p.pos).to.eql {x: 5, y: 6}
      p.write {op: {do: 'flash', y: 7}}
      expect(p.pos).to.eql {x: 5, y: 7}
      p.write {op: {do: 'flash', x: 8}}
      expect(p.pos).to.eql {x: 8, y: 7}
      p.write {op: {do: 'flash'}}
      expect(p.pos).to.eql {x: 8, y: 7}

    it.skip 'should move the plotter with incremental notation', ->
      p.notation = 'I'
      p.write {op: {do: 'int', x: 1, y: 2}}
      expect(p.pos).to.eql {x: 1, y: 2}
      p.write {op: {do: 'move', x: 3, y: 4}}
      expect(p.pos).to.eql {x: 4, y: 6}
      p.write {op: {do: 'flash', x: 5, y: 6}}
      expect(p.pos).to.eql {x: 9, y: 12}
      p.write {op: {do: 'flash', y: 7}}
      expect(p.pos).to.eql {x: 9, y: 19}
      p.write {op: {do: 'flash', x: 8}}
      expect(p.pos).to.eql {x: 17, y: 19}
      p.write {op: {do: 'flash'}}
      expect(p.pos).to.eql {x: 17, y: 19}

    describe.skip 'flashing pads', ->

      it.skip 'should add a pad with a flash', ->
        p.write {set: {currentTool: 'D10'}}
        expect(p.tools.D10.flashed).to.be.false
        p.write {op: {do: 'flash', x: 2, y: 2}}
        expect(p.tools.D10.flashed).to.be.true
        expect(p.defs[0].circle).to.contain {r: 1}
        expect(p.current[0].use).to.contain {x: 2, y: 2}

      it.skip 'should only add a pad to defs once', ->
        p.write {set: {currentTool: 'D10'}}
        p.write {op: {do: 'flash', x: 2, y: 2}}
        p.write {op: {do: 'flash', x: 2, y: 2}}
        expect(p.tools.D10.pad).to.not.be.false
        expect(p.defs).to.have.length 1

      it.skip 'should add pads to the layer bbox', ->
        p.write {set: {currentTool: 'D11'}}
        p.write {op: {do: 'flash', x: 2, y: 2}}
        expect(p.layerBbox).to.eql {xMin: 1, yMin: 1.5, xMax: 3, yMax: 2.5}
        p.write {set: {currentTool: 'D10'}}
        p.write {op: {do: 'flash', x: 2, y: 2}}
        expect(p.layerBbox).to.eql {xMin: 1, yMin: 1, xMax: 3, yMax: 3}
        p.write {op: {do: 'flash', x: -2, y: -2}}
        expect(p.layerBbox).to.eql {xMin: -3, yMin: -3, xMax: 3, yMax: 3}
        p.write {op: {do: 'flash', x: 3, y: 3}}
        expect(p.layerBbox).to.eql {xMin: -3, yMin: -3, xMax: 4, yMax: 4}

      it.skip 'should throw an error if in region mode', ->
        p.region = true
        expect(-> p.write {op: {do: 'flash', x: 2, y: 2}})
          .to.throw /region/

    describe.skip 'paths', ->

      it.skip 'should start a new path with an interpolate', ->
        p.write {op: {do: 'int', x: 5, y: 5}}
        expect(p.path).to.eql ['M', 0, 0, 'L', 5, 5]
        expect(p.layerBbox).to.eql {xMin: -1, yMin: -1, xMax: 6, yMax: 6}

      it.skip 'should error for unstrokable tool outside region mode', ->
        p.write {tool: {D13: {dia: 5, vertices: 5}}}
        expect(-> p.write {op: {do: 'int'}}).to.throw /strokable tool/

      it.skip 'should assume linear interpolation if none was specified', ->
        p.mode = null
        warnings.hook()
        p.write {op: {do: 'int', x: 5, y: 5}}
        expect(warnings.unhook()).to.match /assuming linear/i
        expect(p.mode).to.eql 'i'

      describe.skip 'adding to a linear path', ->

        beforeEach ->
          p.path = ['M', 0, 0, 'L', 5, 5]
          p.layerBbox = {xMin: -1, yMin: -1, xMax: 6, yMax: 6}

        it.skip 'should add a lineto with an int', ->
          p.write {op: {do: 'int', x: 10, y: 10}}
          expect(p.path).to.eql ['M', 0, 0, 'L', 5, 5, 'L', 10, 10]
          expect(p.layerBbox).to.eql {xMin: -1, yMin: -1, xMax: 11, yMax: 11}

        it.skip 'should add a moveto with a move', ->
          p.write {op: {do: 'move', x: 10, y: 10}}
          expect(p.path).to.eql ['M', 0, 0, 'L', 5, 5, 'M', 10, 10]
          expect(p.layerBbox).to.eql {xMin: -1, yMin: -1, xMax: 6, yMax: 6}

      describe.skip 'ending the path', ->

        beforeEach -> p.path = ['M', 0, 0, 'L', 5, 5]

        it.skip 'should end the path on a flash', ->
          p.write {op: {do: 'flash', x: 2, y: 2}}
          expect(p.path).to.be.empty

        it.skip 'should end the path on a tool change', ->
          p.write {set: {currentTool: 'D10'}}
          expect(p.path).to.be.empty

        it.skip 'should end the path on a region change', ->
          p.write {set: {region: true}}
          expect(p.path).to.be.empty

        it.skip 'should end the path on a polarity change', ->
          p.write {new: {layer: 'C'}}
          expect(p.path).to.be.empty

        it.skip 'should end the path on a step repeat', ->
          p.write {new: {sr: {x: 2, y: 2, i: 1, j: 2}}}
          expect(p.path).to.be.empty

      describe.skip 'stroking a rectangular tool', ->

        beforeEach -> p.write {set: {currentTool: 'D11'}}

        # these are fun because they just drag the rectange without rotation
        # let's test each of the quadrants
        # width of tool is 2, height is 1
        it.skip 'should handle a first quadrant move', ->
          p.write {op: {do: 'int', x: 5, y: 5}}
          expect(p.path).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 6, 4.5, 6, 5.5, 4, 5.5, -1, 0.5, 'Z'
         ]

        it.skip 'should handle a second quadrant move', ->
          p.write {op: {do: 'int', x: -5, y: 5}}
          expect(p.path).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 1, 0.5, -4, 5.5, -6, 5.5, -6, 4.5, 'Z'
         ]

        it.skip 'should handle a third quadrant move', ->
          p.write {op: {do: 'int', x: -5, y: -5}}
          expect(p.path).to.eql [
            'M', 0, 0
            'M', 1, -0.5, 1, 0.5, -1, 0.5, -6, -4.5, -6, -5.5, -4, -5.5, 'Z'
         ]

        it.skip 'should handle a fourth quadrant move', ->
          p.write {op: {do: 'int', x: 5, y: -5}}
          expect(p.path).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 4, -5.5, 6, -5.5, 6, -4.5, 1, 0.5, -1, 0.5, 'Z'
         ]

        it.skip 'should handle a move along the positive x-axis', ->
          p.write {op: {do: 'int', x: 5, y: 0}}
          expect(p.path).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 6, -0.5, 6, 0.5, 4, 0.5, -1, 0.5, 'Z'
         ]

        it.skip 'should handle a move along the negative x-axis', ->
          p.write {op: {do: 'int', x: -5, y: 0}}
          expect(p.path).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 1, 0.5, -4, 0.5, -6, 0.5, -6, -0.5, 'Z'
         ]

        it.skip 'should handle a move along the positive y-axis', ->
          p.write {op: {do: 'int', x: 0, y: 5}}
          expect(p.path).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 1, 0.5, 1, 5.5, -1, 5.5, -1, 4.5, 'Z'
         ]

        it.skip 'should handle a move along the negative y-axis', ->
          p.write {op: {do: 'int', x: 0, y: -5}}
          expect(p.path).to.eql [
            'M', 0, 0
            'M', -1, -0.5, -1, -5.5, 1, -5.5, 1, -4.5, 1, 0.5, -1, 0.5, 'Z'
         ]

        it "should not have a stroke-width (it's filled instead)", ->
          p.write {op: {do: 'int', x: 5, y: 5}}
          p.finishPath()
          expect(p.current[0]).to.have.key 'path'
          expect(p.current[0].path).to.not.have.key 'stroke-width'

      describe.skip 'adding an arc to the path', ->

        it.skip 'should throw an error if the tool is not circular', ->
          p.write {set: {currentTool: 'D11', mode: 'cw', quad: 's'}}
          expect(-> p.write {op: {do: 'int', x: 1, y: 1, i: 1}})
            .to.throw /arc with non-circular/

        it.skip 'should not throw if non-circular tool in region mode', ->
          p.write {set:
            {currentTool: 'D11', mode: 'cw', region: true, quad: 's'}
         }
          expect(-> p.write {op: {do: 'int', x: 1, y: 1, i: 1}})
            .to.not.throw()

        it.skip 'should error if quadrant mode has not been specified', ->
          expect(-> p.write {
            set: {mode: 'cw'}, op: {do: 'int', x: 1, y: 1, i: 1}
         }).to.throw /quadrant mode/

        describe.skip 'single quadrant arc mode', ->

          beforeEach -> p.write {set: {quad: 's'}}

          it.skip 'should add a CW arc with a set to cw', ->
            p.write {set: {mode: 'cw'}, op: {do: 'int', x: 1, y: 1, i: 1}}
            expect(p.path[-8..]).to.eql ['A', 1, 1, 0, 0, 0, 1, 1]

          it.skip 'should add a CCW arc with a G03', ->
            p.write {set: {mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, j: 1}}
            expect(p.path[-8..]).to.eql ['A', 1, 1, 0, 0, 1, 1, 1]

          it.skip 'should close the path on a zero length arc', ->
            p.write {set: {mode: 'ccw'}, op: {do: 'int', x: 0, y: 0, j: 1}}
            expect(p.path[-9..]).to.eql ['A', 1, 1, 0, 0, 1, 0, 0, 'Z']

          it.skip 'should warn for impossible arcs and add nothing to path', ->
            warnings.hook()
            p.write {set: {mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, i: 1}}
            expect(warnings.unhook()).to.match /impossible arc/
            expect(p.path).to.not.contain 'A'

        describe.skip 'multi quadrant arc mode', ->

          beforeEach -> p.write {set: {quad: 'm'}}

          it.skip 'should add a CW arc with a G02', ->
            p.write {set: {mode: 'cw'}, op: {do: 'int', x: 1, y: 1, j: 1}}
            expect(p.path[-8..]).to.eql ['A', 1, 1, 0, 1, 0, 1, 1]

          it.skip 'should add a CCW arc with a G03', ->
            p.write {set: {mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, i: 1}}
            expect(p.path[-8..]).to.eql ['A', 1, 1, 0, 1, 1, 1, 1]

          it.skip 'should add 2 paths for full circle if start is end', ->
            p.write {set: {mode: 'cw'}, op: {do: 'int', i: 1}}
            expect(p.path[-16..]).to.eql [
              'A', 1, 1, 0, 0, 0, 2, 0, 'A', 1, 1, 0, 0, 0, 0, 0
           ]

          it.skip 'should warn for impossible arc and add nothing to path', ->
            warnings.hook()
            p.write {set: {mode: 'cw'}, op: {do: 'int', x: 1, y: 1, j:-1}}
            expect(warnings.unhook()).to.match /impossible arc/
            expect(p.path).to.not.contain 'A'

        # tool is a dia 2 circle for these tests
        describe.skip 'adjusting the layer bbox', ->

          it.skip 'sweeping past 180 deg determines min X', ->
            p.write {op: {do: 'move', x: -0.7071, y: -0.7071}}
            p.write {
              set: {mode: 'cw', quad: 's'}
              op: {do: 'int', x: -0.7071, y: 0.7071, i: 0.7071, j: 0.7071}
           }
            result = -2 - p.layerBbox.xMin
            expect(result).to.be.closeTo 0, 0.00001

          it.skip 'sweeping past 270 deg determines min Y', ->
            p.write {op: {do: 'move', x: 0.7071, y: -0.7071}}
            p.write {
              set: {mode: 'cw', quad: 's'}
              op: {do: 'int', x: -0.7071, y: -0.7071, i: 0.7071, j: 0.7071}
           }
            result = -2 - p.layerBbox.yMin
            expect(result).to.be.closeTo 0, 0.00001

          it.skip 'sweeping past 90 deg determines max Y', ->
            p.write {op: {do: 'move', x: -0.7071, y: 0.7071}}
            p.write {
              set: {mode: 'cw', quad: 's'}
              op: {do: 'int', x: 0.7071, y: 0.7071, i: 0.7071, j: 0.7071}
           }
            result = 2 - p.layerBbox.yMax
            expect(result).to.be.closeTo 0, 0.00001

          it.skip 'sweeping past 0 deg determines max X', ->
            p.write {op: {do: 'move', x: 0.7071, y: 0.7071}}
            p.write {
              set: {mode: 'cw', quad: 's'}
              op: {do: 'int', x: 0.7071, y: -0.7071, i: 0.7071, j: 0.7071}
           }
            result = 2 - p.layerBbox.xMax
            expect(result).to.be.closeTo 0, 0.00001

          it.skip 'if its just hanging out, use the end points', ->
            p.write {op: {do: 'move', x: 0.5, y: 0.866}}
            p.write {
              set: {mode: 'cw', quad: 's'}
              op: {do: 'int', x: 0.866, y: 0.5, i: 0.5, j: 0.866}
           }
            expect(p.layerBbox.xMin).to.equal -0.5
            expect(p.layerBbox.yMin).to.equal -0.5
            expect(p.layerBbox.xMax).to.equal 1.8660
            expect(p.layerBbox.yMax).to.equal 1.8660

      describe.skip 'region mode off', ->

        it.skip 'should add the trace properties to the path when it ends', ->
          p.path = ['M', 0, 0, 'L', 5, 5]
          p.finishPath()
          expect(p.current[0].path.d).to.eql ['M', 0, 0, 'L', 5, 5]
          expect(p.current[0].path.fill).to.eql 'none'
          expect(p.current[0].path['stroke-width']).to.equal 2

      describe.skip 'region mode on', ->

        it.skip 'should allow any tool to create a region', ->
          p.write {tool: {D13: {dia: 5, vertices: 5}}}
          p.write {set: {region: true}}
          expect(-> p.write {op:{do: 'int', x: 5, y: 5}}).to.not.throw()

        it.skip 'should not take tool into account when calculating bbox', ->
          p.write {set: {region: true}}
          p.write {op: {do: 'int', x: 5, y: 5}}
          expect(p.layerBbox).to.eql {xMin: 0, yMin: 0, xMax: 5, yMax: 5}

        it.skip 'should add a path element to the current layer', ->
          p.write {set: {region: true}}
          p.write {op: {do: 'int', x: 5, y: 5}}
          p.write {op: {do: 'int', x: 0, y: 5}}
          p.write {op: {do: 'int', x: 0, y: 0}}
          p.finishPath()
          expect(p.current[0].path.d).to.eql [
            'M', 0, 0, 'L', 5, 5, 'L', 0, 5, 'L', 0, 0, 'Z'
         ]

    describe.skip 'modal operation codes', ->

      it.skip 'should throw a warning if operation codes are used modally', ->
        warnings.hook()
        p.write {op: {do: 'int', x: 1, y: 1}}
        p.write {op: {do: 'last', x: 2, y: 2}}
        expect(warnings.unhook()).to.match /modal operation/

      it.skip 'should continue a stroke if last operation was a stroke', ->
        p.write {op: {do: 'int', x: 1, y: 1}}
        p.write {op: {do: 'last', x: 2, y: 2}}
        expect(p.path).to.eql ['M', 0, 0, 'L', 1, 1, 'L', 2, 2]

      it.skip 'should move if last operation was a move', ->
        p.write {op: {do: 'move', x: 1, y: 1}}
        p.write {op: {do: 'last', x: 2, y: 2}}
        expect(p.pos).to.eql {x: 2, y: 2}

      it.skip 'should flash if last operation was a flash', ->
        p.write {op: {do: 'flash', x: 1, y: 1}}
        p.write {op: {do: 'last', x: 2, y: 2}}
        expect(p.current).to.have.length 2
        expect(p.current[0].use).to.contain {x: 1, y: 1}
        expect(p.current[1].use).to.contain {x: 2, y: 2}

  describe.skip 'finish layer method', ->

    beforeEach -> p.current = ['item0', 'item1', 'item2']

    it.skip 'should add current items to the group if only one dark layer', ->
      p.finishLayer()
      expect(p.group).to.eql {g: {_: ['item0', 'item1', 'item2']}}
      expect(p.current).to.be.empty

    describe.skip 'multiple layers', ->

      it.skip 'if clear layer, should mask the group with them', ->
        p.polarity = 'C'
        p.bbox = {xMin: 0, yMin: 0, xMax: 2, yMax: 2}
        p.finishLayer()
        mask = p.defs[0].mask
        expect(mask.color).to.eql '#000'
        expect(mask._).to.eql [
          {rect: {x: 0, y: 0, width: 2, height: 2, fill: '#fff'}}
          'item0'
          'item1'
          'item2'
       ]
        id = p.defs[0].mask.id
        expect(p.group).to.eql {g: {mask: "url(##{id})", _: []}}
        expect(p.current).to.be.empty

      it.skip 'if dark layer after clear layer, it should wrap the group', ->
        p.group = {g: {mask: 'url(#mask-id)', _: ['gItem1', 'gItem2']}}
        p.finishLayer()
        expect(p.group).to.eql {
          g: {
            _: [
              {g: {mask: 'url(#mask-id)', _: ['gItem1', 'gItem2']}}
              'item0'
              'item1'
              'item2'
           ]
         }
       }

    describe.skip 'step repeat', ->

      beforeEach ->
        p.layerBbox = {xMin: 0, yMin: 0, xMax: 2, yMax: 2}
        p.stepRepeat = {x: 2, y: 2, i: 3, j: 3}

      describe.skip 'with a dark layer', ->

        it.skip 'should wrap current in a group, copy it, add it to @group', ->
          p.finishLayer()
          id = p.group.g._[0].g.id
          expect(p.group.g._).to.deep.contain.members [
            {g: {id: id, _: ['item0', 'item1', 'item2']}}
            {use: {y: 3, 'xlink:href': "##{id}"}}
            {use: {x: 3, 'xlink:href': "##{id}"}}
            {use: {x:3, y: 3, 'xlink:href': "##{id}"}}
         ]
          expect(p.current).to.be.empty

        it.skip 'leave existing (pre-stepRepeat) items alone', ->
          p.group.g._ = ['existing1', 'existing2']
          p.finishLayer()
          expect(p.group.g._).to.have.length 6
          id = p.group.g._[2].g.id
          expect(p.group.g._).to.deep.contain.members [
            'existing1'
            'existing2'
            {g: {id: id, _: ['item0', 'item1', 'item2']}}
            {use: {y: 3, 'xlink:href': "##{id}"}}
            {use: {x: 3, 'xlink:href': "##{id}"}}
            {use: {x:3, y: 3, 'xlink:href': "##{id}"}}
         ]
          expect(p.current).to.be.empty

      describe.skip 'with a clear layer', ->

        it.skip 'should wrap the current items and repeat them in the mask', ->
          p.polarity = 'C'
          p.finishLayer()
          maskId = p.defs[0].mask.id
          groupId = p.defs[0].mask._[1].g.id
          expect(p.defs[0].mask._).to.deep.contain.members [
            {rect: {x: 0, y: 0, width: 5, height: 5, fill: '#fff'}}
            {g: {id: groupId, _: ['item0', 'item1', 'item2']}}
            {use: {y: 3, 'xlink:href': "##{groupId}"}}
            {use: {x: 3, 'xlink:href': "##{groupId}"}}
            {use: {x:3, y: 3, 'xlink:href': "##{groupId}"}}
         ]
          expect(p.group.g.mask).to.eql "url(##{maskId})"
          expect(p.current).to.be.empty

      describe.skip 'overlapping clear layers', ->

        beforeEach ->
          p.layerBbox = {xMin: 0, yMin: 0, xMax: 4, yMax: 4}
          p.finishLayer()
          p.current = ['item3', 'item4']
          p.layerBbox = {xMin: 0, yMin: 0, xMax: 6, yMax: 6}
          p.polarity = 'C'
          p.finishLayer()

        it.skip 'should push the ids of sr layers to the overlap array', ->
          expect(p.srOverCurrent[0].D).to.match /gerber-sr/
          expect(p.srOverCurrent[0]).to.not.have.key 'C'
          expect(p.srOverCurrent[1].C).to.match /gerber-sr/
          expect(p.srOverCurrent[1]).to.not.have.key 'D'

        it.skip 'should push dark layers to the group normally', ->
          expect(p.group.g._[0]).to.have.key 'g'
          expect(p.group.g._[1]).to.have.key 'use'
          expect(p.group.g._[2]).to.have.key 'use'
          expect(p.group.g._[3]).to.have.key 'use'

        it.skip 'should set the clear overlap flag and not mask immediately', ->
          expect(p.srOverClear).to.be.true

        it.skip 'should create the mask when the sr changes', ->
          id = []
          for layer in p.srOverCurrent
            id.push "##{val}" for key, val of layer
          p.write {new: {sr: {x: 1, y: 1}}}
          expect(p.srOverCurrent.length).to.equal 0
          expect(p.srOverClear).to.be.false
          expect(p.defs[0].g._).to.eql ['item3', 'item4']
          expect(p.defs[1].mask.color).to.eql '#000'
          maskId = p.defs[1].mask.id
          expect(p.group.g.mask).to.eql "url(##{maskId})"
          expect(p.defs[1].mask._).to.eql [
            {rect: {fill: '#fff', x: 0, y: 0, width: 9, height: 9}}
            {use: {fill: '#fff', 'xlink:href': id[0]}}
            {use: {'xlink:href': id[1]}}
            {use: {y: 3, fill: '#fff', 'xlink:href': id[0]}}
            {use: {y: 3, 'xlink:href': id[1]}}
            {use: {x: 3, fill: '#fff', 'xlink:href': id[0]}}
            {use: {x: 3, 'xlink:href': id[1]}}
            {use: {x: 3, y: 3, fill: '#fff', 'xlink:href': id[0]}}
            {use: {x: 3, y: 3, 'xlink:href': id[1]}}
         ]

        it.skip 'should also finish the SR at the end of file', ->
          p.finish()
          expect(p.srOverCurrent.length).to.equal 0
          expect(p.srOverClear).to.be.false

  describe.skip 'overall fill and stroke style', ->

    it.skip 'should default stroke-linecap and stroke-linejoin to round', ->
      expect(p.attr['stroke-linecap']).to.eql 'round'
      expect(p.attr['stroke-linejoin']).to.eql 'round'

    it.skip 'should default stroke-width to 0', ->
      expect(p.attr['stroke-width']).to.eql 0

    it.skip 'should default stroke to black', ->
      expect(p.attr.stroke).to.eql '#000'
