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
    it 'should not modify the pad string if block is a comment', ->
      m = new Macro ['AMNAME']
      m.runBlock('0 some comment', 'existing').should.equal 'existing'
    it 'should set a modifier but leave the pad alone', ->
      m = new Macro ['AMNAME']
      m.runBlock('$1=(1+2)x(3+4)', 'existing').should.equal 'existing'
      m.modifiers.$1.should.equal 21
    describe 'for primitives', ->
      it 'should wrap previous pad in masked group if exposure is off', ->
        m = new Macro ['AMNAME']
        result = m.runBlock('1,0,0,0,0', '<pad />')


  describe 'primitve methode', ->


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
