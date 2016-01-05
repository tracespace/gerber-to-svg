// test suite for plotter
'use strict'

var expect = require('chai').expect
var forEach = require('lodash.foreach')

var plotter = require('../lib/gerber-plotter')
var boundingBox = require('../lib/_box')

describe('gerber plotter', function() {
  var p
  beforeEach(function() {
    p = plotter()
  })

  it('should be an object stream', function() {
    expect(function() {p.write({})}).to.not.throw()
  })

  describe('factory and options', function() {
    it('should allow user to set units', function() {
      p = plotter({units: 'mm'})
      expect(p.format.units).to.equal('mm')
      p = plotter({units: 'in'})
      expect(p.format.units).to.equal('in')

      expect(function() {p = plotter({units: 'foo'})}).to.throw(/units/)
    })

    it('should allow user to set backupUnits', function() {
      p = plotter({backupUnits: 'mm'})
      expect(p.format.backupUnits).to.equal('mm')
      p = plotter({units: 'in'})
      expect(p.format.units).to.equal('in')

      expect(function() {
        p = plotter({backupUnits: 'foo'})
      }).to.throw(/backup units/)
    })

    it('should allow user to set notation', function() {
      p = plotter({nota: 'A'})
      expect(p.format.nota).to.equal('A')
      p = plotter({nota: 'I'})
      expect(p.format.nota).to.equal('I')

      expect(function() {p = plotter({nota: 'foo'})}).to.throw(/notation/)
    })

    it('should allow user to set backup notation', function() {
      p = plotter({backupNota: 'A'})
      expect(p.format.backupNota).to.equal('A')
      p = plotter({backupNota: 'I'})
      expect(p.format.backupNota).to.equal('I')

      expect(function() {
        p = plotter({backupNota: 'foo'})
      }).to.throw(/backup notation/)
    })

    it('should default backup units and notation to inches and abs', function() {
      expect(p.format.backupUnits).to.equal('in')
      expect(p.format.backupNota).to.equal('A')
    })

    it('should throw if an options key is invalid', function() {
      expect(function() {p = plotter({foo: 'bar'})}).to.throw(/invalid/)
    })

    it('should not throw with null/undefined options', function() {
      var p
      expect(function() {p = plotter({units: null})}).to.not.throw()
      expect(p.format.units).to.be.null

      expect(function() {p = plotter({backupUnits: undefined})}).to.not.throw()
      expect(p.format.backupUnits).to.equal('in')

      expect(function() {p = plotter({nota: undefined})}).to.not.throw()
      expect(p.format.nota).to.be.null

      expect(function() {p = plotter({backupNota: null})}).to.not.throw()
      expect(p.format.backupNota).to.equal('A')
    })
  })

  describe('handling set commands', function() {
    describe('format', function() {
      it('should set units', function() {
        p.write({cmd: 'set', key: 'units', val: 'mm'})
        expect(p.format.units).to.equal('mm')

        p = plotter()
        p.write({cmd: 'set', key: 'units', val: 'in'})
        expect(p.format.units).to.equal('in')
      })

      it('should not redefine units', function() {
        p = plotter({units: 'in'})
        p.write({cmd: 'set', key: 'units', val: 'mm'})
        expect(p.format.units).to.equal('in')
      })

      it('should set the notation', function() {
        p.write({cmd: 'set', key: 'nota', val: 'A'})
        expect(p.format.nota).to.equal('A')

        p = plotter()
        p.write({cmd: 'set', key: 'nota', val: 'I'})
        expect(p.format.nota).to.equal('I')
      })

      it('should not redefine notation', function() {
        p = plotter({nota: 'A'})
        p.write({cmd: 'set', key: 'nota', val: 'I'})
        expect(p.format.nota).to.equal('A')
      })

      it('should set the backup units', function() {
        p.write({cmd: 'set', key: 'backupUnits', val: 'mm'})
        expect(p.format.backupUnits).to.equal('mm')
        p.write({cmd: 'set', key: 'backupUnits', val: 'in'})
        expect(p.format.backupUnits).to.equal('in')
      })

      it('should not redefine the backupUnits set by user', function() {
        p = plotter({backupUnits: 'in'})
        p.write({cmd: 'set', key: 'backupUnits', val: 'mm'})
        expect(p.format.backupUnits).to.equal('in')
      })

      it('should not redefine the backupNotation set by user', function() {
        p = plotter({backupNota: 'A'})
        p.write({cmd: 'set', key: 'backupNota', val: 'I'})
        expect(p.format.backupNota).to.equal('A')
      })
    })

    describe('plotter state', function() {
      it('should change the tool', function() {
        var tool = {}
        p._tools['10'] = tool

        p.write({cmd: 'set', key: 'tool', val: '10'})
        expect(p._tool).to.equal(tool)
      })

      it('should warn if the tool doesnt exist', function(done) {
        p.once('warning', function(w) {
          expect(w.line).to.equal(10)
          expect(w.message).to.match(/tool 10/)
          expect(p._tool).to.be.null
          done()
        })

        p.write({cmd: 'set', line: 10, key: 'tool', val: '10'})
      })

      it('should set the region mode', function() {
        p.write({cmd: 'set', line: 10, key: 'region', val: true})
        expect(p._region).to.be.true
        p.write({cmd: 'set', line: 10, key: 'region', val: false})
        expect(p._region).to.be.false
      })

      it ('should warn and ignore tool changes if region mode is on', function(done) {
        p.once('warning', function(w) {
          expect(w.line).to.equal(11)
          expect(w.message).to.match(/region/)
          expect(p._tool).to.be.null
          done()
        })

        p._tools['10'] = {}
        p.write({cmd: 'set', line: 10, key: 'region', val: true})
        p.write({cmd: 'set', line: 11, key: 'tool', val: '10'})
      })

      it('should set the interpolation mode', function() {
        p.write({cmd: 'set', key: 'mode', val: 'i'})
        expect(p._mode).to.equal('i')
        p.write({cmd: 'set', key: 'mode', val: 'cw'})
        expect(p._mode).to.equal('cw')
        p.write({cmd: 'set', key: 'mode', val: 'ccw'})
        expect(p._mode).to.equal('ccw')
      })

      it('should set the arc quadrant mode', function() {
        p.write({cmd: 'set', key: 'quad', val: 's'})
        expect(p._quad).to.equal('s')
        p.write({cmd: 'set', key: 'quad', val: 'm'})
        expect(p._quad).to.equal('m')
      })
    })
  })

  describe('handling done command', function() {
    it('should set the done flag', function() {
      p.write({cmd: 'done'})
      expect(p._done).to.be.true
    })

    it('should warn if other commands come in after a done', function(done) {
      p.once('warning', function(w) {
        expect(w.message).to.match(/done/)
        done()
      })

      p.write({cmd: 'done'})
      p.write({cmd: 'set', key: 'mode', val: 'i'})
    })
  })

  describe('handling new tool commands', function() {
    it('should set current tool to newly defined tool', function() {
      var circle = {shape: 'circle', val: [4], hole: []}
      p.write({cmd: 'tool', key: '10', val: circle})
      expect(p._tools['10']).to.equal(p._tool)
      p.write({cmd: 'tool', key: '15', val: circle})
      expect(p._tools['15']).to.equal(p._tool)
    })

    it('should set trace width for circle and rectangle tools', function() {
      var circle = {shape: 'circle', val: [4], hole: []}
      var rect = {shape: 'rect', val: [2, 3], hole: []}

      p.write({cmd: 'tool', key: '10', val: circle})
      expect(p._tool.trace).to.eql([4])

      p.write({cmd: 'tool', key: '11', val: rect})
      expect(p._tool.trace).to.eql([2, 3])
    })

    it('should warn and ignore if the tool has already been set', function(done) {
      var circle = {shape: 'circle', val: [4], hole: []}
      var rect = {shape: 'rect', val: [2, 3], hole: []}

      p.once('warning', function(w) {
        expect(w.message).to.match(/already defined/)
        expect(w.line).to.equal(9)
        expect(p._tool.trace).to.eql([4])
        done()
      })

      p.write({cmd: 'tool', key: '10', val: circle, line: 8})
      p.write({cmd: 'tool', key: '10', val: rect, line: 9})
    })

    it('should not set trace for untraceable tools', function() {
      var circle = {shape: 'circle', val: [4], hole: [1, 1]}
      var rect = {shape: 'rect', val: [2, 3], hole: [1]}
      var obround = {shape: 'obround', val: [2, 3], hole: []}
      var poly = {shape: 'poly', val: [2, 3, 4], hole: []}
      var macro = {shape: 'SOME_MACRO', val: [], hole: []}
      p.write({cmd: 'tool', key: '10', val: circle})
      expect(p._tool.trace).to.eql([])
      p.write({cmd: 'tool', key: '11', val: rect})
      expect(p._tool.trace).to.eql([])
      p.write({cmd: 'tool', key: '12', val: obround})
      expect(p._tool.trace).to.eql([])
      p.write({cmd: 'tool', key: '13', val: poly})
      expect(p._tool.trace).to.eql([])
      p.write({cmd: 'tool', key: '14', val: macro})
      expect(p._tool.trace).to.eql([])
    })

    describe('standard tool pad shapes', function() {
      it('should create pad shapes for standard circles', function() {
        var circle0 = {shape: 'circle', val: [1], hole: []}
        var circle1 = {shape: 'circle', val: [2], hole: [1]}
        var circle2 = {shape: 'circle', val: [3], hole: [1, 1]}

        p.write({cmd: 'tool', key: '10', val: circle0})
        expect(p._tool.pad).to.eql([{type: 'circle', cx: 0, cy: 0, r: 0.5}])

        p.write({cmd: 'tool', key: '11', val: circle1})
        expect(p._tool.pad).to.eql([
          {type: 'circle', cx: 0, cy: 0, r: 1},
          {type: 'layer', polarity: 'clear', box: [-1, -1, 1, 1]},
          {type: 'circle', cx: 0, cy: 0, r: 0.5}
        ])

        p.write({cmd: 'tool', key: '12', val: circle2})
        expect(p._tool.pad).to.eql([
          {type: 'circle', cx: 0, cy: 0, r: 1.5},
          {type: 'layer', polarity: 'clear', box: [-1.5, -1.5, 1.5, 1.5]},
          {type: 'rect', cx: 0, cy: 0, r: 0, width: 1, height: 1}
        ])
      })

      it('should create pad shapes for standard rectangles', function() {
        var rect0 = {shape: 'rect', val: [1, 2], hole: []}
        var rect1 = {shape: 'rect', val: [3, 4], hole: [1]}
        var rect2 = {shape: 'rect', val: [5, 6], hole: [1, 1]}

        p.write({cmd: 'tool', key: '10', val: rect0})
        expect(p._tool.pad).to.eql([
          {type: 'rect', cx: 0, cy: 0, r: 0, width: 1, height: 2}
        ])

        p.write({cmd: 'tool', key: '11', val: rect1})
        expect(p._tool.pad).to.eql([
          {type: 'rect', cx: 0, cy: 0, r: 0, width: 3, height: 4},
          {type: 'layer', polarity: 'clear', box: [-1.5, -2, 1.5, 2]},
          {type: 'circle', cx: 0, cy: 0, r: 0.5}
        ])

        p.write({cmd: 'tool', key: '12', val: rect2})
        expect(p._tool.pad).to.eql([
          {type: 'rect', cx: 0, cy: 0, r: 0, width: 5, height: 6},
          {type: 'layer', polarity: 'clear', box: [-2.5, -3, 2.5, 3]},
          {type: 'rect', cx: 0, cy: 0, r: 0, width: 1, height: 1}
        ])
      })

      it('should create pad shapes for standard obrounds', function() {
        var obround0 = {shape: 'obround', val: [1, 2], hole: []}
        var obround1 = {shape: 'obround', val: [4, 3], hole: [1]}
        var obround2 = {shape: 'obround', val: [5, 6], hole: [1, 1]}

        p.write({cmd: 'tool', key: '10', val: obround0})
        expect(p._tool.pad).to.eql([
          {type: 'rect', cx: 0, cy: 0, r: 0.5, width: 1, height: 2}
        ])

        p.write({cmd: 'tool', key: '11', val: obround1})
        expect(p._tool.pad).to.eql([
          {type: 'rect', cx: 0, cy: 0, r: 1.5, width: 4, height: 3},
          {type: 'layer', polarity: 'clear', box: [-2, -1.5, 2, 1.5]},
          {type: 'circle', cx: 0, cy: 0, r: 0.5}
        ])

        p.write({cmd: 'tool', key: '12', val: obround2})
        expect(p._tool.pad).to.eql([
          {type: 'rect', cx: 0, cy: 0, r: 2.5, width: 5, height: 6},
          {type: 'layer', polarity: 'clear', box: [-2.5, -3, 2.5, 3]},
          {type: 'rect', cx: 0, cy: 0, r: 0, width: 1, height: 1}
        ])
      })

      it('should create pad shapes for standard polygons', function() {
        var poly0 = {shape: 'poly', val: [2, 3, 0], hole: []}
        var poly1 = {shape: 'poly', val: [2, 6, 45], hole: [1]}
        var poly2 = {shape: 'poly', val: [2, 12, 140], hole: [1, 1]}

        p.write({cmd: 'tool', key: '10', val: poly0})
        expect(p._tool.pad).to.eql([
          {type: 'poly', points: [
            [1, 0],
            [-0.5, 0.8660254],
            [-0.5, -0.8660254]
          ]}
        ])

        p.write({cmd: 'tool', key: '11', val: poly1})
        var poly = p._tool.pad[0]
        var box = [-0.96592583, -0.96592583, 0.96592583, 0.96592583]

        expect(p._tool.pad).to.have.length(3)
        expect(poly).to.have.all.keys(['type', 'points'])
        expect(poly.type).to.equal('poly')
        expect(poly.points).to.eql([
          [0.70710678, 0.70710678],
          [-0.25881905, 0.96592583],
          [-0.96592583, 0.25881905],
          [-0.70710678, -0.70710678],
          [0.25881905, -0.96592583],
          [0.96592583, -0.25881905]
        ])
        expect(p._tool.pad.slice(1)).to.eql([
          {type: 'layer', polarity: 'clear', box: box},
          {type: 'circle', cx: 0, cy: 0, r: 0.5}
        ])

        p.write({cmd: 'tool', key: '12', val: poly2})
        poly = p._tool.pad[0]
        box = [-0.98480775, -0.98480775, 0.98480775, 0.98480775]

        expect(p._tool.pad).to.have.length(3)
        expect(poly).to.have.all.keys(['type', 'points'])
        expect(poly.type).to.equal('poly')
        expect(poly.points).to.eql([
          [-0.76604444, 0.64278761],
          [-0.98480775, 0.17364818],
          [-0.93969262, -0.34202014],
          [-0.64278761, -0.76604444],
          [-0.17364818, -0.98480775],
          [0.34202014, -0.93969262],
          [0.76604444, -0.64278761],
          [0.98480775, -0.17364818],
          [0.93969262, 0.34202014],
          [0.64278761, 0.76604444],
          [0.17364818, 0.98480775],
          [-0.34202014, 0.93969262]
        ])
        expect(p._tool.pad.slice(1)).to.eql([
          {type: 'layer', polarity: 'clear', box: box},
          {type: 'rect', cx: 0, cy: 0, r: 0, width: 1, height: 1}
        ])
      })
    })

    describe('standard tool bounding boxes', function() {
      it('should calculate a bounding box for a circle', function() {
        var circle0 = {shape: 'circle', val: [1], hole: []}
        var circle1 = {shape: 'circle', val: [7], hole: [1]}
        var circle2 = {shape: 'circle', val: [4], hole: [1, 1]}

        p.write({cmd: 'tool', key: '10', val: circle0})
        expect(p._tool.box).to.eql([-0.5, -0.5, 0.5, 0.5])
        p.write({cmd: 'tool', key: '11', val: circle1})
        expect(p._tool.box).to.eql([-3.5, -3.5, 3.5, 3.5])
        p.write({cmd: 'tool', key: '12', val: circle2})
        expect(p._tool.box).to.eql([-2, -2, 2, 2])
      })

      it('should calculate a bounding box for a rects and obrounds', function() {
        var rect0 = {shape: 'rect', val: [1, 2], hole: []}
        var rect1 = {shape: 'rect', val: [7, 4], hole: [1]}
        var obround0 = {shape: 'obround', val: [9, 8], hole: [1, 1]}
        var obround1 = {shape: 'obround', val: [4, 1], hole: []}

        p.write({cmd: 'tool', key: '10', val: rect0})
        expect(p._tool.box).to.eql([-0.5, -1, 0.5, 1])
        p.write({cmd: 'tool', key: '11', val: rect1})
        expect(p._tool.box).to.eql([-3.5, -2, 3.5, 2])
        p.write({cmd: 'tool', key: '12', val: obround0})
        expect(p._tool.box).to.eql([-4.5, -4, 4.5, 4])
        p.write({cmd: 'tool', key: '13', val: obround1})
        expect(p._tool.box).to.eql([-2, -0.5, 2, 0.5])
      })

      it('should calculate a bounding box for a standard polygon', function() {
        var poly0 = {shape: 'poly', val: [5, 4, 0], hole: []}
        var poly1 = {shape: 'poly', val: [6, 8, 0], hole: [1]}
        var poly2 = {shape: 'poly', val: [4 * Math.sqrt(2), 4, 45], hole: [1, 1]}

        p.write({cmd: 'tool', key: '10', val: poly0})
        expect(p._tool.box).to.eql([-2.5, -2.5, 2.5, 2.5])
        p.write({cmd: 'tool', key: '11', val: poly1})
        expect(p._tool.box).to.eql([-3, -3, 3, 3])
        p.write({cmd: 'tool', key: '12', val: poly2})
        expect(p._tool.box).to.eql([-2, -2, 2, 2], 10)
      })
    })

    describe('macro tool pads', function() {
      describe('primitives without rotation', function() {
        it('should ignore comment primitives', function() {
          var macro = {cmd: 'macro', key: 'EMPTY', val: [{type: 'comment'}]}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'EMPTY', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([])
          expect(p._tool.box).to.eql([Infinity, Infinity, -Infinity, -Infinity])
        })

        it('should be able to handle shape and box for circle primitives', function() {
          var blocks = [{type: 'circle', exp: 1, dia: 4, cx: 3, cy: 4, rot: 0}]
          var macro = {cmd: 'macro', key: 'CIRC', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'CIRC', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([{type: 'circle', cx: 3, cy: 4, r: 2}])
          expect(p._tool.box).to.eql([1, 2, 5, 6])
        })

        it('should be able to handle shape and box for vect primitives', function() {
          var blocks = [
            {type: 'vect', exp: 1, width: 2, x1: 0, y1: 0, x2: 5, y2: 0, rot: 0},
            {type: 'vect', exp: 1, width: 1, x1: 0, y1: 0, x2: 0, y2: 5, rot: 0}
          ]
          var macro = {cmd: 'macro', key: 'VECT', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'VECT', val: [], hole: []}}

          p.write(macro)
          p.write(tool)

          expect(p._tool.pad).to.eql([
            {type: 'poly', points: [[0, -1], [5, -1], [5, 1], [0, 1]]},
            {type: 'poly', points: [[0.5, 0], [0.5, 5], [-0.5, 5], [-0.5, 0]]}
          ])

          expect(p._tool.box).to.eql([-0.5, -1, 5, 5])
        })

        it('should be able to handle rectangle primitives', function() {
          var blocks = [
            {type: 'rect', exp: 1, width: 4, height: 2, cx: 3, cy: 4, rot: 0}
          ]
          var macro = {cmd: 'macro', key: 'RECT', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'RECT', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([
            {type: 'rect', cx: 3, cy: 4, width: 4, height: 2, r: 0}
          ])
          expect(p._tool.box).to.eql([1, 3, 5, 5])
        })

        it('should be able to handle lower-left rects', function() {
          var blocks = [
            {type: 'rectLL', exp: 1, width: 4, height: 2, x: 1, y: 3, rot: 0}
          ]
          var macro = {cmd: 'macro', key: 'LRECT', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'LRECT', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([
            {type: 'rect', cx: 3, cy: 4, width: 4, height: 2, r: 0}
          ])
          expect(p._tool.box).to.eql([1, 3, 5, 5])
        })

        it('should be able to handle an outline primitive', function() {
          var blocks = [
            {type: 'outline', exp: 1, points: [0, 0, 1, 0, 1, 1, 0, 0], rot: 0}
          ]
          var macro = {cmd: 'macro', key: 'OPOLY', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'OPOLY', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([
            {type: 'poly', points: [[0, 0], [1, 0], [1, 1]]}
          ])
          expect(p._tool.box).to.eql([0, 0, 1, 1])
        })

        it('should handle a regular polygon primitive', function() {
          var blocks = [
            {type: 'poly', exp: 1, vertices: 4, cx: 3, cy: 2, dia: 2, rot: 0}
          ]
          var macro = {cmd: 'macro', key: 'POLY', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'POLY', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([{
            type: 'poly',
            points: [[4, 2], [3, 3], [2, 2], [3, 1]]
          }])
          expect(p._tool.box).to.eql([2, 1, 4, 3])
        })

        it('should handle moiré primitives with only rings', function() {
          var blocks = [{
            type: 'moire',
            exp: 1,
            cx: 2,
            cy: 3,
            dia: 4,
            ringThx: 0.4,
            ringGap: 0.2,
            maxRings: 2,
            crossThx: 0.1,
            crossLen: 5,
            rot: 0
          }]
          var macro = {cmd: 'macro', key: 'TARG', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'TARG', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([
            {type: 'ring', cx: 2, cy: 3, r: 1.8, width: 0.4},
            {type: 'ring', cx: 2, cy: 3, r: 1.2, width: 0.4},
            {type: 'rect', cx: 2, cy: 3, width: 5, height: 0.1, r: 0},
            {type: 'rect', cx: 2, cy: 3, width: 0.1, height: 5, r: 0}
          ])
          expect(p._tool.box).to.eql([-0.5, 0.5, 4.5, 5.5])
        })

        it('should handle moirés with circle centers', function() {
          var blocks = [{
            type: 'moire',
            exp: 1,
            cx: 5,
            cy: 5,
            dia: 2.8,
            ringThx: 0.5,
            ringGap: 0.5,
            maxRings: 2,
            crossThx: 0.2,
            crossLen: 2.5,
            rot: 0
          }]
          var macro = {cmd: 'macro', key: 'TARG', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'TARG', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([
            {type: 'ring', cx: 5, cy: 5, r: 1.15, width: 0.5},
            {type: 'circle', cx: 5, cy: 5, r: 0.4},
            {type: 'rect', cx: 5, cy: 5, width: 2.5, height: 0.2, r: 0},
            {type: 'rect', cx: 5, cy: 5, width: 0.2, height: 2.5, r: 0}
          ])
          expect(p._tool.box).to.eql([3.6, 3.6, 6.4, 6.4])
        })

        it('should handle thermals', function() {
          var blocks = [{
            type: 'thermal',
            exp: 1,
            cx: 1,
            cy: 1,
            outerDia: 7,
            innerDia: 5,
            gap: 1,
            rot: 0
          }]
          var macro = {cmd: 'macro', key: 'THRM', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'THRM', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([
            {
              type: 'clip',
              shape: [
                {type: 'rect', cx: 3, cy: 3, width: 3, height: 3, r: 0},
                {type: 'rect', cx: -1, cy: 3, width: 3, height: 3, r: 0},
                {type: 'rect', cx: -1, cy: -1, width: 3, height: 3, r: 0},
                {type: 'rect', cx: 3, cy: -1, width: 3, height: 3, r: 0}
              ],
              clip: {type: 'ring', cx: 1, cy: 1, r: 3, width: 1}
            }
          ])
          expect(p._tool.box).to.eql([-2.5, -2.5, 4.5, 4.5])
        })
      })

      describe('rotated primitives', function() {
        it('should handle rotated circles', function() {
          var blocks = [{type: 'circle', exp: 1, dia: 4, cx: 0, cy: 4, rot: 90}]
          var macro = {cmd: 'macro', key: 'RCIRC', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'RCIRC', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([{type: 'circle', cx: -4, cy: 0, r: 2}])
          expect(p._tool.box).to.eql([-6, -2, -2, 2])
        })

        it('should handle rotated vects', function() {
          var blocks = [
            {type: 'vect', exp: 1, width: 1, x1: 1, y1: 1, x2: 5, y2: 5, rot: 45}
          ]
          var macro = {cmd: 'macro', key: 'RVECT', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'RVECT', val: [], hole: []}}

          p.write(macro)
          p.write(tool)

          expect(p._tool.pad).to.eql([
            {
              type: 'poly',
              points: [
                [0.5, 1.41421356],
                [0.5, 7.07106781],
                [-0.5, 7.07106781],
                [-0.5, 1.41421356]
              ]
            }
          ])
          expect(p._tool.box).to.eql([-0.5, 1.41421356, 0.5, 7.07106781])
        })

        it('should handle rotated rects', function() {
          var blocks = [
            {type: 'rect', exp: 1, width: 4, height: 2, cx: 3, cy: 4, rot: -30}
          ]
          var macro = {cmd: 'macro', key: 'RRECT', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'RRECT', val: [], hole: []}}

          p.write(macro)
          p.write(tool)

          expect(p._tool.pad).to.eql([
            {
              type: 'poly',
              points: [
                [2.36602540, 2.09807622],
                [5.83012702, 0.09807622],
                [6.83012702, 1.83012702],
                [3.36602540, 3.83012702]
              ]
            }
          ])
          expect(p._tool.box).to.eql([2.36602540, 0.09807622, 6.83012702, 3.83012702])
        })

        it('should handle rotated lower-left rects', function() {
          var blocks = [
            {type: 'rectLL', exp: 1, width: 4, height: 2, x: 1, y: 3, rot: -30}
          ]
          var macro = {cmd: 'macro', key: 'LRECT', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'LRECT', val: [], hole: []}}

          p.write(macro)
          p.write(tool)

          expect(p._tool.pad).to.eql([
            {
              type: 'poly',
              points: [
                [2.36602540, 2.09807622],
                [5.83012702, 0.09807622],
                [6.83012702, 1.83012702],
                [3.36602540, 3.83012702]
              ]
            }
          ])
          expect(p._tool.box).to.eql([2.36602540, 0.09807622, 6.83012702, 3.83012702])
        })

        it('should handle rotated outline polygons', function() {
          var blocks = [
            {type: 'outline', exp: 1, points: [0, 0, 1, 0, 1, 1, 0, 0], rot: 150}
          ]
          var macro = {cmd: 'macro', key: 'LRECT', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'LRECT', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([{
            type: 'poly',
            points: [[0, 0], [-0.86602540, 0.5], [-1.36602540, -0.36602540]]
          }])
          expect(p._tool.box).to.eql([-1.36602540, -0.36602540, 0, 0.5])
        })

        it('should handle rotated regular polygons', function() {
          var dia = 2 * Math.sqrt(2)
          var blocks = [
            {type: 'poly', exp: 1, vertices: 4, cx: 0, cy: 0, dia: dia, rot: 45}
          ]
          var macro = {cmd: 'macro', key: 'POLY', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'POLY', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([{
            type: 'poly',
            points: [[1, 1], [-1, 1], [-1, -1], [1, -1]]
          }])
          expect(p._tool.box).to.eql([-1, -1, 1, 1])
        })

        it('should handle rotated moires', function() {
          var blocks = [{
            type: 'moire',
            exp: 1,
            cx: 0,
            cy: 0,
            dia: 4,
            ringThx: 0.4,
            ringGap: 0.2,
            maxRings: 2,
            crossThx: 0.1,
            crossLen: 5,
            rot: -150
          }]
          var macro = {cmd: 'macro', key: 'TARG', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'TARG', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([
            {type: 'ring', cx: 0, cy: 0, r: 1.8, width: 0.4},
            {type: 'ring', cx: 0, cy: 0, r: 1.2, width: 0.4},
            {type: 'poly', points: [
              [2.19006351, 1.20669873],
              [-2.14006351, -1.29330127],
              [-2.19006351, -1.20669873],
              [2.14006351, 1.29330127]
            ]},
            {type: 'poly', points: [
              [1.29330127, -2.14006351],
              [1.20669873, -2.19006351],
              [-1.29330127, 2.14006351],
              [-1.20669873, 2.19006351]
            ]}
          ])
          expect(p._tool.box).to.eql(
            [-2.19006351, -2.19006351, 2.19006351, 2.19006351])
        })

        it('should handle rotated thermals', function() {
          var blocks = [{
            type: 'thermal',
            exp: 1,
            cx: 0,
            cy: 0,
            outerDia: 4,
            innerDia: 3,
            gap: 0.2,
            rot: 45
          }]
          var macro = {cmd: 'macro', key: 'THRM', val: blocks}
          var tool = {cmd: 'tool', key: '10', val: {shape: 'THRM', val: [], hole: []}}

          p.write(macro)
          p.write(tool)
          expect(p._tool.pad).to.eql([
            {
              type: 'clip',
              shape: [
                {type: 'poly', points: [
                  [0, 0.14142136],
                  [1.34350288, 1.48492424],
                  [0, 2.82842712],
                  [-1.34350288, 1.48492424]
                ]},
                {type: 'poly', points: [
                  [-1.48492424, -1.34350288],
                  [-0.14142136, 0],
                  [-1.48492424, 1.34350288],
                  [-2.82842712, 0]
                ]},
                {type: 'poly', points: [
                  [0, -2.82842712],
                  [1.34350288, -1.48492424],
                  [0, -0.14142136],
                  [-1.34350288, -1.48492424]
                ]},
                {type: 'poly', points: [
                  [1.48492424, -1.34350288],
                  [2.82842712, 0],
                  [1.48492424, 1.34350288],
                  [0.14142136, 0]
                ]}
              ],
              clip: {type: 'ring', cx: 0, cy: 0, r: 1.75, width: 0.5}
            }
          ])
          expect(p._tool.box).to.eql([-2, -2, 2, 2])
        })
      })

      it('should handle modifiers and functional args', function() {
        var blocks = [{
          type: 'circle',
          exp: 1,
          dia: function(mods) {return mods.$1},
          cx: function(mods) {return mods.$2},
          cy: function(mods) {return mods.$3},
          rot: function(mods) {return mods.$4}
        }]
        var mods = [4, 3, 2, 0]
        var macro = {cmd: 'macro', key: 'CIRC', val: blocks}
        var tool = {cmd: 'tool', key: '10', val: {shape: 'CIRC', val: mods, hole: []}}

        p.write(macro)
        p.write(tool)
        expect(p._tool.pad).to.eql([{type: 'circle', cx: 3, cy: 2, r: 2}])
      })

      it('should handle variable sets', function() {
        var blocks = [
          {
            type: 'variable',
            set: function(mods) {
              return {$1: 4, $2: 3, $3: mods.$2 - 1}
            }
          },
          {
            type: 'circle',
            exp: 1,
            dia: function(mods) {return mods.$1},
            cx: function(mods) {return mods.$2},
            cy: function(mods) {return mods.$3},
            rot: 0
          }
        ]
        var mods = [4, 3]
        var macro = {cmd: 'macro', key: 'CIRC', val: blocks}
        var tool = {cmd: 'tool', key: '10', val: {shape: 'CIRC', val: mods, hole: []}}

        p.write(macro)
        p.write(tool)
        expect(p._tool.pad).to.eql([{type: 'circle', cx: 3, cy: 2, r: 2}])
      })

      it('should handle multiple primitives and exposure', function() {
        var blocks = [
          {type: 'circle', exp: 1, dia: 4, cx: -2, cy: 0, rot: 0},
          {type: 'rect', exp: 0, width: 1, height: 1, cx: -1, cy: 0, rot: 0},
          {type: 'rect', exp: 0, width: 1, height: 1, cx: 1, cy: 0, rot: 0},
          {type: 'circle', exp: 1, dia: 4, cx: 2, cy: 0, rot: 0}
        ]
        var macro = {cmd: 'macro', key: 'MAC', val: blocks}
        var tool = {cmd: 'tool', key: '10', val: {shape: 'MAC', val: [], hole: []}}

        p.write(macro)
        p.write(tool)
        expect(p._tool.pad).to.eql([
          {type: 'circle', cx: -2, cy: 0, r: 2},
          {type: 'layer', polarity: 'clear', box: [-4, -2, 0, 2]},
          {type: 'rect', width: 1, height: 1, cx: -1, cy: 0, r: 0},
          {type: 'rect', width: 1, height: 1, cx: 1, cy: 0, r: 0},
          {type: 'layer', polarity: 'dark', box: [-4, -2, 0, 2]},
          {type: 'circle', cx: 2, cy: 0, r: 2}
        ])
        expect(p._tool.box).to.eql([-4, -2, 4, 2])
      })
    })
  })

  describe('handling operation commands', function() {
    beforeEach(function() {
      var tool = {shape: 'circle', val: [2], hole: []}
      p.write({cmd: 'set', key: 'epsilon', val: 0.00000001})
      p.write({cmd: 'set', key: 'units', val: 'in'})
      p.write({cmd: 'set', key: 'nota', val: 'A'})
      p.write({cmd: 'set', key: 'mode', val: 'i'})
      p.write({cmd: 'tool', key: '10', val: tool})
    })

    it('should move the plotter', function() {
      p.write({cmd: 'op', key: 'int', val: {x: 4, y: -3}})
      expect(p._pos).to.eql([4, -3])
      p.write({cmd: 'op', key: 'move', val: {y: 0}})
      expect(p._pos).to.eql([4, 0])
      p.write({cmd: 'op', key: 'flash', val: {x: -7}})
      expect(p._pos).to.eql([-7, 0])
    })

    it('should move the plotter with incremental notation', function() {
      p.nota = 'I'
      p.write({cmd: 'op', key: 'int', val: {x: 4, y: -3, i: 1, j: 4}})
      expect(p._pos).to.eql([4, -3])
      p.write({cmd: 'op', key: 'move', val: {y: 1}})
      expect(p._pos).to.eql([4, -2])
      p.write({cmd: 'op', key: 'flash', val: {x: -7}})
      expect(p._pos).to.eql([-3, -2])
    })

    describe('flashing pads', function() {
      it('should emit a shape if first flash for tool', function(done) {
        p.once('readable', function() {
          var result = p.read()
          expect(result).to.eql({
            type: 'shape',
            tool: '10',
            shape: p._tool.pad
          })
          done()
        })
        p.write({cmd: 'op', key: 'flash', val: {x: 1, y: 1}})
      })

      it('should emit pad objects after the shape object', function(done) {
        p.once('data', function(result) {
          expect(result.type).to.equal('shape')
          p.once('data', function(result) {
            expect(result).to.eql({type: 'pad', tool: '10', x: 1, y: 1})
            done()
          })
        })
        p.write({cmd: 'op', key: 'flash', val: {x: 1, y: 1}})
      })

      it('should not emit the pad shape more than once', function(done) {
        var results = 0
        var expected = ['shape', 'pad', 'pad']
        var handleData = function(data) {
          expect(data.type).to.eql(expected[results])
          if (++results >= expected.length) {
            p.removeListener('data', handleData)
            return done()
          }
        }

        p.on('data', handleData)
        p.write({cmd: 'op', key: 'flash', val: {x: 1, y: 1}})
        p.write({cmd: 'op', key: 'flash', val: {x: 5, y: 5}})
      })

      it('should update the bounding box', function() {
        p.write({cmd: 'op', key: 'flash', val: {x: 1, y: 1}})
        expect(p._box).to.eql([0, 0, 2, 2])
      })
    })

    describe('interpolating to create strokes', function() {
      it('should create a path graph with linear strokes', function() {
        p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1}})
        p.write({cmd: 'op', key: 'int', val: {x: 1, y: 3}})
        p.write({cmd: 'op', key: 'int', val: {x: 3, y: 3}})

        expect(p._path.traverse()).to.eql([
          {type: 'line', start: [0, 0], end: [1, 1]},
          {type: 'line', start: [1, 1], end: [1, 3]},
          {type: 'line', start: [1, 3], end: [3, 3]}
        ])
      })

      it('should handle moves in between strokes', function() {
        p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1}})
        p.write({cmd: 'op', key: 'move', val: {x: 1, y: 3}})
        p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1}})
        p.write({cmd: 'op', key: 'move', val: {x: 3, y: 3}})
        p.write({cmd: 'op', key: 'int', val: {x: 1, y: 3}})

        expect(p._path.traverse()).to.eql([
          {type: 'line', start: [0, 0], end: [1, 1]},
          {type: 'line', start: [1, 1], end: [1, 3]},
          {type: 'line', start: [1, 3], end: [3, 3]}
        ])
      })

      it('should update the box in non-region mode', function() {
        p.write({cmd: 'op', key: 'int', val: {x: 1, y: 3}})
        p.write({cmd: 'op', key: 'int', val: {x: 3, y: 3}})
        p.write({cmd: 'op', key: 'int', val: {x: 0, y: 0}})

        expect(p._box).to.eql([-1, -1, 4, 4])
      })

      it('should update the bounding box in region mode', function() {
        p.write({cmd: 'set', key: 'region', val: true})
        p.write({cmd: 'op', key: 'int', val: {x: 1, y: 3}})
        p.write({cmd: 'op', key: 'int', val: {x: 3, y: 3}})
        p.write({cmd: 'op', key: 'int', val: {x: 0, y: 0}})

        expect(p._box).to.eql([0, 0, 3, 3])
      })

      describe('arc strokes', function() {
        it('should determine the center and radius in single quadrant mode', function() {
          p.write({cmd: 'set', key: 'arc', val: 's'})
          p.write({cmd: 'set', key: 'mode', val: 'cw'})
          p.write({cmd: 'op', key: 'int', val: {x: 2, y: 0, i: 1, j: 1.5}})
          p.write({cmd: 'set', key: 'mode', val: 'ccw'})
          p.write({cmd: 'op', key: 'int', val: {x: 4, y: 0, i: 1, j: 1.5}})
          p.write({cmd: 'set', key: 'mode', val: 'cw'})
          p.write({cmd: 'op', key: 'int', val: {x: 4, y: -2, i: 1.5, j: 1}})
          p.write({cmd: 'set', key: 'mode', val: 'ccw'})
          p.write({cmd: 'op', key: 'int', val: {x: 4, y: 0, i: 1.5, j: 1}})

          var R = Math.sqrt(Math.pow(1.5, 2) + 1)
          expect(p._path.traverse()).to.eql([
            {
              type: 'arc',
              start: [0, 0, 2.158798930342464],
              end: [2, 0, 0.982793723247329],
              center: [1, -1.5],
              sweep: 1.1760052070951348,
              radius: R,
              dir: 'cw'
            },
            {
              type: 'arc',
              start: [2, 0, 4.124386376837123],
              end: [4, 0, 5.3003915839322575],
              center: [3, 1.5],
              sweep: 1.1760052070951348,
              radius: R,
              dir: 'ccw'
            },
            {
              type: 'arc',
              start: [4, 0, 0.5880026035475675],
              end: [4, -2, 5.695182703632018],
              center: [2.5, -1],
              sweep: 1.176005207095135,
              radius: R,
              dir: 'cw'
            },
            {
              type: 'arc',
              start: [4, -2, 5.695182703632018],
              end: [4, 0, 0.5880026035475675],
              center: [2.5, -1],
              sweep: 1.176005207095135,
              radius: R,
              dir: 'ccw'
            }
          ])
        })

        it('should use the actual offsets to get the center in multi-quadrant mode', function() {
          p.write({cmd: 'set', key: 'arc', val: 'm'})
          p.write({cmd: 'set', key: 'mode', val: 'cw'})
          p.write({cmd: 'op', key: 'int', val: {x: 2, y: 0, i: 1, j: -1.5}})
          p.write({cmd: 'set', key: 'mode', val: 'ccw'})
          p.write({cmd: 'op', key: 'int', val: {x: 4, y: 0, i: 1, j: 1.5}})

          var R = Math.sqrt(Math.pow(1.5, 2) + 1)
          expect(p._path.traverse()).to.eql([
            {
              type: 'arc',
              start: [0, 0, 2.158798930342464],
              end: [2, 0, 0.982793723247329],
              center: [1, -1.5],
              sweep: 1.1760052070951348,
              radius: R,
              dir: 'cw'
            },
            {
              type: 'arc',
              start: [2, 0, 4.124386376837123],
              end: [4, 0, 5.3003915839322575],
              center: [3, 1.5],
              sweep: 1.1760052070951348,
              radius: R,
              dir: 'ccw'
            }
          ])
        })

        it('should set the sweep to zero for matching start and end in single mode', function() {
          p.write({cmd: 'set', key: 'arc', val: 's'})
          p.write({cmd: 'set', key: 'mode', val: 'cw'})
          p.write({cmd: 'op', key: 'int', val: {x: 0, y: 0, i: 1}})

          expect(p._path.traverse()).to.eql([
            {
              type: 'arc',
              start: [0, 0, 0],
              end: [0, 0, 0],
              center: [-1, 0],
              sweep: 0,
              radius: 1,
              dir: 'cw'
            }
          ])
        })

        it('should set the sweep to a full circle in multi mode', function() {
          p.write({cmd: 'set', key: 'arc', val: 'm'})
          p.write({cmd: 'set', key: 'mode', val: 'cw'})
          p.write({cmd: 'op', key: 'int', val: {x: 0, y: 0, i: -1}})

          expect(p._path.traverse()).to.eql([
            {
              type: 'arc',
              start: [0, 0, 0],
              end: [0, 0, 0],
              center: [-1, 0],
              sweep: 2 * Math.PI,
              radius: 1,
              dir: 'cw'
            }
          ])
        })

        it('should warn and not add to path if arc is impossible', function(done) {
          p.once('warning', function(w) {
            expect(w.message).to.match(/impossible arc/)
            expect(w.line).to.equal(12)

            setTimeout(function() {
              expect(p._path.length).to.equal(0)
              done()
            }, 5)
          })

          p.write({cmd: 'set', key: 'arc', val: 's'})
          p.write({cmd: 'set', key: 'mode', val: 'ccw'})
          p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1, i: 1}, line: 12})
        })

        it('should warn and not add to path if tool is not circular', function(done) {
          p.once('warning', function(w) {
            expect(w.message).to.match(/arc.*circular/)
            setTimeout(function() {
              expect(p._path.length).to.equal(0)
              done()
            }, 5)
          })

          var rectTool = {shape: 'rect', val: [2, 1], hole: []}
          p.write({cmd: 'tool', key: '11', val: rectTool})
          p.write({cmd: 'set', key: 'arc', val: 's'})
          p.write({cmd: 'set', key: 'mode', val: 'cw'})
          p.write({cmd: 'op', key: 'int', val: {x: 2, y: 0, i: 1, j: 1.5}})
        })

        it('should allow non-circular tools if in region mode', function() {
          var rectTool = {shape: 'rect', val: [2, 1], hole: []}
          p.write({cmd: 'tool', key: '11', val: rectTool})
          p.write({cmd: 'set', key: 'arc', val: 's'})
          p.write({cmd: 'set', key: 'mode', val: 'cw'})
          p.write({cmd: 'set', key: 'region', val: true})
          p.write({cmd: 'op', key: 'int', val: {x: 2, y: 0, i: 1, j: 1.5}})
          expect(p._path.length).to.equal(1)
        })

        describe('bounding box', function() {
          it('should usually use the arc end points', function() {
            p.write({cmd: 'op', key: 'move', val: {x: 0.5, y: 0.866}})
            p.write({cmd: 'set', key: 'mode', val: 'cw'})
            p.write({cmd: 'set', key: 'arc', val: 's'})
            p.write({cmd: 'op', key: 'int', val: {x: 0.866, y: 0.5, i: 0.5, j: 0.866}})
            expect(p._box).to.eql([-0.5, -0.5, 1.8660, 1.8660])

            p._box = boundingBox.new()
            p.write({cmd: 'set', key: 'region', val: true})
            p.write({cmd: 'op', key: 'move', val: {x: 0.5, y: 0.866}})
            p.write({cmd: 'op', key: 'int', val: {x: 0.866, y: 0.5, i: 0.5, j: 0.866}})
            expect(p._box).to.eql([0.5, 0.5, 0.8660, 0.8660])
          })

          it('should should set the min x when arc sweeps past 180 deg', function() {
            p.write({cmd: 'op', key: 'move', val: {x: -0.7071, y: -0.7071}})
            p.write({cmd: 'set', key: 'mode', val: 'cw'})
            p.write({cmd: 'set', key: 'arc', val: 's'})
            p.write({cmd: 'op', key: 'int', val: {x: -0.7071, y: 0.7071, i: 0.7071, j: 0.7071}})
            expect(p._box[0]).to.be.closeTo(-2, 0.00001)

            p._box = boundingBox.new()
            p.write({cmd: 'set', key: 'region', val: true})
            p.write({cmd: 'op', key: 'move', val: {x: -0.7071, y: -0.7071}})
            p.write({cmd: 'op', key: 'int', val: {x: -0.7071, y: 0.7071, i: 0.7071, j: 0.7071}})
            expect(p._box[0]).to.be.closeTo(-1, 0.00001)
          })

          it('should should set the min y when arc sweeps past 270 deg', function() {
            p.write({cmd: 'op', key: 'move', val: {x: -0.7071, y: -0.7071}})
            p.write({cmd: 'set', key: 'mode', val: 'ccw'})
            p.write({cmd: 'set', key: 'arc', val: 's'})
            p.write({cmd: 'op', key: 'int', val: {x: 0.7071, y: -0.7071, i: 0.7071, j: 0.7071}})
            expect(p._box[1]).to.be.closeTo(-2, 0.00001)

            p._box = boundingBox.new()
            p.write({cmd: 'set', key: 'region', val: true})
            p.write({cmd: 'op', key: 'move', val: {x: -0.7071, y: -0.7071}})
            p.write({cmd: 'op', key: 'int', val: {x: 0.7071, y: -0.7071, i: 0.7071, j: 0.7071}})
            expect(p._box[1]).to.be.closeTo(-1, 0.00001)
          })

          it('should should set the max x when arc sweeps past 0 deg', function() {
            p.write({cmd: 'op', key: 'move', val: {x: 0.7071, y: -0.7071}})
            p.write({cmd: 'set', key: 'mode', val: 'ccw'})
            p.write({cmd: 'set', key: 'arc', val: 's'})
            p.write({cmd: 'op', key: 'int', val: {x: 0.7071, y: 0.7071, i: 0.7071, j: 0.7071}})
            expect(p._box[2]).to.be.closeTo(2, 0.00001)

            p._box = boundingBox.new()
            p.write({cmd: 'set', key: 'region', val: true})
            p.write({cmd: 'op', key: 'move', val: {x: 0.7071, y: -0.7071}})
            p.write({cmd: 'op', key: 'int', val: {x: 0.7071, y: 0.7071, i: 0.7071, j: 0.7071}})
            expect(p._box[2]).to.be.closeTo(1, 0.00001)
          })

          it('should should set the max y when arc sweeps past 90 deg', function() {
            p.write({cmd: 'op', key: 'move', val: {x: -0.7071, y: 0.7071}})
            p.write({cmd: 'set', key: 'mode', val: 'cw'})
            p.write({cmd: 'set', key: 'arc', val: 's'})
            p.write({cmd: 'op', key: 'int', val: {x: 0.7071, y: 0.7071, i: 0.7071, j: 0.7071}})
            expect(p._box[3]).to.be.closeTo(2, 0.00001)

            p._box = boundingBox.new()
            p.write({cmd: 'set', key: 'region', val: true})
            p.write({cmd: 'op', key: 'move', val: {x: -0.7071, y: 0.7071}})
            p.write({cmd: 'op', key: 'int', val: {x: 0.7071, y: 0.7071, i: 0.7071, j: 0.7071}})
            expect(p._box[3]).to.be.closeTo(1, 0.00001)
          })

          it('should set the box properly for a full circle', function() {
            p.write({cmd: 'set', key: 'mode', val: 'cw'})
            p.write({cmd: 'set', key: 'arc', val: 'm'})
            p.write({cmd: 'op', key: 'int', val: {x: 0, y: 0, i: -1, j: 0}})
            expect(p._box).to.eql([-3, -2, 1, 2])

            p._box = boundingBox.new()
            p.write({cmd: 'set', key: 'region', val: true})
            p.write({cmd: 'op', key: 'int', val: {x: 0, y: 0, i: 0, j: 1}})
            expect(p._box).to.eql([-1, 0, 1, 2])
          })
        })
      })
    })

    describe('interpolating with rectangular tools', function() {
      beforeEach(function() {
        var rectTool = {shape: 'rect', val: [2, 1], hole: []}
        p.write({cmd: 'tool', key: '11', val: rectTool})
      })

      it('should directly emit fills without adding to the path for rect tools', function(done) {
        var path = [
          {type: 'line', start: [-1, -0.5], end: [1, -0.5]},
          {type: 'line', start: [1, -0.5], end: [1, 0.5]},
          {type: 'line', start: [1, 0.5], end: [-1, 0.5]},
          {type: 'line', start: [-1, 0.5], end: [-1, -0.5]}
        ]

        p.once('readable', function() {
          var result = p.read()
          expect(p._path.length).to.equal(0)
          expect(result).to.eql({type: 'fill', path: path})

          setTimeout(function() {
            expect(p._box).to.eql([-1, -0.5, 1, 0.5])
            done()
          }, 1)
        })

        p.write({cmd: 'op', key: 'int', val: {x: 0, y: 0}})
      })

      it('should handle a first quadrant move', function(done) {
        var path = [
          {type: 'line', start: [-1, -0.5], end: [1, -0.5]},
          {type: 'line', start: [1, -0.5], end: [6, 4.5]},
          {type: 'line', start: [6, 4.5], end: [6, 5.5]},
          {type: 'line', start: [6, 5.5], end: [4, 5.5]},
          {type: 'line', start: [4, 5.5], end: [-1, 0.5]},
          {type: 'line', start: [-1, 0.5], end: [-1, -0.5]}
        ]

        p.once('readable', function() {
          var result = p.read()
          expect(p._path.length).to.equal(0)
          expect(result).to.eql({type: 'fill', path: path})

          setTimeout(function() {
            expect(p._box).to.eql([-1, -0.5, 6, 5.5])
            done()
          }, 1)
        })

        p.write({cmd: 'op', key: 'int', val: {x: 5, y: 5}})
      })

      it('should handle a second quadrant move', function(done) {
        var path = [
          {type: 'line', start: [1, -0.5], end: [1, 0.5]},
          {type: 'line', start: [1, 0.5], end: [-4, 5.5]},
          {type: 'line', start: [-4, 5.5], end: [-6, 5.5]},
          {type: 'line', start: [-6, 5.5], end: [-6, 4.5]},
          {type: 'line', start: [-6, 4.5], end: [-1, -0.5]},
          {type: 'line', start: [-1, -0.5], end: [1, -0.5]}
        ]

        p.once('readable', function() {
          var result = p.read()
          expect(p._path.length).to.equal(0)
          expect(result).to.eql({type: 'fill', path: path})

          setTimeout(function() {
            expect(p._box).to.eql([-6, -0.5, 1, 5.5])
            done()
          }, 1)
        })

        p.write({cmd: 'op', key: 'int', val: {x: -5, y: 5}})
      })

      it('should handle a third quadrant move', function(done) {
        var path = [
          {type: 'line', start: [1, 0.5], end: [-1, 0.5]},
          {type: 'line', start: [-1, 0.5], end: [-6, -4.5]},
          {type: 'line', start: [-6, -4.5], end: [-6, -5.5]},
          {type: 'line', start: [-6, -5.5], end: [-4, -5.5]},
          {type: 'line', start: [-4, -5.5], end: [1, -0.5]},
          {type: 'line', start: [1, -0.5], end: [1, 0.5]}
        ]

        p.once('readable', function() {
          var result = p.read()
          expect(p._path.length).to.equal(0)
          expect(result).to.eql({type: 'fill', path: path})

          setTimeout(function() {
            expect(p._box).to.eql([-6, -5.5, 1, 0.5])
            done()
          }, 1)
        })

        p.write({cmd: 'op', key: 'int', val: {x: -5, y: -5}})
      })

      it('should handle a fourth quadrant move', function(done) {
        var path = [
          {type: 'line', start: [-1, 0.5], end: [-1, -0.5]},
          {type: 'line', start: [-1, -0.5], end: [4, -5.5]},
          {type: 'line', start: [4, -5.5], end: [6, -5.5]},
          {type: 'line', start: [6, -5.5], end: [6, -4.5]},
          {type: 'line', start: [6, -4.5], end: [1, 0.5]},
          {type: 'line', start: [1, 0.5], end: [-1, 0.5]}
        ]

        p.once('readable', function() {
          var result = p.read()
          expect(p._path.length).to.equal(0)
          expect(result).to.eql({type: 'fill', path: path})

          setTimeout(function() {
            expect(p._box).to.eql([-1, -5.5, 6, 0.5])
            done()
          }, 1)
        })

        p.write({cmd: 'op', key: 'int', val: {x: 5, y: -5}})
      })

      it('should do a normal stroke if region mode is on', function(done) {
        p._region = true
        p.write({cmd: 'op', key: 'int', val: {x: 5, y: 5}})

        setTimeout(function() {
          expect(p._path.traverse()).to.eql([{type: 'line', start: [0, 0], end: [5, 5]}])
          done()
        }, 10)
      })
    })

    it('should allow but warn about modal operation codes', function(done) {
      p.once('warning', function(w) {
        expect(w.message).to.match(/modal operation/)
        setTimeout(function() {
          expect(p._path.length).to.equal(2)
          done()
        }, 5)
      })

      p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1}})
      p.write({cmd: 'op', key: 'last', val: {x: 2, y: 2}})
    })
  })

  describe('operation warnings', function() {
    beforeEach(function() {
      var tool = {shape: 'circle', val: [2], hole: []}
      p.write({cmd: 'set', key: 'epsilon', val: 0.00000001})
      p.write({cmd: 'tool', key: '10', val: tool})
    })

    it('should warn and use backup units if the units are not set', function(done) {
      p.once('warning', function(w) {
        expect(w.message).to.match(/backup units/)
        done()
      })

      p.write({cmd: 'set', key: 'nota', val: 'A'})
      p.write({cmd: 'set', key: 'mode', val: 'i'})
      p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1}})
    })

    it('should warn and use backup notation if the notation is not set', function(done) {
      p.once('warning', function(w) {
        expect(w.message).to.match(/backup notation/)
        done()
      })

      p.write({cmd: 'set', key: 'units', val: 'in'})
      p.write({cmd: 'set', key: 'mode', val: 'i'})
      p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1}})
    })

    it('should warn if a tool is flashed in region mode', function(done) {
      p.once('warning', function(w) {
        expect(w.message).to.match(/flash in region/)
        done()
      })

      p.write({cmd: 'set', key: 'units', val: 'in'})
      p.write({cmd: 'set', key: 'nota', val: 'A'})
      p.write({cmd: 'set', key: 'region', val: 'true'})
      p.write({cmd: 'op', key: 'flash', val: {x: 1, y: 1}})
    })

    it('should warn and ignore interpolates with unstrokable tools', function(done) {
      var tool = {shape: 'circle', val: [2], hole: [1]}

      p.once('warning', function(w) {
        expect(w.message).to.match(/not strokable/)

        setTimeout(function() {
          expect(p._path.length).to.equal(0)
          done()
        }, 5)
      })

      p.write({cmd: 'tool', key: '11', val: tool})
      p.write({cmd: 'set', key: 'units', val: 'in'})
      p.write({cmd: 'set', key: 'nota', val: 'A'})
      p.write({cmd: 'set', key: 'mode', val: 'i'})
      p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1}})
    })

    it('should warn and assume linear interpolation mode if unspecified', function(done) {
      p.once('warning', function(w) {
        expect(w.message).to.match(/no interpolation.*linear/)
        setTimeout(function() {
          expect(p._path.length).to.equal(1)
          done()
        }, 5)
      })

      p.write({cmd: 'set', key: 'units', val: 'in'})
      p.write({cmd: 'set', key: 'nota', val: 'A'})
      p.write({cmd: 'op', key: 'int', val: {x: 1, y: 1}})
    })

    it('should warn and assume single-quadrant mode if unspecified', function(done) {
      p.on('warning', function(w) {
        expect(w.message).to.match(/assuming single quadrant/)
        setTimeout(function() {
          expect(p._arc).to.equal('s')
          expect(p._path.length).to.equal(1)
          done()
        }, 5)
      })

      p.write({cmd: 'set', key: 'units', val: 'in'})
      p.write({cmd: 'set', key: 'nota', val: 'A'})
      p.write({cmd: 'set', key: 'mode', val: 'cw'})
      p.write({cmd: 'op', key: 'int', val: {x: 2, y: 0, i: 1, j: 1.5}})
    })
  })

  describe('emitting strokes and regions', function() {
    var path = [
      {type: 'line', start: [0, 0], end: [1, 0]},
      {type: 'line', start: [1, 0], end: [1, 1]},
      {type: 'line', start: [1, 1], end: [0, 1]},
      {type: 'line', start: [0, 1], end: [0, 0]}
    ]

    beforeEach(function() {
      var tool0 = {shape: 'circle', val: [0.2], hole: []}
      var tool1 = {shape: 'circle', val: [0.4], hole: []}
      p.write({cmd: 'tool', key: '11', val: tool1})
      p.write({cmd: 'tool', key: '10', val: tool0})
      forEach(path, p._path.add, p._path)
    })

    it('should end the path on a tool change', function(done) {
      p.once('data', function() {
        expect(p._path.length).to.equal(0)
        done()
      })

      p.write({cmd: 'set', key: 'tool', val: '10'})
    })

    it('should end the path on a tool definition', function(done) {
      var tool = {shape: 'circle', val: [0.1], hole: []}

      p.once('data', function() {
        expect(p._path.length).to.equal(0)
        done()
      })

      p.write({cmd: 'tool', key: '12', val: tool})
    })

    it('should end the path on a region change', function(done) {
      p.once('data', function() {
        expect(p._path.length).to.equal(0)
        done()
      })

      p.write({cmd: 'set', key: 'region', val: true})
    })

    it('should end the path on a polarity change', function(done) {
      p.once('data', function() {
        expect(p._path.length).to.equal(0)
        done()
      })

      p.write({cmd: 'level', key: 'polarity', val: 'C'})
    })

    it('should end the path on a step repeat', function(done) {
      p.once('data', function() {
        expect(p._path.length).to.equal(0)
        done()
      })

      p.write({cmd: 'level', key: 'stepRep', val:	{x: 5, y: 5, i: 2, j: 2}})
    })

    it('should end the path on stream end', function(done) {
      p.once('data', function() {
        expect(p._path.length).to.equal(0)
        done()
      })

      p.end()
    })

    it('should emit a stroke if region mode it off', function(done) {
      var expected = {
        type: 'stroke',
        width: 0.2,
        path: path
      }

      p.once('readable', function() {
        var data = p.read()
        expect(data).to.eql(expected)
        done()
      })

      p._finishPath()
    })

    it('should emit a fill if region mode is on', function(done) {
      var expected = {type: 'fill', path: path}

      p.once('readable', function() {
        var data = p.read()
        expect(data).to.eql(expected)
        done()
      })

      p._region = true
      p._finishPath()
    })
  })

  describe('emitting new layers', function() {
    it('should push a polarity change with the current bounding box', function(done) {
      var results = 0
      var expected = [
        {type: 'polarity', polarity: 'clear', box: [0, 0, 10, 10]},
        {type: 'polarity', polarity: 'dark', box: [0, 0, 10, 10]}
      ]

      var handleData = function(data) {
        expect(data).to.eql(expected[results])
        if (++results >= expected.length) {
          p.removeListener('data', handleData)
          return done()
        }
      }

      p.on('data', handleData)
      p._box = [0, 0, 10, 10]
      p.write({cmd: 'level', key: 'polarity', val: 'C'})
      p.write({cmd: 'level', key: 'polarity', val: 'D'})
    })

    it('should push a step repeat with the current bounding box', function(done) {
      p.once('readable', function() {
        var result = p.read()
        expect(result).to.eql({
          type: 'repeat',
          offsets: [[0, 0], [0, 2.2], [0, 4.4], [3.3, 0], [3.3, 2.2], [3.3, 4.4]],
          box: [0, 0, 10, 10]
        })
        done()
      })

      p._box = [0, 0, 10, 10]
      p.write({cmd: 'level', key: 'stepRep', val: {x: 2, y: 3, i: 3.3, j: 2.2}})
    })

    it('should update the box during a step repeat', function() {
      var tool = {shape: 'circle', val: [2], hole: []}
      p.write({cmd: 'tool', key: '10', val: tool})
      p.write({cmd: 'level', key: 'stepRep', val: {x: 2, y: 2, i: 3.5, j: -3}})
      p.write({cmd: 'op', key: 'flash', val: {x: -3, y: 4}})
      expect(p._box).to.eql([-4, 0, 1.5, 5])
    })
  })

  describe('ending the stream', function() {
    it('should push a size object after the stream ends', function(done) {
      p.once('readable', function() {
        var result = p.read()
        expect(result).to.eql({type: 'size', box: [1, 2, 3, 4], units: 'in'})
        done()
      })

      p._box = [1, 2, 3, 4]
      p.format.units = 'in'
      p.end()
    })
  })
})
