// test suite for the plotter to svg transform stream
'use strict'

var expect = require('chai').expect

var PlotterToSvg = require('../lib/plotter-to-svg')

var EMPTY_SVG = [
  '<svg id="id" ',
  'xmlns="http://www.w3.org/2000/svg" ',
  'version="1.1" ',
  'xmlns:xlink="http://www.w3.org/1999/xlink" ',
  'stroke-linecap="round" ',
  'stroke-linejoin="round" ',
  'stroke-width="0" ',
  'width="0" ',
  'height="0" ',
  'viewBox="0 0 0 0">',
  '</svg>'].join('')

describe('plotter to svg transform stream', function() {
  var p
  beforeEach(function() {
    p = new PlotterToSvg('id')
    p.setEncoding('utf8')
  })

  it('should emit an empty svg if it gets a zero size plot', function(done) {
    p.once('data', function(result) {
      expect(result).to.equal(EMPTY_SVG)
      done()
    })

    p.write({type: 'size', box: [Infinity, Infinity, -Infinity, -Infinity], units: ''})
    p.end()
  })

  it('should be able to add an id', function(done) {
    p = new PlotterToSvg('foo')
    p.once('data', function(result) {
      expect(result).to.match(/id="foo"/)
      done()
    })

    p.write({type: 'size', box: [Infinity, Infinity, -Infinity, -Infinity], units: ''})
    p.end()
  })

  it('should be able to add a classname', function(done) {
    p = new PlotterToSvg('foo', 'bar')
    p.once('data', function(result) {
      expect(result).to.match(/class="bar"/)
      done()
    })

    p.write({type: 'size', box: [Infinity, Infinity, -Infinity, -Infinity], units: ''})
    p.end()
  })

  it('should be able to add a color', function(done) {
    p = new PlotterToSvg('foo', 'bar', 'baz')
    p.once('data', function(result) {
      expect(result).to.match(/color="baz"/)
      done()
    })

    p.write({type: 'size', box: [Infinity, Infinity, -Infinity, -Infinity], units: ''})
    p.end()
  })

  describe('creating pad shapes', function() {
    it('should handle circle primitives', function() {
      var toolShape = [{type: 'circle', cx: 0.001, cy: 0.002, r: 0.005}]
      var expected = '<circle id="id_pad-10" cx="1" cy="2" r="5"/>'

      p.write({type: 'shape', tool: '10', shape: toolShape})
      expect(p.defs).to.equal(expected)
    })

    it('should handle rect primitives', function() {
      var toolShape = [
        {type: 'rect', cx: 0.002, cy: 0.004, width: 0.002, height: 0.004, r: 0.002}
      ]
      var expected = '<rect id="id_pad-10" x="1" y="2" rx="2" ry="2" width="2" height="4"/>'

      p.write({type: 'shape', tool: '10', shape: toolShape})
      expect(p.defs).to.equal(expected)
    })

    it('should handle polygon primitives', function() {
      var toolShape = [{type: 'poly', points: [[0, 0], [1, 0], [0, 1]]}]
      var expected = '<polygon id="id_pad-12" points="0,0 1000,0 0,1000"/>'

      p.write({type: 'shape', tool: '12', shape: toolShape})
      expect(p.defs).to.equal(expected)
    })

    it('should handle a ring primitives', function() {
      var toolShape = [{type: 'ring', r: 0.02, width: 0.005, cx: 0.05, cy: -0.03}]
      var expected = '<circle id="id_pad-11" cx="50" cy="-30" r="20" stroke-width="5"/>'

      p.write({type: 'shape', tool: '11', shape: toolShape})
      expect(p.defs).to.equal(expected)
    })

    it('should handle a clipped primitive with rects', function() {
      var clippedShapes = [
        {type: 'rect', cx: 0.003, cy: 0.003, width: 0.004, height: 0.004, r: 0},
        {type: 'rect', cx: -0.003, cy: 0.003, width: 0.004, height: 0.004, r: 0},
        {type: 'rect', cx: -0.003, cy: -0.003, width: 0.004, height: 0.004, r: 0},
        {type: 'rect', cx: 0.003, cy: -0.003, width: 0.004, height: 0.004, r: 0}
      ]
      var ring = {type: 'ring', r: 0.004, width: 0.002, cx: 0, cy: 0}
      var toolShape = [{type: 'clip', shape: clippedShapes, clip: ring}]

      var expected = [
        '<mask id="id_pad-15_mask" fill="none" stroke="#fff">',
        '<circle cx="0" cy="0" r="4" stroke-width="2"/>',
        '</mask>',
        '<g id="id_pad-15" mask="url(#id_pad-15_mask)">',
        '<rect x="1" y="1" width="4" height="4"/>',
        '<rect x="-5" y="1" width="4" height="4"/>',
        '<rect x="-5" y="-5" width="4" height="4"/>',
        '<rect x="1" y="-5" width="4" height="4"/>',
        '</g>'
      ].join('')

      p.write({type: 'shape', tool: '15', shape: toolShape})
      expect(p.defs).to.equal(expected)
    })

    it('should handle a clipped primitive with polys', function() {
      var po = 0.001
      var ne = -0.005
      var mP = po + 0.004
      var mN = ne + 0.004

      var clippedShapes = [
        {type: 'poly', points: [[po, po], [mP, po], [mP, mP], [po, mP]]},
        {type: 'poly', points: [[ne, po], [mN, po], [mN, mP], [ne, mP]]},
        {type: 'poly', points: [[ne, ne], [mN, ne], [mN, mN], [ne, mN]]},
        {type: 'poly', points: [[po, ne], [mP, ne], [mP, mN], [po, mN]]}
      ]
      var ring = {type: 'ring', r: 0.004, width: 0.002, cx: 0, cy: 0}
      var toolShape = [{type: 'clip', shape: clippedShapes, clip: ring}]

      var expected = [
        '<mask id="id_pad-15_mask" fill="none" stroke="#fff">',
        '<circle cx="0" cy="0" r="4" stroke-width="2"/>',
        '</mask>',
        '<g id="id_pad-15" mask="url(#id_pad-15_mask)">',
        '<polygon points="1,1 5,1 5,5 1,5"/>',
        '<polygon points="-5,1 -1,1 -1,5 -5,5"/>',
        '<polygon points="-5,-5 -1,-5 -1,-1 -5,-1"/>',
        '<polygon points="1,-5 5,-5 5,-1 1,-1"/>',
        '</g>'
      ].join('')

      p.write({type: 'shape', tool: '15', shape: toolShape})
      expect(p.defs).to.equal(expected)
    })

    it('should handle multiple primitives', function() {
      var toolShape = [
        {type: 'rect', cx: 0.003, cy: 0.003, width: 0.004, height: 0.004, r: 0},
        {type: 'rect', cx: -0.003, cy: 0.003, width: 0.004, height: 0.004, r: 0},
        {type: 'rect', cx: -0.003, cy: -0.003, width: 0.004, height: 0.004, r: 0},
        {type: 'rect', cx: 0.003, cy: -0.003, width: 0.004, height: 0.004, r: 0}
      ]

      var expected = [
        '<g id="id_pad-20">',
        '<rect x="1" y="1" width="4" height="4"/>',
        '<rect x="-5" y="1" width="4" height="4"/>',
        '<rect x="-5" y="-5" width="4" height="4"/>',
        '<rect x="1" y="-5" width="4" height="4"/>',
        '</g>'
      ].join('')

      p.write({type: 'shape', tool: '20', shape: toolShape})
      expect(p.defs).to.equal(expected)
    })

    it('should handle polarity changes', function() {
      var toolShape = [
        {type: 'rect', cx: 0, cy: 0.005, width: 0.006, height: 0.008, r: 0},
        {type: 'layer', polarity: 'clear', box: [-0.003, 0.001, 0.003, 0.009]},
        {type: 'rect', cx: 0, cy: 0.005, width: 0.004, height: 0.004, r: 0},
        {type: 'layer', polarity: 'dark', box: [-0.003, 0.001, 0.003, 0.009]},
        {type: 'rect', cx: 0, cy: -0.005, width: 0.006, height: 0.008, r: 0},
        {type: 'circle', cx: 0, cy: 0, r: 0.004},
        {type: 'layer', polarity: 'clear', box: [-0.004, -0.009, 0.004, 0.004]},
        {type: 'rect', cx: 0, cy: -0.005, width: 0.004, height: 0.004, r: 0},
        {type: 'circle', cx: 0, cy: 0, r: 0.002}
      ]

      var expected = [
        '<mask id="id_pad-11_1" fill="#000">',
        '<rect x="-3" y="1" width="6" height="8" fill="#fff"/>',
        '<rect x="-2" y="3" width="4" height="4"/>',
        '</mask>',
        '<mask id="id_pad-11_3" fill="#000">',
        '<rect x="-4" y="-9" width="8" height="13" fill="#fff"/>',
        '<rect x="-2" y="-7" width="4" height="4"/>',
        '<circle cx="0" cy="0" r="2"/>',
        '</mask>',
        '<g id="id_pad-11">',
        '<g mask="url(#id_pad-11_3)">',
        '<g mask="url(#id_pad-11_1)">',
        '<rect x="-3" y="1" width="6" height="8"/>',
        '</g>',
        '<rect x="-3" y="-9" width="6" height="8"/>',
        '<circle cx="0" cy="0" r="4"/>',
        '</g>',
        '</g>'
      ].join('')

      p.write({type: 'shape', tool: '11', shape: toolShape})
      expect(p.defs).to.equal(expected)
    })
  })

  it('should be able to add a pad to the layer', function() {
    var pad = {type: 'pad', tool: '24', x: 0.020, y: 0.050}
    var expected = '<use xlink:href="#id_pad-24" x="20" y="50"/>'

    p.write(pad)
    expect(p.layer).to.equal(expected)
  })
})
