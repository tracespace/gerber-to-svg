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
      it 'should not throw missing tool exception for drill files', ->
        # drill files sometimes do this, so check for it
        p = new Plotter '', null, require '../src/drill-parser'
        (-> p.command { set: { currentTool: 'T0' } } ).should.not.throw()
      it 'should throw if region mode is on', ->
        p.region = true
        p.tools.D10 = {}
        (-> p.command { set: { currentTool: 'D10' } }).should.throw /tool/
    it 'should set the interpolation mode', ->
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

  describe 'new layer commands', ->
    it 'should finish any in progress layer', ->
      p.current = [ 'stuff' ]
      p.command { new: { sr: { x: 2, y: 3, i: 7, j: 2 } } }
      p.current.should.eql []
      p.current = [ 'more', 'stuff' ]
      p.command { new: { layer: 'C' } }
      p.current.should.eql []

    it 'should set step repeat params', ->
      p.command { new: { sr: { x: 2, y: 3, i: 7, j: 2 } } }
      p.stepRepeat.should.eql { x: 2, y: 3, i: 7, j: 2 }
      p.command { new: { sr: { x: 1, y: 1 } } }
      p.stepRepeat.should.eql { x: 1, y: 1 }

    it 'should set polarity param', ->
      p.command { new: { layer: 'C' } }
      p.polarity.should.eql 'C'
      p.command { new: { layer: 'D' } }
      p.polarity.should.eql 'D'

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

      it 'should assume notation is absolute if not set on a drill file', ->
        p = new Plotter '', null, require '../src/drill-parser'
        p.units = 'in'
        p.command { tool: { T1: { dia: 1 } } }
        (-> p.command { op: { do: 'flash', x: 1, y: 1 } }).should.not.throw()
        p.notation.should.eql 'A'

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
      it 'should add pads to the layer bbox', ->
        p.command { set: { currentTool: 'D11' } }
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        p.layerBbox.should.eql { xMin: 1, yMin: 1.5, xMax: 3, yMax: 2.5 }
        p.command { set: { currentTool: 'D10' } }
        p.command { op: { do: 'flash', x: 2, y: 2 } }
        p.layerBbox.should.eql { xMin: 1, yMin: 1, xMax: 3, yMax: 3 }
        p.command { op: { do: 'flash', x: -2, y: -2 } }
        p.layerBbox.should.eql { xMin: -3, yMin: -3, xMax: 3, yMax: 3 }
        p.command { op: { do: 'flash', x: 3, y: 3 } }
        p.layerBbox.should.eql { xMin: -3, yMin: -3, xMax: 4, yMax: 4 }
      it 'should throw an error if in region mode', ->
        p.region = true
        (-> p.command { op: { do: 'flash', x: 2, y: 2 } }).should.throw /region/
    describe 'paths', ->
      it 'should start a new path with an interpolate', ->
        p.command { op: { do: 'int', x: 5, y: 5 } }
        p.path.should.eql [ 'M', 0, 0, 'L', 5, 5 ]
        p.layerBbox.should.eql { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }
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
          p.layerBbox = { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }
        it 'should add a lineto with an int', ->
          p.command { op: { do: 'int', x: 10, y: 10 } }
          p.path.should.eql [ 'M', 0, 0, 'L', 5, 5, 'L', 10, 10 ]
          p.layerBbox.should.eql { xMin: -1, yMin: -1, xMax: 11, yMax: 11 }
        it 'should add a moveto with a move', ->
          p.command { op: { do: 'move', x: 10, y: 10 } }
          p.path.should.eql [ 'M', 0, 0, 'L', 5, 5, 'M', 10, 10 ]
          p.layerBbox.should.eql { xMin: -1, yMin: -1, xMax: 6, yMax: 6 }
      describe 'ending the path', ->
        beforeEach -> p.path = [ 'M', 0, 0, 'L', 5, 5 ]
        it 'should end the path on a flash', ->
          p.command { op: { do: 'flash', x: 2, y: 2 } }
          p.path.should.eql []
        it 'should end the path on a tool change', ->
          p.command { set: { currentTool: 'D10' } }
          p.path.should.eql []
        it 'should end the path on a region change', ->
          p.command { set: { region: true } }
          p.path.should.eql []
        it 'should end the path on a polarity change', ->
          p.command { new: { layer: 'C' } }
          p.path.should.eql []
        it 'should end the path on a step repeat', ->
          p.command { new: { sr: { x: 2, y: 2, i: 1, j: 2 } } }
          p.path.should.eql []

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
        describe 'adjusting the layer bbox', ->
          it 'sweeping past 180 deg determines min X', ->
            p.command { op: { do: 'move', x: -0.7071, y: -0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: -0.7071, y: 0.7071, i: 0.7071, j: 0.7071 }
            }
            result = Math.abs -2-p.layerBbox.xMin
            result.should.be.lessThan 0.00001
          it 'sweeping past 270 deg determines min Y', ->
            p.command { op: { do: 'move', x: 0.7071, y: -0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: -0.7071, y: -0.7071, i: 0.7071, j: 0.7071 }
            }
            result = Math.abs -2-p.layerBbox.yMin
            result.should.be.lessThan 0.00001
          it 'sweeping past 90 deg determines max Y', ->
            p.command { op: { do: 'move', x: -0.7071, y: 0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.7071, y: 0.7071, i: 0.7071, j: 0.7071 }
            }
            result = Math.abs 2-p.layerBbox.yMax
            result.should.be.lessThan 0.00001
          it 'sweeping past 0 deg determines max X', ->
            p.command { op: { do: 'move', x: 0.7071, y: 0.7071 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.7071, y: -0.7071, i: 0.7071, j: 0.7071 }
            }
            result = Math.abs 2-p.layerBbox.xMax
            result.should.be.lessThan 0.00001
          it 'if its just hanging out, use the end points', ->
            p.command { op: { do: 'move', x: 0.5, y: 0.866 } }
            p.command {
              set: { mode: 'cw', quad: 's' }
              op: { do: 'int', x: 0.866, y: 0.5, i: 0.5, j: 0.866 }
            }
            p.layerBbox.xMin.should.equal -0.5
            p.layerBbox.yMin.should.equal -0.5
            p.layerBbox.xMax.should.equal 1.8660
            p.layerBbox.yMax.should.equal 1.8660

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
          p.layerBbox.should.eql { xMin: 0, yMin: 0, xMax: 5, yMax: 5 }
        it 'should add a path element to the current layer', ->
          p.command { set: { region: true } }
          p.command { op: { do: 'int', x: 5, y: 5 } }
          p.command { op: { do: 'int', x: 0, y: 5 } }
          p.command { op: { do: 'int', x: 0, y: 0 } }
          p.finishPath()
          p.current.should.containEql {
            path: { d: ['M', 0, 0, 'L', 5, 5, 'L', 0, 5, 'L', 0, 0, 'Z' ] }
          }

    describe 'modal operation codes', ->
      it 'should throw a warning if operation codes are used modally', ->
        hook = stderr()
        p.command { op: { do: 'int', x: 1, y: 1 } }
        p.command { op: { do: 'last', x: 2, y: 2 } }
        hook.captured().should.match /modal operation/
        hook.unhook()
      it 'should continue a stroke if last operation was a stroke', ->
        p.command { op: { do: 'int', x: 1, y: 1 } }
        p.command { op: { do: 'last', x: 2, y: 2 } }
        p.path.should.eql [ 'M', 0, 0, 'L', 1, 1, 'L', 2, 2 ]
      it 'should move if last operation was a move', ->
        p.command { op: { do: 'move', x: 1, y: 1 } }
        p.command { op: { do: 'last', x: 2, y: 2 } }
        p.pos.should.eql { x: 2, y: 2 }
      it 'should flash if last operation was a flash', ->
        p.command { op: { do: 'flash', x: 1, y: 1 } }
        p.command { op: { do: 'last', x: 2, y: 2 } }
        p.current.should.containDeep [
          { use: { x: 1, y: 1 } }, { use: { x: 2, y: 2 } }
        ]

  describe 'finish layer method', ->
    beforeEach -> p.current = [ 'item0', 'item1', 'item2' ]
    it 'should add the current items to the group if only one dark layer', ->
      p.finishLayer()
      p.group.should.eql { g: { _: [ 'item0', 'item1', 'item2' ] } }
      p.current.should.eql []
    describe 'multiple layers', ->
      it 'if clear layer, should mask the group with them', ->
        p.polarity = 'C'
        p.bbox = { xMin: 0, yMin: 0, xMax: 2, yMax: 2 }
        p.finishLayer()
        p.defs.should.containDeep [
          {
            mask: {
              color: '#000'
              _: [
                { rect: { x: 0, y: 0, width: 2, height: 2, fill: '#fff' } }
                'item0'
                'item1'
                'item2'
              ]
            }
          }
        ]
        id = p.defs[0].mask.id
        p.group.should.eql { g: { mask: "url(##{id})", _: [] } }
        p.current.should.eql []
      it 'if dark layer after clear layer, it should wrap the group', ->
        p.group = { g: { mask: 'url(#mask-id)', _: [ 'gItem1', 'gItem2' ] } }
        p.finishLayer()
        p.group.should.eql {
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
          p.group.should.containDeep {
            g: {
              _: [
                { g: { id: id, _: [ 'item0', 'item1', 'item2' ] } }
                { use: { y: 3, 'xlink:href': '#'+id } }
                { use: { x: 3, 'xlink:href': '#'+id } }
                { use: { x:3, y: 3, 'xlink:href': '#'+id } }
              ]
            }
          }
          p.current.should.eql []
        it 'leave existing (pre-stepRepeat) items alone', ->
          p.group.g._ = [ 'existing1', 'existing2' ]
          p.finishLayer()
          p.group.g._.should.have.length 6
          id = p.group.g._[2].g.id
          p.group.should.containDeep {
            g: {
              _: [
                'existing1'
                'existing2'
                { g: { _: [ 'item0', 'item1', 'item2' ] } }
                { use: { y: 3, 'xlink:href': '#'+id } }
                { use: { x: 3, 'xlink:href': '#'+id } }
                { use: { x:3, y: 3, 'xlink:href': '#'+id } }
              ]
            }
          }
          p.current.should.eql []

      describe 'with a clear layer', ->
        it 'should wrap the current items and repeat them in the mask', ->
          p.polarity = 'C'
          p.finishLayer()
          maskId = p.defs[0].mask.id
          groupId = p.defs[0].mask._[1].g.id
          p.defs[0].should.containDeep {
            mask: {
              _: [
                { rect: { x: 0, y: 0, width: 5, height: 5, fill: '#fff' } }
                { g: { _: [ 'item0', 'item1', 'item2' ] } }
                { use: { y: 3, 'xlink:href': '#'+groupId } }
                { use: { x: 3, 'xlink:href': '#'+groupId } }
                { use: { x:3, y: 3, 'xlink:href': '#'+groupId } }
              ]
            }
          }
          p.group.g.mask.should.eql "url(##{maskId})"
          p.current.should.eql []

      describe 'overlapping clear layers', ->
        beforeEach ->
          p.layerBbox = { xMin: 0, yMin: 0, xMax: 4, yMax: 4 }
          p.finishLayer()
          p.current = [ 'item3', 'item4' ]
          p.layerBbox = { xMin: 0, yMin: 0, xMax: 6, yMax: 6 }
          p.polarity = 'C'
          p.finishLayer()
        it 'should push the ids of sr layers to the overlap array', ->
          p.srOverCurrent[0].D.should.match /gerber-sr/
          p.srOverCurrent[0].should.not.have.key 'C'
          p.srOverCurrent[1].C.should.match /gerber-sr/
          p.srOverCurrent[1].should.not.have.key 'D'
        it 'should push dark layers to the group normally', ->
          p.group.g._.should.containDeep [
              { g: {} }
              { use: {} }
              { use: {} }
              { use: {} }
          ]
        it 'should set the clear overlap flag and not mask immediately', ->
          p.srOverClear.should.be.true
        it 'should create the mask when the sr changes', ->
          id = []
          for layer in p.srOverCurrent
            id.push val for key, val of layer
          p.command { new: { sr: { x: 1, y: 1 } } }
          p.srOverCurrent.length.should.equal 0
          p.srOverClear.should.be.false
          p.defs[0].should.containDeep {
            g: { _: [ 'item3', 'item4' ] }
          }
          p.defs[1].mask.color.should.eql '#000'
          maskId = p.defs[1].mask.id
          p.group.g.mask.should.eql "url(##{maskId})"
          p.defs[1].mask._.should.containDeep [
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
          p.srOverCurrent.length.should.equal 0
          p.srOverClear.should.be.false
  describe 'overall fill and stroke style', ->
    it 'should default stroke-linecap and stroke-linejoin to round', ->
      p.attr['stroke-linecap'].should.eql 'round'
      p.attr['stroke-linejoin'].should.eql 'round'
    it 'should default stroke-width to 0', ->
      p.attr['stroke-width'].should.eql 0
    it 'should default stroke to black', ->
      p.attr.stroke.should.eql '#000'
