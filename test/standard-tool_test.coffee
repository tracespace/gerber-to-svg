# test suite for the standard tool functions

standard = require '../src/standard-tool'

tool = 'D10'
describe 'standard tool function', ->
  it 'should return the pad id', ->
    result = standard tool, { dia: 10 }
    result.padId.should.match /D10/

  it 'should return an array of shapes for the pad', ->
    result = standard 'D10', { dia: 10 }
    result.pad.length.should.equal 1
    result = standard tool, { dia: 10, hole: { dia: 2 } }
    result.pad.length.should.equal 2

  describe 'for circle tools', ->
    it 'should half the diameter to get the radius', ->
      result = standard tool, {dia: 10}
      result.pad[0].circle.r.should.equal 5
    it 'should set the center to 0 by defualt', ->
      result = standard tool, {dia: 10}
      result.pad[0].circle.cx.should.equal 0
      result.pad[0].circle.cy.should.equal 0
    it 'should be traceable if there is no hole', ->
      result = standard tool, {dia: 10}
      result.trace['stroke-width'].should.equal 10
    it 'should throw an error if the diameter is negative', ->
      (-> standard tool, {dia: -3.4}).should.throw /diameter out of range/
      (-> standard tool, {dia: 0}).should.not.throw

  describe 'for rectangle tools', ->
    it 'should set the width and height', ->
      result = standard tool, { width: 1.2, height: 2.2 }
      result.pad[0].rect.width.should.equal 1.2
      result.pad[0].rect.height.should.equal 2.2
    it 'should offset the top left corner', ->
      result = standard tool, { width: 1.2, height: 2.2 }
      result.pad[0].rect.x.should.equal -0.6
      result.pad[0].rect.y.should.equal -1.1
    it 'should be traceable if there is no hole', ->
      result = standard tool, { width: 1.2, height: 2.2 }
      result.trace.should.not.be.false
    it 'should throw an error for non-positive side lengths', ->
      (-> standard tool, {width: -23, height: 4}).should.throw /out of range/
      (-> standard tool, {width: 2.3, height: 0}).should.throw /out of range/

  describe 'for obround tools', ->
    it 'should return a rect with radiused corners', ->
      result = standard tool, { width: 3.4, height: 2.2, obround: true }
      result.pad[0].rect.rx.should.equal 1.1
      result.pad[0].rect.ry.should.equal 1.1
      result = standard tool, { width: 6.6, height: 6.7, obround: true }
      result.pad[0].rect.rx.should.equal 3.3
      result.pad[0].rect.ry.should.equal 3.3

  describe 'for polygon tools', ->
    it 'should return the correct points with no rotation specified', ->
      result = standard tool, { dia: 4, verticies: 5 }
      points = ''
      step = 2*Math.PI/5
      for v in [0..4]
        theta = v*step
        points += "#{2*Math.cos theta},#{2*Math.sin theta}"
        if v isnt 4 then points += ' '
      result.pad[0].polygon.points.should.equal points
    it 'should return the correct points with rotation specified', ->
      result = standard tool, { dia: 42.6, verticies: 7, degrees: 42 }
      points = ''
      start = 42 * Math.PI / 180
      step = 2*Math.PI/7
      for v in [0..6]
        theta = start+v*step
        points += "#{21.3*Math.cos theta},#{21.3*Math.sin theta}"
        if v isnt 6 then points += ' '
      result.pad[0].polygon.points.should.equal points
    it 'should not be traceable', ->
      result = standard tool, { dia: 4, verticies: 5 }
      result.trace.should.be.false
      result = standard tool, { dia: 42.6, verticies: 7, degrees: 42 }
      result.trace.should.be.false
    it 'should throw if the number of points is not between 3 and 12', ->
      (-> result = standard tool, {dia: 10, verticies: 2})
        .should.throw /points out of range/
      (-> result = standard tool, {dia: 10, verticies: 13})
        .should.throw /points out of range/

  describe 'with holes', ->
    it 'should not allow tracing if theres a hole', ->
      result = standard tool, { dia: 10, hole: { dia: 3 } }
      result.trace.should.be.false
    it 'should create a mask with a circle if the hole is circular', ->
      result = standard tool, { dia: 10, hole: { dia: 4 } }
      # result pad should be an array of two objects where there mask is first
      result.pad.should.containDeep [
        {
          mask: {
            _: [
              { rect: { x: -5, y: -5, width: 10, height: 10, fill: '#fff' } }
              { circle: { cx: 0, cy: 0, r: 2, fill: '#000' } }
            ]
          }
        }
      ]
    it 'should create a mask with a rect if the hole is rectangular', ->
      result = standard tool, { dia: 10, hole: { width: 4, height: 2 } }
      # result pad should be an array of two objects where there mask is first
      result.pad.should.containDeep [
        {
          mask: {
            _: [
              { rect: { x: -5, y: -5, width: 10, height: 10, fill: '#fff' } }
              { rect: { x: -2, y: -1, width: 4, height: 2, fill: '#000' } }
            ]
          }
        }
      ]
    it 'should set the mask of the pad properly', ->
      result = standard tool, { dia: 10, hole: { dia: 4 } }
      maskId = result.pad[0].mask.id
      result.pad.should.containDeep [ { circle: { mask: "url(##{maskId})" } } ]
    it 'should throw an error if the diameter is negative', ->
      (-> standard tool, { dia: 10, hole: { dia: -3 } })
        .should.throw /hole diameter out of range/
    it 'should throw an error if the hole sides are negative', ->
      (-> standard tool, { dia: 10, hole: { width: -3, height: 2 } })
        .should.throw /hole width out of range/
      (-> standard tool, { dia: 10, hole: { width: 1, height: -5 } })
        .should.throw /hole height out of range/
    it 'should throw an error if parameters are invalid', ->
      (-> standard tool, { dia: 10, hole: { width: 1 } })
        .should.throw /invalid hole/
      (-> standard tool, { dia: 10, hole: { height: 1 } })
        .should.throw /invalid hole/
      (-> standard tool, { dia: 10, hole: { dia: 2, width: 1 } })
        .should.throw /invalid hole/
      (-> standard tool, { dia: 10, hole: { dia: 2, height: 1 } })
        .should.throw /invalid hole/
