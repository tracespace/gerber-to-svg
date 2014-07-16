# tests for the aperture macro class

mt = require('../src/macro-tool')
Macro = mt.MacroTool
macros = mt.macros
primitives = mt.primitives

describe 'tool macro class', ->
  it 'should add itself to the macro list', ->
    m = new Macro ['MACRONAME']
    macros.MACRONAME.should.equal m

describe 'macro primitive', ->
  tool = '10'
  pad = ''
  describe 'circles', ->
    CIRCLE = [
      () -> 1
      () -> 4
      () -> 1
      () -> 2
    ]
    CIRCLE_PAD = '<circle cx="1" cy="2" r="2" id="tool_macro0_pad" />'

    CIRCLE_CLEAR = [
      () -> 0
      () -> 8
      () -> 3
      () -> 2
    ]
    CIRCLE_CLEAR_PAD = '<g mask="url(#_macro1_clear)"></g>\
                        <mask id="_macro1_clear">\
                        <rect width="100%" height="100%" fill="#fff" />\
                        <circle cx="3" cy="2" r="4" id="tool_macro1_pad"
                        fill="#000" /></mask>'
    it 'should return the svg for a circle', ->
      result = primitives['1'] pad, CIRCLE
      result.should.equal CIRCLE_PAD

    it 'should return a masked group if exposure if off', ->
      result = primitives['1'] pad, CIRCLE_CLEAR
      result.should.equal CIRCLE_CLEAR_PAD
