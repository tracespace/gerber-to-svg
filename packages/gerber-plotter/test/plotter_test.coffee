# test suite for plotter class
expect = require('chai').expect
Plotter = require '../src/plotter'
DrillParser = require '../src/drill-parser'
# stream hook for testing for warnings
warnings = require './warn-capture'

describe 'Plotter class', ->
  p = null
  beforeEach -> p = new Plotter()

  describe 'setting internal plotter state', ->

    describe 'units', ->

      it 'should set the units to mm and in', ->
        p.command { set: { units: 'mm' } }
        expect( p.units ).to.eql 'mm'
        p = new Plotter()
        p.command { set: { units: 'in' } }
        expect( p.units ).to.eql 'in'

      it 'should should allow the user to overide the units', ->
        p = new Plotter(null, null, {units: 'mm'})
        expect(p.units).to.eql 'mm'
        p.command {set: {units: 'in'}}
        expect(p.units).to.eql 'mm'
        p = new Plotter(null, null, {units: 'in'})
        expect(p.units).to.eql 'in'
        p.command {set: {units: 'mm'}}
        expect(p.units).to.eql 'in'

      it 'should set the backup units', ->
        p.command { set: { backupUnits: 'mm' } }
        expect( p.backupUnits ).to.eql 'mm'

      it 'should set the backup units', ->
        p.command { set: { backupUnits: 'in' } }
        expect( p.backupUnits ).to.eql 'in'

    describe 'notation', ->

      it 'should set the notation mode', ->
        p.command { set: { notation: 'A' } }
        expect( p.notation ).to.eql 'A'
        p = new Plotter()
        p.command { set: { notation: 'I' } }
        expect( p.notation ).to.eql 'I'

      it 'should allow the user to override the notation', ->
        p = new Plotter null, null, {notation: 'A'}
        expect(p.notation).to.eql 'A'
        p.command {set: {notation: 'I'}}
        expect(p.notation).to.eql 'A'
        p = new Plotter null, null, {notation: 'I'}
        expect(p.notation).to.eql 'I'
        p.command {set: {notation: 'A'}}
        expect(p.notation).to.eql 'I'

    describe 'changing the tool', ->

      it 'should change to tool to an existing tool', ->
        p.tools.D10 = {}
        p.command { set: { currentTool: 'D10' } }
        expect( p.currentTool ).to.eql 'D10'

      it 'should throw if the tool doesnt exist', ->
        expect( -> p.command { set: { currentTool: 'D10' } } ).to.throw /tool/

      it 'should not throw missing tool exception for drill files', ->
        # drill files sometimes do this, so check for it
        p = new Plotter null, new DrillParser()
        expect( -> p.command { set: { currentTool: 'T0' } } ).to.not.throw()

      it 'should throw if region mode is on', ->
        p.region = true
        p.tools.D10 = {}
        expect( -> p.command { set: { currentTool: 'D10' } } ).to.throw /tool/

    it 'should set the interpolation mode', ->
      p.command { set: { mode: 'i' } }
      expect( p.mode ).to.eql 'i'
      p.command { set: { mode: 'cw' } }
      expect( p.mode ).to.eql 'cw'
      p.command { set: { mode: 'ccw' } }
      expect( p.mode ).to.eql 'ccw'

    it 'should set the arc quadrant mode', ->
      p.command { set: { quad: 's' } }
      expect( p.quad ).to.eql 's'
      p.command { set: { quad: 'm' } }
      expect( p.quad ).to.eql 'm'

    it 'should set the region mode', ->
      p.command { set: { region: true } }
      expect( p.region ).to.eql true
      p.command { set: { region: false } }
      expect( p.region ).to.eql false

    it 'should set the file end flag', ->
      p.command { set: { done: true } }
      expect( p.done ).to.be.true

  describe 'new layer commands', ->

    it 'should finish any in progress layer', ->
      p.current = [ 'stuff' ]
      p.command { new: { sr: { x: 2, y: 3, i: 7, j: 2 } } }
      expect( p.current ).to.be.empty
      p.current = [ 'more', 'stuff' ]
      p.command { new: { layer: 'C' } }
      expect( p.current ).to.be.empty

    it 'should set step repeat params', ->
      p.command { new: { sr: { x: 2, y: 3, i: 7, j: 2 } } }
      expect( p.stepRepeat ).to.eql { x: 2, y: 3, i: 7, j: 2 }
      p.command { new: { sr: { x: 1, y: 1 } } }
      expect( p.stepRepeat ).to.eql { x: 1, y: 1 }

    it 'should set polarity param', ->
      p.command { new: { layer: 'C' } }
      expect( p.polarity ).to.eql 'C'
      p.command { new: { layer: 'D' } }
      expect( p.polarity ).to.eql 'D'

  describe 'defining new tools', ->

    it 'should add a standard tool to the tools object', ->
      p.command { tool: { D10: { dia: 10 } } }
      expect( p.tools.D10.trace ).to.contain {
        fill: 'none'
        'stroke-width': 10
      }
      expect( p.tools.D10.pad ).to.have.length 1
      expect( p.tools.D10.pad[0].circle.r ).to.eql 5
      flash = p.tools.D10.flash(1.0, 3.6)
      expect( flash.use.x ).to.eql 1
      expect( flash.use.y ).to.eql 3.6
      expect( flash.use['xlink:href'] ).to.match /D10/
      expect( p.tools.D10.bbox(1.0, 3.6) ).to.eql {
        xMin: -4, yMin: -1.4, xMax: 6, yMax: 8.6
      }

    describe 'tool macros', ->

      beforeEach ->
        p.parser = { format: { places: [2, 4] } }
        p.command { macro: [ 'AMRECT1', '21,1,$1,$2,0,0,0' ] }

      it 'should add the macro to the macros list', ->
        expect( p.macros.RECT1.name ).to.eql 'RECT1'

      it 'should add macro tools to the tools object', ->
        p.command { tool: { D10: { macro: 'RECT1', mods: [ 2, 1 ] } } }
        expect( p.tools.D10.pad[0] ).to.have.key 'rect'

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
        warnings.hook()
        p.command { op: { do: 'int', x: 1, y: 1 } }
        expect( warnings.unhook() ).to.match /units .* deprecated/
        expect( p.units ).to.eql 'in'

      it 'should assume inches if units and backup units are not set', ->
        p.units = null
        warnings.hook()
        p.command { op: { do: 'int', x: 1, y: 1 } }
        expect( warnings.unhook() ).to.match /no units/
        expect( p.units ).to.eql 'in'

      it 'should throw if notation is not set', ->
        p.notation = null
        expect( -> p.command { op: { do: 'int', x: 1, y: 1 } } )
          .to.throw /format/

      it 'should assume notation is absolute if not set on a drill file', ->
        p = new Plotter null, new DrillParser()
        p.units = 'in'
        p.command { tool: { T1: { dia: 1 } } }
        expect( -> p.command { op:{ do: 'flash', x: 1, y: 1 } } ).to.not.throw()
        expect( p.notation ).to.eql 'A'

    it 'should move the plotter position with absolute notation', ->
      p.command { op: { do: 'int', x: 1, y: 2 } }
      expect( p.pos ).to.eql { x: 1, y: 2 }
      p.command { op: { do: 'move', x: 3, y: 4 } }
      expect( p.pos ).to.eql { x: 3, y: 4 }
      p.command { op: { do: 'flash', x: 5, y: 6 } }
      expect( p.pos ).to.eql { x: 5, y: 6 }
      p.command { op: { do: 'flash', y: 7 } }
      expect( p.pos ).to.eql { x: 5, y: 7 }
      p.command { op: { do: 'flash', x: 8 } }
      expect( p.pos ).to.eql { x: 8, y: 7 }
      p.command { op: { do: 'flash' } }
      expect( p.pos ).to.eql { x: 8, y: 7 }

    it 'should move the plotter with incremental notation', ->
      p.notation = 'I'
      p.command { op: { do: 'int', x: 1, y: 2 } }
      expect( p.pos ).to.eql { x: 1, y: 2 }
      p.command { op: { do: 'move', x: 3, y: 4 } }
      expect( p.pos ).to.eql { x: 4, y: 6 }
      p.command { op: { do: 'flash', x: 5, y: 6 } }
      expect( p.pos ).to.eql { x: 9, y: 12 }
      p.command { op: { do: 'flash', y: 7 } }
      expect( p.pos ).to.eql { x: 9, y: 19 }
      p.command { op: { do: 'flash', x: 8 } }
      expect( p.pos ).to.eql { x: 17, y: 19 }
      p.command { op: { do: 'flash' } }
      expect( p.pos ).to.eql { x: 17, y: 19 }

    describe 'flashing pads', ->

      it 'should add a pad with a flash', ->
        p.command { set: { currentTool: 'D10' } }
        expect(p.tools.D10.flashed).to.be.false
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        expect(p.tools.D10.flashed).to.be.true
        expect( p.defs[0].circle ).to.contain { r: 1 }
        expect( p.current[0].use ).to.contain { x: 2, y: 2 }

      it 'should only add a pad to defs once', ->
        p.command { set: { currentTool: 'D10' } }
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        expect(p.tools.D10.pad).to.not.be.false
        expect(p.defs).to.have.length 1

      it 'should add pads to the layer bbox', ->
        p.command { set: { currentTool: 'D11' } }
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        expect( p.layerBbox ).to.eql { xMin: 1, yMin: 1.5, xMax: 3, yMax: 2.5 }
        p.command { set: { currentTool: 'D10' } }
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        expect( p.layerBbox ).to.eql { xMin: 1, yMin: 1, xMax: 3, yMax: 3 }
        p.command { op: { do: 'flash', x: -2, y: -2 } }
        expect( p.layerBbox ).to.eql { xMin: -3, yMin: -3, xMax: 3, yMax: 3 }
        p.command { op: { do: 'flash', x: 3, y: 3 } }
        expect( p.layerBbox ).to.eql { xMin: -3, yMin: -3, xMax: 4, yMax: 4 }

      it 'should throw an error if in region mode', ->
        p.region = true
        expect( -> p.command { op: { do: 'flash', x: 2, y: 2 } } )
          .to.throw /region/

    describe 'paths', ->

      it 'should start a new path with an interpolate', ->
        p.command { op: { do: 'int', x: 5, y: 5 } }
        expect( p.path ).to.eql [ 'M', 0, 0, 'L', 5, 5 ]
        expect( p.layerBbox ).to.eql { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }

      it 'should throw an error for unstrokable tool outside region mode', ->
        p.command { tool: { D13: { dia: 5, vertices: 5 } } }
        expect( -> p.command { op: { do: 'int' } } ).to.throw /strokable tool/

      it 'should assume linear interpolation if none was specified', ->
        p.mode = null
        warnings.hook()
        p.command { op: { do: 'int', x: 5, y: 5 } }
        expect( warnings.unhook() ).to.match /assuming linear/i
        expect( p.mode ).to.eql 'i'

      describe 'adding to a linear path', ->

        beforeEach ->
          p.path = [ 'M', 0, 0, 'L', 5, 5 ]
          p.layerBbox = { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }

        it 'should add a lineto with an int', ->
          p.command { op: { do: 'int', x: 10, y: 10 } }
          expect( p.path ).to.eql [ 'M', 0, 0, 'L', 5, 5, 'L', 10, 10 ]
          expect( p.layerBbox ).to.eql { xMin: -1, yMin: -1, xMax: 11, yMax: 11}

        it 'should add a moveto with a move', ->
          p.command { op: { do: 'move', x: 10, y: 10 } }
          expect( p.path ).to.eql [ 'M', 0, 0, 'L', 5, 5, 'M', 10, 10 ]
          expect( p.layerBbox ).to.eql { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }

      describe 'ending the path', ->

        beforeEach -> p.path = [ 'M', 0, 0, 'L', 5, 5 ]

        it 'should end the path on a flash', ->
          p.command { op: { do: 'flash', x: 2, y: 2 } }
          expect( p.path ).to.be.empty

        it 'should end the path on a tool change', ->
          p.command { set: { currentTool: 'D10' } }
          expect( p.path ).to.be.empty

        it 'should end the path on a region change', ->
          p.command { set: { region: true } }
          expect( p.path ).to.be.empty

        it 'should end the path on a polarity change', ->
          p.command { new: { layer: 'C' } }
          expect( p.path ).to.be.empty

        it 'should end the path on a step repeat', ->
          p.command { new: { sr: { x: 2, y: 2, i: 1, j: 2 } } }
          expect( p.path ).to.be.empty

      describe 'stroking a rectangular tool', ->

        beforeEach -> p.command { set: { currentTool: 'D11' } }

        # these are fun because they just drag the rectange without rotation
        # let's test each of the quadrants
        # width of tool is 2, height is 1
        it 'should handle a first quadrant move', ->
          p.command { op: { do: 'int', x: 5, y: 5 } }
          expect( p.path ).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 6, 4.5, 6, 5.5, 4, 5.5, -1, 0.5, 'Z'
          ]

        it 'should handle a second quadrant move', ->
          p.command { op: { do: 'int', x: -5, y: 5 } }
          expect( p.path ).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 1, 0.5, -4, 5.5, -6, 5.5, -6, 4.5, 'Z'
          ]

        it 'should handle a third quadrant move', ->
          p.command { op: { do: 'int', x: -5, y: -5 } }
          expect( p.path ).to.eql [
            'M', 0, 0
            'M', 1, -0.5, 1, 0.5, -1, 0.5, -6, -4.5, -6, -5.5, -4, -5.5, 'Z'
          ]

        it 'should handle a fourth quadrant move', ->
          p.command { op: { do: 'int', x: 5, y: -5 } }
          expect( p.path ).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 4, -5.5, 6, -5.5, 6, -4.5, 1, 0.5, -1, 0.5, 'Z'
          ]

        it 'should handle a move along the positive x-axis', ->
          p.command { op: { do: 'int', x: 5, y: 0 } }
          expect( p.path ).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 6, -0.5, 6, 0.5, 4, 0.5, -1, 0.5, 'Z'
          ]

        it 'should handle a move along the negative x-axis', ->
          p.command { op: { do: 'int', x: -5, y: 0 } }
          expect( p.path ).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 1, 0.5, -4, 0.5, -6, 0.5, -6, -0.5, 'Z'
          ]

        it 'should handle a move along the positive y-axis', ->
          p.command { op: { do: 'int', x: 0, y: 5 } }
          expect( p.path ).to.eql [
            'M', 0, 0
            'M', -1, -0.5, 1, -0.5, 1, 0.5, 1, 5.5, -1, 5.5, -1, 4.5, 'Z'
          ]

        it 'should handle a move along the negative y-axis', ->
          p.command { op: { do: 'int', x: 0, y: -5 } }
          expect( p.path ).to.eql [
            'M', 0, 0
            'M', -1, -0.5, -1, -5.5, 1, -5.5, 1, -4.5, 1, 0.5, -1, 0.5, 'Z'
          ]

        it "should not have a stroke-width (it's filled instead)", ->
          p.command { op: { do: 'int', x: 5, y: 5 } }
          p.finishPath()
          expect( p.current[0] ).to.have.key 'path'
          expect( p.current[0].path ).to.not.have.key 'stroke-width'

      describe 'adding an arc to the path', ->

        it 'should throw an error if the tool is not circular', ->
          p.command { set: { currentTool: 'D11', mode: 'cw', quad: 's' } }
          expect( -> p.command { op: { do: 'int', x: 1, y: 1, i: 1 } } )
            .to.throw /arc with non-circular/

        it 'should not throw if non-circular tool in region mode', ->
          p.command { set:
            { currentTool: 'D11', mode: 'cw', region: true, quad: 's' }
          }
          expect( -> p.command { op: { do: 'int', x: 1, y: 1, i: 1 } } )
            .to.not.throw()

        it 'should throw an error if quadrant mode has not been specified', ->
          expect( -> p.command {
            set: { mode: 'cw' }, op: { do: 'int', x: 1, y: 1, i: 1 }
          }).to.throw /quadrant mode/

        describe 'single quadrant arc mode', ->

          beforeEach -> p.command { set: { quad: 's' } }

          it 'should add a CW arc with a set to cw', ->
            p.command { set: { mode: 'cw'}, op: {do: 'int', x: 1, y: 1, i: 1} }
            expect( p.path[-8..] ).to.eql [ 'A', 1, 1, 0, 0, 0, 1, 1 ]

          it 'should add a CCW arc with a G03', ->
            p.command { set: { mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, j: 1} }
            expect( p.path[-8..] ).to.eql [ 'A', 1, 1, 0, 0, 1, 1, 1 ]

          it 'should close the path on a zero length arc', ->
            p.command { set: { mode: 'ccw'}, op: {do: 'int', x: 0, y: 0, j: 1} }
            expect( p.path[-9..] ).to.eql [ 'A', 1, 1, 0, 0, 1, 0, 0, 'Z' ]

          it 'should warn for impossible arcs and add nothing to the path', ->
            warnings.hook()
            p.command { set: { mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, i: 1} }
            expect( warnings.unhook() ).to.match /impossible arc/
            expect( p.path ).to.not.contain 'A'

        describe 'multi quadrant arc mode', ->

          beforeEach -> p.command { set: { quad: 'm' } }

          it 'should add a CW arc with a G02', ->
            p.command { set: { mode: 'cw'}, op: {do: 'int', x: 1, y: 1, j: 1} }
            expect( p.path[-8..] ).to.eql [ 'A', 1, 1, 0, 1, 0, 1, 1 ]

          it 'should add a CCW arc with a G03', ->
            p.command { set: { mode: 'ccw'}, op: {do: 'int', x: 1, y: 1, i: 1} }
            expect( p.path[-8..] ).to.eql [ 'A', 1, 1, 0, 1, 1, 1, 1 ]

          it 'should add 2 paths for full circle if start is end', ->
            p.command { set: { mode: 'cw'}, op: { do: 'int', i: 1 } }
            expect( p.path[-16..] ).to.eql [
              'A', 1, 1, 0, 0, 0, 2, 0, 'A', 1, 1, 0, 0, 0, 0, 0
            ]

          it 'should warn for impossible arc and add nothing to the path', ->
            warnings.hook()
            p.command { set: { mode: 'cw' }, op: {do: 'int', x: 1, y: 1, j:-1 }}
            expect( warnings.unhook() ).to.match /impossible arc/
            expect( p.path ).to.not.contain 'A'

        # tool is a dia 2 circle for these tests
        describe 'adjusting the layer bbox', ->

          it 'sweeping past 180 deg determines min X', ->
            p.command { op: { do: 'move', x: -0.7071, y: -0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: -0.7071, y: 0.7071, i: 0.7071, j: 0.7071 }
            }
            result = -2 - p.layerBbox.xMin
            expect( result ).to.be.closeTo 0, 0.00001

          it 'sweeping past 270 deg determines min Y', ->
            p.command { op: { do: 'move', x: 0.7071, y: -0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: -0.7071, y: -0.7071, i: 0.7071, j: 0.7071 }
            }
            result = -2 - p.layerBbox.yMin
            expect( result ).to.be.closeTo 0, 0.00001

          it 'sweeping past 90 deg determines max Y', ->
            p.command { op: { do: 'move', x: -0.7071, y: 0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.7071, y: 0.7071, i: 0.7071, j: 0.7071 }
            }
            result = 2 - p.layerBbox.yMax
            expect( result ).to.be.closeTo 0, 0.00001

          it 'sweeping past 0 deg determines max X', ->
            p.command { op: { do: 'move', x: 0.7071, y: 0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.7071, y: -0.7071, i: 0.7071, j: 0.7071 }
            }
            result = 2 - p.layerBbox.xMax
            expect( result ).to.be.closeTo 0, 0.00001

          it 'if its just hanging out, use the end points', ->
            p.command { op: { do: 'move', x: 0.5, y: 0.866 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.866, y: 0.5, i: 0.5, j: 0.866 }
            }
            expect( p.layerBbox.xMin ).to.equal -0.5
            expect( p.layerBbox.yMin ).to.equal -0.5
            expect( p.layerBbox.xMax ).to.equal 1.8660
            expect( p.layerBbox.yMax ).to.equal 1.8660

      describe 'region mode off', ->

        it 'should add the trace properties to the path when it ends', ->
          p.path = ['M', 0, 0, 'L', 5, 5 ]
          p.finishPath()
          expect( p.current[0].path.d ).to.eql ['M', 0, 0, 'L', 5, 5]
          expect( p.current[0].path.fill ).to.eql 'none'
          expect( p.current[0].path['stroke-width'] ).to.equal 2

      describe 'region mode on', ->

        it 'should allow any tool to create a region', ->
          p.command { tool: { D13: { dia: 5, vertices: 5 } } }
          p.command { set: { region: true } }
          expect( -> p.command { op:{ do: 'int', x: 5, y: 5 } } ).to.not.throw()

        it 'should not take the tool into account when calculating the bbox', ->
          p.command { set: { region: true } }
          p.command { op: { do: 'int', x: 5, y: 5 } }
          expect( p.layerBbox ).to.eql { xMin: 0, yMin: 0, xMax: 5, yMax: 5 }

        it 'should add a path element to the current layer', ->
          p.command { set: { region: true } }
          p.command { op: { do: 'int', x: 5, y: 5 } }
          p.command { op: { do: 'int', x: 0, y: 5 } }
          p.command { op: { do: 'int', x: 0, y: 0 } }
          p.finishPath()
          expect( p.current[0].path.d ).to.eql [
            'M', 0, 0, 'L', 5, 5, 'L', 0, 5, 'L', 0, 0, 'Z'
          ]

    describe 'modal operation codes', ->

      it 'should throw a warning if operation codes are used modally', ->
        warnings.hook()
        p.command { op: { do: 'int', x: 1, y: 1 } }
        p.command { op: { do: 'last', x: 2, y: 2 } }
        expect( warnings.unhook() ).to.match /modal operation/

      it 'should continue a stroke if last operation was a stroke', ->
        p.command { op: { do: 'int', x: 1, y: 1 } }
        p.command { op: { do: 'last', x: 2, y: 2 } }
        expect( p.path ).to.eql [ 'M', 0, 0, 'L', 1, 1, 'L', 2, 2 ]

      it 'should move if last operation was a move', ->
        p.command { op: { do: 'move', x: 1, y: 1 } }
        p.command { op: { do: 'last', x: 2, y: 2 } }
        expect( p.pos ).to.eql { x: 2, y: 2 }

      it 'should flash if last operation was a flash', ->
        p.command { op: { do: 'flash', x: 1, y: 1 } }
        p.command { op: { do: 'last', x: 2, y: 2 } }
        expect( p.current ).to.have.length 2
        expect( p.current[0].use ).to.contain { x: 1, y: 1 }
        expect( p.current[1].use ).to.contain { x: 2, y: 2 }

  describe 'finish layer method', ->

    beforeEach -> p.current = [ 'item0', 'item1', 'item2' ]

    it 'should add the current items to the group if only one dark layer', ->
      p.finishLayer()
      expect( p.group ).to.eql { g: { _: [ 'item0', 'item1', 'item2' ] } }
      expect( p.current ).to.be.empty

    describe 'multiple layers', ->

      it 'if clear layer, should mask the group with them', ->
        p.polarity = 'C'
        p.bbox = { xMin: 0, yMin: 0, xMax: 2, yMax: 2 }
        p.finishLayer()
        mask = p.defs[0].mask
        expect( mask.color ).to.eql '#000'
        expect( mask._ ).to.eql [
          { rect: { x: 0, y: 0, width: 2, height: 2, fill: '#fff' } }
          'item0'
          'item1'
          'item2'
        ]
        id = p.defs[0].mask.id
        expect( p.group ).to.eql { g: { mask: "url(##{id})", _: [] } }
        expect( p.current ).to.be.empty

      it 'if dark layer after clear layer, it should wrap the group', ->
        p.group = { g: { mask: 'url(#mask-id)', _: [ 'gItem1', 'gItem2' ] } }
        p.finishLayer()
        expect( p.group ).to.eql {
          g: {
            _: [
              { g: { mask: 'url(#mask-id)', _: [ 'gItem1', 'gItem2' ] } }
              'item0'
              'item1'
              'item2'
            ]
          }
        }

    describe 'step repeat', ->

      beforeEach ->
        p.layerBbox = { xMin: 0, yMin: 0, xMax: 2, yMax: 2 }
        p.stepRepeat = { x: 2, y: 2, i: 3, j: 3 }

      describe 'with a dark layer', ->

        it 'should wrap current in a group, copy it, and add it to @group', ->
          p.finishLayer()
          id = p.group.g._[0].g.id
          expect( p.group.g._ ).to.deep.contain.members [
            { g: { id: id, _: [ 'item0', 'item1', 'item2' ] } }
            { use: { y: 3, 'xlink:href': "##{id}" } }
            { use: { x: 3, 'xlink:href': "##{id}" } }
            { use: { x:3, y: 3, 'xlink:href': "##{id}" } }
          ]
          expect( p.current ).to.be.empty

        it 'leave existing (pre-stepRepeat) items alone', ->
          p.group.g._ = [ 'existing1', 'existing2' ]
          p.finishLayer()
          expect( p.group.g._ ).to.have.length 6
          id = p.group.g._[2].g.id
          expect( p.group.g._ ).to.deep.contain.members [
            'existing1'
            'existing2'
            { g: { id: id, _: [ 'item0', 'item1', 'item2' ] } }
            { use: { y: 3, 'xlink:href': "##{id}" } }
            { use: { x: 3, 'xlink:href': "##{id}" } }
            { use: { x:3, y: 3, 'xlink:href': "##{id}" } }
          ]
          expect( p.current ).to.be.empty

      describe 'with a clear layer', ->

        it 'should wrap the current items and repeat them in the mask', ->
          p.polarity = 'C'
          p.finishLayer()
          maskId = p.defs[0].mask.id
          groupId = p.defs[0].mask._[1].g.id
          expect( p.defs[0].mask._ ).to.deep.contain.members [
            { rect: { x: 0, y: 0, width: 5, height: 5, fill: '#fff' } }
            { g: { id: groupId, _: [ 'item0', 'item1', 'item2' ] } }
            { use: { y: 3, 'xlink:href': "##{groupId}" } }
            { use: { x: 3, 'xlink:href': "##{groupId}" } }
            { use: { x:3, y: 3, 'xlink:href': "##{groupId}" } }
          ]
          expect( p.group.g.mask ).to.eql "url(##{maskId})"
          expect( p.current ).to.be.empty

      describe 'overlapping clear layers', ->

        beforeEach ->
          p.layerBbox = { xMin: 0, yMin: 0, xMax: 4, yMax: 4 }
          p.finishLayer()
          p.current = [ 'item3', 'item4' ]
          p.layerBbox = { xMin: 0, yMin: 0, xMax: 6, yMax: 6 }
          p.polarity = 'C'
          p.finishLayer()

        it 'should push the ids of sr layers to the overlap array', ->
          expect( p.srOverCurrent[0].D ).to.match /gerber-sr/
          expect( p.srOverCurrent[0] ).to.not.have.key 'C'
          expect( p.srOverCurrent[1].C ).to.match /gerber-sr/
          expect( p.srOverCurrent[1] ).to.not.have.key 'D'

        it 'should push dark layers to the group normally', ->
          expect( p.group.g._[0] ).to.have.key 'g'
          expect( p.group.g._[1] ).to.have.key 'use'
          expect( p.group.g._[2] ).to.have.key 'use'
          expect( p.group.g._[3] ).to.have.key 'use'

        it 'should set the clear overlap flag and not mask immediately', ->
          expect( p.srOverClear ).to.be.true

        it 'should create the mask when the sr changes', ->
          id = []
          for layer in p.srOverCurrent
            id.push "##{val}" for key, val of layer
          p.command { new: { sr: { x: 1, y: 1 } } }
          expect( p.srOverCurrent.length ).to.equal 0
          expect( p.srOverClear ).to.be.false
          expect( p.defs[0].g._ ).to.eql [ 'item3', 'item4' ]
          expect( p.defs[1].mask.color ).to.eql '#000'
          maskId = p.defs[1].mask.id
          expect( p.group.g.mask ).to.eql "url(##{maskId})"
          expect( p.defs[1].mask._ ).to.eql [
            { rect: { fill: '#fff', x: 0, y: 0, width: 9, height: 9 } }
            { use: { fill: '#fff', 'xlink:href': id[0] } }
            { use: { 'xlink:href': id[1] } }
            { use: { y: 3, fill: '#fff', 'xlink:href': id[0] } }
            { use: { y: 3, 'xlink:href': id[1] } }
            { use: { x: 3, fill: '#fff', 'xlink:href': id[0] } }
            { use: { x: 3, 'xlink:href': id[1] } }
            { use: { x: 3, y: 3, fill: '#fff', 'xlink:href': id[0] } }
            { use: { x: 3, y: 3, 'xlink:href': id[1] } }
          ]

        it 'should also finish the SR at the end of file', ->
          p.finish()
          expect( p.srOverCurrent.length ).to.equal 0
          expect( p.srOverClear ).to.be.false

  describe 'overall fill and stroke style', ->

    it 'should default stroke-linecap and stroke-linejoin to round', ->
      expect( p.attr['stroke-linecap'] ).to.eql 'round'
      expect( p.attr['stroke-linejoin'] ).to.eql 'round'

    it 'should default stroke-width to 0', ->
      expect( p.attr['stroke-width'] ).to.eql 0

    it 'should default stroke to black', ->
      expect( p.attr.stroke ).to.eql '#000'
