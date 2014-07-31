# test suite for GerberParser class
Parser = require '../src/gerber-parser'

describe 'gerber parser class', ->
  describe 'getting the next command', ->
    it 'should return an array', ->
      p = new Parser 'asdfgfdgf*'
      result = Array.isArray p.nextCommand()
      result.should.be.true
    it 'should return found data blocks', ->
      p = new Parser 'asdfgfdgf*'
      result = p.nextCommand()
      result.should.eql [ 'asdfgfdgf' ]
      p = new Parser '%MOIN*LPD*%'
      result = p.nextCommand()
      result.should.eql [ '%', 'MOIN', 'LPD', '%' ]
    it 'should ignore line feeds and carriage returns', ->
      p = new Parser 'asdf\ngf\rdgf*\n\r'
      result = p.nextCommand()
      result.should.eql [ 'asdfgfdgf' ]
      p = new Parser '\n\r%ADD10C,10*%\n\r'
      result = p.nextCommand()
      result.should.eql [ '%', 'ADD10C,10', '%' ]
    it 'should keep keep getting the next command', ->
      p = new Parser 'abcd*efgh*'
      (p.nextCommand()).should.eql [ 'abcd' ]
      (p.nextCommand()).should.eql [ 'efgh' ]
