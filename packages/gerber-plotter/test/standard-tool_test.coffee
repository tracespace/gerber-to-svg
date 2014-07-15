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
      result = standard tool, CIRCLE_NO_HOLE
      result.pad.should.equal CIRCLE_NO_HOLE_PAD
      for key, value of CIRCLE_NO_HOLE_TRACE
        result.trace["#{key}"].should.equal value
    it 'should return the svg for a circle with a circle hole', ->
      result = standard tool, CIRCLE_C_HOLE
      result.pad.should.equal CIRCLE_C_HOLE_PAD
      result.trace.should.equal CIRCLE_C_HOLE_TRACE
    it 'should return the svg for a circle with a rectangular hole', ->
      result = standard tool, CIRCLE_R_HOLE
      result.pad.should.equal CIRCLE_R_HOLE_PAD
      result.trace.should.equal CIRCLE_R_HOLE_TRACE

  describe 'for rectangle tools', ->
    # input and output for a rectangle tool with no hole
    RECT_NO_HOLE = { width: 3.4, height: 2.2 }
    RECT_NO_HOLE_PAD = '<rect x="-1.7" y="-1.1" width="3.4" height="2.2" id="tool10pad" />'
    RECT_NO_HOLE_TRACE = { 'stroke-width': 0 }

    # circle tool with a circle hole
    # hole means that this tool is not strokeable
    RECT_C_HOLE = { width: 2.0, height: 1.0, hole: { dia: 5.3 } }
    RECT_C_HOLE_PAD = '<mask id="tool10pad_hole">\
                      <rect x="-1" y="-0.5" width="2" height="1" fill="#fff" />\
                      <circle cx="0" cy="0" r="2.65" fill="#000" />\
                      </mask>\
                      <rect x="-1" y="-0.5" width="2" height="1" id="tool10pad"
                      mask="url(#tool10pad_hole)"
                      />'
    RECT_C_HOLE_TRACE = false

    # circle tool with a rectangular hole
    RECT_R_HOLE = { width: 9.4, height: 4.2, hole: { width: 4.6, height: 3.2 } }
    RECT_R_HOLE_PAD = '<mask id="tool10pad_hole">\
                       <rect x="-4.7" y="-2.1" width="9.4" height="4.2" fill="#fff" />\
                       <rect x="-2.3" y="-1.6" width="4.6" height="3.2" fill="#000" />\
                       </mask>\
                       <rect x="-4.7" y="-2.1" width="9.4" height="4.2" id="tool10pad"
                       mask="url(#tool10pad_hole)"
                       />'
    RECT_R_HOLE_TRACE = false

    it 'should return the svg for a rectangle with no hole', ->
      result = standard tool, RECT_NO_HOLE
      result.pad.should.equal RECT_NO_HOLE_PAD
      for key, value of RECT_NO_HOLE_TRACE
        result.trace["#{key}"].should.equal value
    it 'should return the svg for a rectangle with a circle hole', ->
      result = standard tool, RECT_C_HOLE
      result.pad.should.equal RECT_C_HOLE_PAD
      result.trace.should.equal RECT_C_HOLE_TRACE
    it 'should return the svg for a rectangle with a rectangular hole', ->
      result = standard tool, RECT_R_HOLE
      result.pad.should.equal RECT_R_HOLE_PAD
      result.trace.should.equal RECT_R_HOLE_TRACE

  describe 'for obround tools', ->
    # input and output for a rectangle tool with no hole
    OB_NO_HOLE = { width: 3.4, height: 2.2, obround: true }
    OB_NO_HOLE_PAD = '<rect x="-1.7" y="-1.1" width="3.4" height="2.2"
                      rx="1.1" ry="1.1" id="tool10pad" />'
    OB_NO_HOLE_TRACE = false

    # circle tool with a circle hole
    # hole means that this tool is not strokeable
    OB_C_HOLE = { width: 2.0, height: 1.0, obround: true, hole: { dia: 5.3 } }
    OB_C_HOLE_PAD = '<mask id="tool10pad_hole">\
                    <rect x="-1" y="-0.5" width="2" height="1"
                    rx="0.5" ry="0.5" fill="#fff" />\
                    <circle cx="0" cy="0" r="2.65" fill="#000" />\
                    </mask>\
                    <rect x="-1" y="-0.5" width="2" height="1"
                    rx="0.5" ry="0.5" id="tool10pad"
                    mask="url(#tool10pad_hole)" />'
    OB_C_HOLE_TRACE = false

    # circle tool with a rectangular hole
    OB_R_HOLE = { width: 9.4, height: 4.2, obround: true, hole: {
      width: 4.6
      height: 3.2 } }
    OB_R_HOLE_PAD = '<mask id="tool10pad_hole">\
                    <rect x="-4.7" y="-2.1" width="9.4" height="4.2"
                    rx="2.1" ry="2.1" fill="#fff" />\
                    <rect x="-2.3" y="-1.6" width="4.6" height="3.2" fill="#000" />\
                    </mask>\
                    <rect x="-4.7" y="-2.1" width="9.4" height="4.2"
                    rx="2.1" ry="2.1" id="tool10pad"
                    mask="url(#tool10pad_hole)" />'
    OB_R_HOLE_TRACE = false

    it 'should return the svg for a obround with no hole', ->
      result = standard tool, OB_NO_HOLE
      result.pad.should.equal OB_NO_HOLE_PAD
      result.trace.should.equal OB_NO_HOLE_TRACE
    it 'should return the svg for a obround with a circle hole', ->
      result = standard tool, OB_C_HOLE
      result.pad.should.equal OB_C_HOLE_PAD
      result.trace.should.equal OB_C_HOLE_TRACE
    it 'should return the svg for a obround with a rectangular hole', ->
      result = standard tool, OB_R_HOLE
      result.pad.should.equal OB_R_HOLE_PAD
      result.trace.should.equal OB_R_HOLE_TRACE
