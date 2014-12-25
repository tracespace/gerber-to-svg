# tests for the macro arithmetic calc
calc = require '../src/macro-calc'

# stream hook for testing for warnings
streamCapture = require './stream-capture'
stderr = -> streamCapture(process.stderr)

tokenize = calc.tokenize
isNumber = calc.isNumber
parse = calc.parse

describe 'macro arithmetic calculator', ->
  describe 'tokenize function', ->
    it 'should break apart a string into tokens', ->
      tokenize('1').should.eql [ '1' ]
      tokenize('1.2').should.eql [ '1.2' ]
      tokenize('$3').should.eql [ '$3' ]
      tokenize('+-/x').should.eql [ '+', '-', '/', 'x' ]
      tokenize('(())').should.eql [ '(', '(', ')', ')' ]
      tokenize('1+(2x$3)').should.eql [ '1', '+', '(', '2', 'x', '$3', ')' ]
  describe 'is number function', ->
    it 'should identify a number as a number', ->
      isNumber('3').should.be.true
    it 'should identify a float as a number', ->
      isNumber('3.14').should.be.true
    it 'should identify a modifier as a number', ->
      isNumber('$3').should.be.true
    it 'should not identify an operator as a number', ->
      isNumber('+').should.be.false
      isNumber('-').should.be.false
      isNumber('x').should.be.false
      isNumber('/').should.be.false
      isNumber(')').should.be.false
      isNumber('(').should.be.false

  describe 'parse function', ->
    it 'should parse a string into an object of nodes', ->
      parse('(1+$2)x3)').should.eql {
        type: 'x'
        left: {
          type: '+'
          left: { type: 'n', val: '1' }
          right: { type: 'n', val: '$2' }
        }
        right: { type: 'n', val: '3'}
      }
  
  describe 'exceptions to the rules', ->
    it "should allow an 'X' as a symbol, but warn that is should be 'x'", ->
      hook = stderr()
      parse('1X2').should.eql {
        type: 'x'
        left: { type: 'n', val: '1' }
        right: { type: 'n', val: '2' }
      }
      hook.captured().should.match /uppercase 'X' as multiplication symbol/
      hook.unhook()
