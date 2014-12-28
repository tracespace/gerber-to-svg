# tests for the macro arithmetic calc
calc = require '../src/macro-calc'
expect = require('chai').expect

# warnings hook for testing for warnings
warnings = require './warn-capture'

tokenize = calc.tokenize
isNumber = calc.isNumber
parse = calc.parse

describe 'macro arithmetic calculator', ->
  describe 'tokenize function', ->
    it 'should break apart a string into tokens', ->
      expect( tokenize '1' ).to.eql [ '1' ]
      expect( tokenize '1.2' ).to.eql [ '1.2' ]
      expect( tokenize '$3' ).to.eql [ '$3' ]
      expect( tokenize '+-/x' ).to.eql [ '+', '-', '/', 'x' ]
      expect( tokenize '(())' ).to.eql [ '(', '(', ')', ')' ]
      expect( tokenize '1+(2x$3)' ).to.eql ['1', '+', '(', '2', 'x', '$3', ')']
  describe 'is number function', ->
    it 'should identify a number as a number', ->
      expect( isNumber('3') ).to.be.true
    it 'should identify a float as a number', ->
      expect( isNumber('3.14') ).to.be.true
    it 'should identify a modifier as a number', ->
      expect( isNumber('$3') ).to.be.true
    it 'should not identify an operator as a number', ->
      expect( isNumber('+') ).to.be.false
      expect( isNumber('-') ).to.be.false
      expect( isNumber('x') ).to.be.false
      expect( isNumber('/') ).to.be.false
      expect( isNumber(')') ).to.be.false
      expect( isNumber('(') ).to.be.false

  describe 'parse function', ->
    it 'should parse a string into an object of nodes', ->
      expect( parse('(1+$2)x3)') ).to.eql {
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
      warnings.hook()
      expect( parse('1X2') ).to.eql {
        type: 'x'
        left: { type: 'n', val: '1' }
        right: { type: 'n', val: '2' }
      }
      expect( warnings.unhook() ).to.match /uppercase 'X' as multiplication/
