# test suite for the standard tool functions

standard = require '../src/standard-tool'

describe 'standard tool function', ->
  it 'should not populate the id field if the tool is empty', ->
    result = standard { dia: 10 }, 'D12'
    result.pad.circle._attr.id.should.match /tool-D12-pad/
    result = standard { dia: 10 }, ''
    (result.pad.circle._attr.id?).should.be.false
    result = standard { dia: 10 }
    (result.pad.circle._attr.id?).should.be.false

  describe 'for circle tools', ->
    it 'should half the diameter to get the radius', ->
      result = standard {dia: 10}
      result.pad.circle._attr.r.should.equal '5'
    it 'should set the center to 0 by defualt', ->
      result = standard {dia: 10}
      result.pad.circle._attr.cx.should.equal '0'
      result.pad.circle._attr.cy.should.equal '0'
    it 'should set the center to the paramters passed in', ->
      result = standard {dia: 10, cx: 4, cy: 3}
      result.pad.circle._attr.cx.should.equal '4'
      result.pad.circle._attr.cy.should.equal '3'
    it 'should be traceable if there is no hole', ->
      result = standard {dia: 10}
      result.trace['stroke-width'].should.equal '10'
      result.trace['stroke-linecap'].should.equal 'round'
      result.trace['stroke-linejoin'].should.equal 'round'
    it 'should throw an error if the diameter is negative', ->
      (-> standard {dia: -3.4}).should.throw /diameter out of range/
      (-> standard {dia: 0}).should.not.throw

  describe 'for rectangle tools', ->
    it 'should set the width and height', ->
      result = standard { width: 1.2, height: 2.2 }
      result.pad.rect._attr.width.should.equal '1.2'
      result.pad.rect._attr.height.should.equal '2.2'
    it 'should offset the top left corner if not given a center position', ->
      result = standard { width: 1.2, height: 2.2 }
      result.pad.rect._attr.x.should.equal '-0.6'
      result.pad.rect._attr.y.should.equal '-1.1'
    it 'should offset the top left corner if given a center', ->
      result = standard { width: 1.2, height: 2.2, cx: 1, cy: 4 }
      result.pad.rect._attr.x.should.equal '0.4'
      result.pad.rect._attr.y.should.equal '2.9'
    it 'should be traceable if there is no hole', ->
      result = standard { width: 1.2, height: 2.2 }
      result.trace['stroke-width'].should.equal '0'
    it 'should throw an error for non-positive side lengths', ->
      (-> standard {width: -23, height: 4}).should.throw /out of range/
      (-> standard {width: 2.3, height: 0}).should.throw /out of range/

  describe 'for obround tools', ->
    it 'should return a rect with radiused corners', ->
      result = standard { width: 3.4, height: 2.2, obround: true }
      result.pad.rect._attr.rx.should.equal '1.1'
      result.pad.rect._attr.ry.should.equal '1.1'
      result = standard { width: 6.6, height: 6.7, obround: true }
      result.pad.rect._attr.rx.should.equal '3.3'
      result.pad.rect._attr.ry.should.equal '3.3'

  describe 'for polygon tools', ->
    it 'should return the correct points with no rotation specified', ->
      result = standard { dia: 4, verticies: 5 }
      points = ''
      step = 2*Math.PI/5
      for v in [0..4]
        theta = v*step
        points += "#{2*Math.cos theta},#{2*Math.sin theta}"
        if v isnt 4 then points += ' '
      result.pad.polygon._attr.points.should.equal points
    it 'should return the correct points with rotation specified', ->
      result = standard { dia: 42.6, verticies: 7, degrees: 42 }
      points = ''
      start = 42 * Math.PI / 180
      step = 2*Math.PI/7
      for v in [0..6]
        theta = start+v*step
        points += "#{21.3*Math.cos theta},#{21.3*Math.sin theta}"
        if v isnt 6 then points += ' '
      result.pad.polygon._attr.points.should.equal points
    it 'should not be traceable', ->
      result = standard { dia: 4, verticies: 5 }
      result.trace.should.be.false
      result = standard { dia: 42.6, verticies: 7, degrees: 42 }
      result.trace.should.be.false
    it 'should throw if the number of points is not between 3 and 12', ->
      (-> result = standard {dia: 10, verticies: 2})
        .should.throw /points out of range/
      (-> result = standard {dia: 10, verticies: 13})
        .should.throw /points out of range/

  describe 'with holes', ->
    it 'should throw an error if the diameter is negative', ->
      (-> standard { dia: 10, hole: { dia: -3 } })
        .should.throw /hole diameter out of range/
    it 'should throw an error if the hole sides are negative', ->
      (-> standard { dia: 10, hole: { width: -3, height: 2 } })
        .should.throw /hole width out of range/
      (-> standard { dia: 10, hole: { width: 1, height: -5 } })
        .should.throw /hole height out of range/
    it 'should throw an error if parameters are invalid', ->
      (-> standard { dia: 10, hole: { width: 1 } })
        .should.throw /invalid hole/
      (-> standard { dia: 10, hole: { height: 1 } })
        .should.throw /invalid hole/
      (-> standard { dia: 10, hole: { dia: 2, width: 1 } })
        .should.throw /invalid hole/
      (-> standard { dia: 10, hole: { dia: 2, height: 1 } })
        .should.throw /invalid hole/
