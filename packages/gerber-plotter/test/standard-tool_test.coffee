# test suite for the standard tool functions
expect = require('chai').expect
standard = require '../src/standard-tool'
# warning capture
warnings = require './warn-capture'

tool = 'D10'
describe 'standard tool function', ->

  it 'should return the pad id', ->
    result = standard tool, { dia: 10 }
    expect( result.padId ).to.match /D10/

  it 'should return an array of shapes for the pad', ->
    result = standard 'D10', { dia: 10 }
    expect( result.pad.length ).to.equal 1
    result = standard tool, { dia: 10, hole: { dia: 2 } }
    expect( result.pad.length ).to.equal 2

  describe 'for circle tools', ->
    it 'should half the diameter to get the radius', ->
      result = standard tool, {dia: 10}
      expect( result.pad[0].circle.r ).to.equal 5
    it 'should set the center to 0 by defualt', ->
      result = standard tool, {dia: 10}
      expect( result.pad[0].circle.cx ).to.equal 0
      expect( result.pad[0].circle.cy ).to.equal 0
    it 'should be traceable if there is no hole', ->
      result = standard tool, {dia: 10}
      expect( result.trace['stroke-width'] ).to.equal 10
    it 'should throw an error if the diameter is negative', ->
      expect( -> standard tool, {dia: -3.4} ).to.throw /diameter out of range/
      expect( -> standard tool, {dia: 0} ).to.not.throw

  describe 'for rectangle tools', ->
    it 'should set the width and height', ->
      result = standard tool, { width: 1.2, height: 2.2 }
      expect( result.pad[0].rect.width ).to.equal 1.2
      expect( result.pad[0].rect.height ).to.equal 2.2
    it 'should offset the top left corner', ->
      result = standard tool, { width: 1.2, height: 2.2 }
      expect( result.pad[0].rect.x ).to.equal -0.6
      expect( result.pad[0].rect.y ).to.equal -1.1
    it 'should be traceable if there is no hole', ->
      result = standard tool, { width: 1.2, height: 2.2 }
      expect( result.trace ).to.not.be.false
    it 'should throw an error for negative side lengths', ->
      expect(-> standard tool, {width: -23, height: 4}).to.throw /out of range/
      expect(-> standard tool, {width: 2.3, height: -1}).to.throw /out of range/
    it 'should throw a warning and return circle for zero-size side lengths', ->
      warnings.hook()
      result = standard tool, { width: 0, height: 1 }
      expect( warnings.unhook() ).to.match /zero-size rectangle/
      expect( result.pad[0].circle.r ).to.eql 0
      expect( result.pad[0].circle.id ).to.match /D10/

  describe 'for obround tools', ->
    it 'should return a rect with radiused corners', ->
      result = standard tool, { width: 3.4, height: 2.2, obround: true }
      expect( result.pad[0].rect.rx ).to.equal 1.1
      expect( result.pad[0].rect.ry ).to.equal 1.1
      result = standard tool, { width: 6.6, height: 6.7, obround: true }
      expect( result.pad[0].rect.rx ).to.equal 3.3
      expect( result.pad[0].rect.ry ).to.equal 3.3

  describe 'for polygon tools', ->
    it 'should return the correct points with no rotation specified', ->
      result = standard tool, { dia: 4, vertices: 5 }
      points = ''
      step = 2 * Math.PI / 5
      for v in [0..4]
        theta = v * step
        points += "#{2 * Math.cos theta},#{2 * Math.sin theta}"
        if v isnt 4 then points += ' '
      expect( result.pad[0].polygon.points ).to.equal points
    it 'should return the correct points with rotation specified', ->
      result = standard tool, { dia: 42.6, vertices: 7, degrees: 42 }
      points = ''
      start = 42 * Math.PI / 180
      step = 2 * Math.PI / 7
      for v in [0..6]
        theta = start + v * step
        points += "#{21.3 * Math.cos theta},#{21.3 * Math.sin theta}"
        if v isnt 6 then points += ' '
      expect( result.pad[0].polygon.points ).to.equal points
    it 'should not be traceable', ->
      result = standard tool, { dia: 4, vertices: 5 }
      expect( result.trace ).to.be.false
      result = standard tool, { dia: 42.6, vertices: 7, degrees: 42 }
      expect( result.trace ).to.be.false
    it 'should throw if the number of points is not between 3 and 12', ->
      expect( -> result = standard tool, {dia: 10, vertices: 2} )
        .to.throw /points out of range/
      expect( -> result = standard tool, {dia: 10, vertices: 13} )
        .to.throw /points out of range/

  describe 'with holes', ->
    it 'should not allow tracing if theres a hole', ->
      result = standard tool, { dia: 10, hole: { dia: 3 } }
      expect( result.trace ).to.be.false
    it 'should create a mask with a circle if the hole is circular', ->
      result = standard tool, { dia: 10, hole: { dia: 4 } }
      # result pad should be an array of two objects where there mask is first
      expect( result.pad ).to.have.length 2
      expect( result.pad[0].mask._ ).to.have.length 2
      expect( result.pad[0].mask._ ).to.eql [
        { rect: { x: -5, y: -5, width: 10, height: 10, fill: '#fff' } }
        { circle: { cx: 0, cy: 0, r: 2, fill: '#000' } }
      ]
    it 'should create a mask with a rect if the hole is rectangular', ->
      result = standard tool, { dia: 10, hole: { width: 4, height: 2 } }
      # result pad should be an array of two objects where there mask is first
      expect( result.pad ).to.have.length 2
      expect( result.pad[0].mask._ ).to.have.length 2
      expect( result.pad[0].mask._ ).to.eql [
        { rect: { x: -5, y: -5, width: 10, height: 10, fill: '#fff' } }
        { rect: { x: -2, y: -1, width: 4, height: 2, fill: '#000' } }
      ]
    it 'should set the mask of the pad properly', ->
      result = standard tool, { dia: 10, hole: { dia: 4 } }
      maskId = result.pad[0].mask.id
      expect( result.pad[1].circle.mask ).to.eql "url(##{maskId})"
    it 'should throw an error if the diameter is negative', ->
      expect( -> standard tool, { dia: 10, hole: { dia: -3 } } )
        .to.throw /hole diameter out of range/
    it 'should throw an error if the hole sides are negative', ->
      expect( -> standard tool, { dia: 10, hole: { width: -3, height: 2 } } )
        .to.throw /hole width out of range/
      expect( -> standard tool, { dia: 10, hole: { width: 1, height: -5 } } )
        .to.throw /hole height out of range/
    it 'should throw an error if parameters are invalid', ->
      expect( -> standard tool, { dia: 10, hole: { width: 1 } } )
        .to.throw /invalid hole/
      expect( -> standard tool, { dia: 10, hole: { height: 1 } } )
        .to.throw /invalid hole/
      expect( -> standard tool, { dia: 10, hole: { dia: 2, width: 1 } } )
        .to.throw /invalid hole/
      expect( -> standard tool, { dia: 10, hole: { dia: 2, height: 1 } } )
        .to.throw /invalid hole/
