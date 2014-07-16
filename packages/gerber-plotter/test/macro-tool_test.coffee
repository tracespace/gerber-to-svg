# tests for the aperture macro class

mt = require('../src/macro-tool')
Macro = mt.MacroTool
macros = mt.macros
primitives = mt.primitives

describe 'tool macro class', ->
  it 'should add itself to the macro list', ->
    m = new Macro ['MACRONAME']
    macros.MACRONAME.should.equal m

  it 'should be able to macro up a circle', ->
    circleBlocks = ['CMAC', '1,1,1.5,0,0']
    circleSvg = '<g id="tool10pad">\
                <circle cx="0" cy="0" r="0.75" id="tool_macro0_pad" /></g>'
    m = new Macro circleBlocks
    result = m.run '10'
    result.should.equal circleSvg

describe 'macro primitive', ->
  tool = '10'
  pad = ''
  describe 'circles', ->
    CIRCLE = [ '1', '4', '1', '2' ]
    CIRCLE_PAD = '<circle cx="1" cy="2" r="2" id="tool_macro1_pad" />'

    CIRCLE_CLEAR = [ '0', '8', '3', '2' ]
    CIRCLE_CLEAR_PAD = '<g mask="url(#_macro2_clear)"></g>\
                        <mask id="_macro2_clear">\
                        <rect width="100%" height="100%" fill="#fff" />\
                        <circle cx="3" cy="2" r="4" id="tool_macro2_pad"
                        fill="#000" /></mask>'
    it 'should return the svg for a circle', ->
      result = primitives['1'] pad, CIRCLE
      result.should.equal CIRCLE_PAD

    it 'should return a masked group if exposure if off', ->
      result = primitives['1'] pad, CIRCLE_CLEAR
      result.should.equal CIRCLE_CLEAR_PAD
