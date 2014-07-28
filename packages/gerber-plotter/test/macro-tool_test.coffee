# tests for the aperture macro class

Macro = require '../src/macro-tool'

describe 'tool macro class', ->
  it 'should identify itself', ->
    m = new Macro ['AMMACRONAME']
    m.name.should.equal 'MACRONAME'

  it 'should save the blocks for processing', ->
    m = new Macro ['AMNAME', '0 block 0', '0 block 1', '0 block 2']
    m.blocks[0].should.equal '0 block 0'
    m.blocks[1].should.equal '0 block 1'
    m.blocks[2].should.equal '0 block 2'

  describe 'run method', ->
    it 'should set modifiers that are passed in', ->
      MODIFIERS = ['1', '1.5', '0', '-0.76']
      m = new Macro ['MACRONAME']
      result = m.run '10', MODIFIERS
      m.modifiers.$1.should.equal '1'
      m.modifiers.$2.should.equal '1.5'
      m.modifiers.$3.should.equal '0'
      m.modifiers.$4.should.equal '-0.76'

  describe 'run block method', ->
    it 'should not modify the pad if block is a comment', ->
      m = new Macro ['AMNAME']
      m.runBlock '0 some comment'
      m.shapes.should.eql []
      m.masks.should.eql []
    it 'should set a modifier but leave the pad alone', ->
      m = new Macro ['AMNAME']
      m.runBlock '$1=(1+2)x(3+4)'
      m.modifiers.$1.should.equal 21
      m.shapes.should.eql []
      m.masks.should.eql []

  describe 'primitve methode', ->
    it 'should add a circle to the shapes and the bbox', ->
      m = new Macro ['AMNAME']
      m.primitive [1, 1, 5, 1, 2]
      m.shapes.should.containDeep [
        { circle: { _attr: { cx: '1', cy: '2', r: '2.5' } } }
      ]
      m.masks.should.eql []
      m.bbox.should.eql [ -1.5, -0.5, 3.5, 4.5 ]
    it 'should add a vector line to the shapes and bbox', ->
      m = new Macro ['AMNAME']
      m.primitive [2, 1, 5, 1, 1, 15, 1, 0]
      m.shapes.should.containDeep [
        {
          line: {
            _attr: { x1: '1', y1: '1', x2: '15', y2: '1', 'stroke-width': '5' }
          }
        }
      ]
      m.masks.should.eql []
      m.bbox.should.eql [ 1, -1.5, 15, 3.5 ]

  describe 'getNumber method', ->
    m = new Macro ['MACRONAME']
    it 'should return a number if passed a string of a number', ->
      m.getNumber('2.4').should.equal 2.4
    it 'should return the modifier if passed a reference to a modifier', ->
      m.modifiers.$2 = 3.5
      m.getNumber('$2').should.equal 3.5
    it 'should return a number if passed a string with arithmetic', ->
      m.modifiers.$1 = 2.6
      m.getNumber('$1+5').should.equal 7.6

  describe 'arithmetic evaluate method', ->
    m = new Macro ['MACRONAME']
    it 'should obey order of operations', ->
      m.getNumber('1+2x3').should.equal 7
      m.getNumber('1-2x3').should.equal -5
      m.getNumber('1+1/2').should.equal 1.5
      m.getNumber('1-1/2').should.equal 0.5
    it 'should allow parentheses to overide order of operations', ->
      m.getNumber('(1+2)x3').should.equal 9
      m.getNumber('(1-2)x3').should.equal -3
      m.getNumber('(1+1)/2').should.equal 1
      m.getNumber('(1-1)/2').should.equal 0
