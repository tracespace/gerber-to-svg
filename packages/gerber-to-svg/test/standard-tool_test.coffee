# test suite for the standard tool functions

standard = require '../src/standard-tool'

describe 'standard tool function', ->
  tool = '10'
  it 'should not populate the id field if the tool is empty', ->
    result = standard '', {dia: 10}
    result.pad.should.equal '<circle "cx=0" cy="0" r="5" />'
    result = standard null, {dia: 10}
    result.pad.should.equal '<circle "cx=0" cy="0" r="5" />'  

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
    it 'should throw an error if the diameter is negative', ->
      (-> standard tool, {dia: -3.4}).should.throw /diameter out of range/

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
    it 'should throw an error for non-positive side lengths', ->
      (-> standard tool, {width: -23, height: 4}).should.throw /out of range/
      (-> standard tool, {width: 2.3, height: 0}).should.throw /out of range/

  describe 'for obround tools', ->
    # input and output for a rectangle tool with no hole
    OB_NO_HOLE = { width: 3.4, height: 2.2, obround: true }
    OB_NO_HOLE_PAD = '<rect x="-1.7" y="-1.1" width="3.4" height="2.2"
                      rx="1.1" ry="1.1" id="tool10pad" />'

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

    it 'should return the svg for a obround with no hole', ->
      result = standard tool, OB_NO_HOLE
      result.pad.should.equal OB_NO_HOLE_PAD
      result.trace.should.be.false
    it 'should return the svg for a obround with a circle hole', ->
      result = standard tool, OB_C_HOLE
      result.pad.should.equal OB_C_HOLE_PAD
      result.trace.should.be.false
    it 'should return the svg for a obround with a rectangular hole', ->
      result = standard tool, OB_R_HOLE
      result.pad.should.equal OB_R_HOLE_PAD
      result.trace.should.be.false

  describe 'for polygon tools', ->
    POLY_NO_DEG = { dia: 4, verticies: 5 }
    POLY_NO_DEG_PAD = '<polygon points="'
    step = 2*Math.PI/5
    for v in [0..4]
      theta = v*step
      POLY_NO_DEG_PAD += "#{2*Math.cos theta},#{2*Math.sin theta}"
      if v isnt 4 then POLY_NO_DEG_PAD += ' '
    POLY_NO_DEG_PAD += '" id="tool10pad" />'

    POLY_DEG = { dia: 42.6, verticies: 7, degrees: 42}
    POLY_DEG_PAD = '<polygon points="'
    start = 42 * Math.PI / 180
    step = 2*Math.PI/7
    for v in [0..6]
      theta = start+v*step
      POLY_DEG_PAD += "#{21.3*Math.cos theta},#{21.3*Math.sin theta}"
      if v isnt 6 then POLY_DEG_PAD += ' '
    POLY_DEG_PAD += '" id="tool10pad" />'

    it 'should throw if the number of points is not between 3 and 12', ->
      (-> result = standard tool, {dia: 10, verticies: 2})
        .should.throw /points out of range/
      (-> result = standard tool, {dia: 10, verticies: 13})
        .should.throw /points out of range/

    it 'should return the svg for a regular polygon with no start rotation', ->
      result = standard tool, POLY_NO_DEG
      result.pad.should.equal POLY_NO_DEG_PAD
      result.trace.should.be.false

    it 'should return the svg for a regular polygon with a start rotation', ->
      result = standard tool, POLY_DEG
      result.pad.should.equal POLY_DEG_PAD
      result.trace.should.be.false

  describe 'with holes', ->
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
