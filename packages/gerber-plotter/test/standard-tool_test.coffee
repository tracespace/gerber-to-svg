# test suite for the standard tool functions

standard = require '../src/standard-tool'

describe 'standard tool function', ->
  tool = '10'
  describe 'for circle tools', ->
    # input and output for a circle tool with no hole
    CIRCLE_NO_HOLE = { dia: 10 }
    CIRCLE_NO_HOLE_PAD = '<circle cx="0" cy="0" r="5" id="tool10pad" />'
    CIRCLE_NO_HOLE_TRACE = {
      'stroke-width': '10'
      'stroke-linecap': 'round'
      'stroke-linejoin': 'round'
    }

    # circle tool with a circle hole
    # hole means that this tool is not strokeable
    CIRCLE_C_HOLE = { dia: 7.8, hole: { dia: 5.3 } }
    CIRCLE_C_HOLE_PAD = '<mask id="tool10pad_hole">\
                         <circle cx="0" cy="0" r="3.9" fill="#fff" />\
                         <circle cx="0" cy="0" r="2.65" fill="#000" />\
                         </mask>\
                         <circle cx="0" cy="0" r="3.9" id="tool10pad"
                           mask="url(#tool10pad_hole)"
                         />'
    CIRCLE_C_HOLE_TRACE = false

    # circle tool with a rectangular hole
    CIRCLE_R_HOLE = { dia: 14.46, hole: { width: 4.6, height: 3.2 } }
    CIRCLE_R_HOLE_PAD = '<mask id="tool10pad_hole">\
                         <circle cx="0" cy="0" r="7.23" fill="#fff" />\
                         <rect x="-2.3" y="-1.6" width="4.6" height="3.2" fill="#000" />\
                         </mask>\
                         <circle cx="0" cy="0" r="7.23" id="tool10pad"
                           mask="url(#tool10pad_hole)"
                         />'
    CIRCLE_R_HOLE_TRACE = false

    it 'should return the svg for a circle with no hole', ->
      result = standard.circle tool, CIRCLE_NO_HOLE
      result.pad.should.equal CIRCLE_NO_HOLE_PAD
      for key, value of CIRCLE_NO_HOLE_TRACE
        result.trace["#{key}"].should.equal value
    it 'should return the svg for a circle with a circle hole', ->
      result = standard.circle tool, CIRCLE_C_HOLE
      result.pad.should.equal CIRCLE_C_HOLE_PAD
      result.trace.should.equal CIRCLE_C_HOLE_TRACE
    it 'should return the svg for a circle with a rectangular hole', ->
      result = standard.circle tool, CIRCLE_R_HOLE
      result.pad.should.equal CIRCLE_R_HOLE_PAD
      result.trace.should.equal CIRCLE_R_HOLE_TRACE
    it 'should throw an error if the diamter is negative', ->
      (-> result = standard.circle tool, {dia: '-1.2'})
        .should.throw /negative diameter/
    it 'should throw an error if the diameter is missing', ->
      (-> result = standard.circle tool, {})
        .should.throw /missing diameter/
