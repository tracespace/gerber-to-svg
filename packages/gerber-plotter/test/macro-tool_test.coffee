# tests for the aperture macro class

mt = require '../src/macro-tool'
Macro = mt.MacroTool
macros = mt.macros

describe 'tool macro class', ->
  it 'should add itself to the macro list', ->
    m = new Macro ['MACRONAME']
    macros.MACRONAME.should.equal m

  describe 'run method', ->
    it 'should set modifiers that are passed in', ->
      MODIFIERS = ['1', '1.5', '0', '-0.76']
      m = new Macro ['MACRONAME']
      result = m.run '10', MODIFIERS
      m.modifiers['$1'].should.equal 1
      m.modifiers['$2'].should.equal 1.5
      m.modifiers['$3'].should.equal 0
      m.modifiers['$4'].should.equal -0.76

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
    describe 'arithmetic', ->
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
