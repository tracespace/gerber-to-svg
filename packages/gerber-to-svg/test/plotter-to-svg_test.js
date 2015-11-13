// test suite for the plotter to svg transform stream
'use strict'

var expect = require('chai').expect

var plotterToSvg = require('../lib/plotter-to-svg')

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
    p = plotterToSvg('id')
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
    p = plotterToSvg('foo')
    p.once('data', function(result) {
      expect(result).to.match(/id="foo"/)
      done()
    })

    p.write({type: 'size', box: [Infinity, Infinity, -Infinity, -Infinity], units: ''})
    p.end()
  })

  it('should be able to add a classname', function(done) {
    p = plotterToSvg('foo', 'bar')
    p.once('data', function(result) {
      expect(result).to.match(/class="bar"/)
      done()
    })

    p.write({type: 'size', box: [Infinity, Infinity, -Infinity, -Infinity], units: ''})
    p.end()
  })

  it('should be able to add a color', function(done) {
    p = plotterToSvg('foo', 'bar', 'baz')
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

    it('should handle ')
  })
})
