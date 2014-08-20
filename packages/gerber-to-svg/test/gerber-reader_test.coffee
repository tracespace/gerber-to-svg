# test suite for the gerber file reader
Reader = require '../src/gerber-reader'

# twenty command, twenty line gerber file
TEST_GERBER = '''
  G04 test the gerber reader*
  %FSLAX24Y24*%
  %MOIN*%
  %ADD10C,0.01*ADD11C,0.06*%
  ￼￼￼￼￼D10*
  ￼￼￼￼￼￼X0Y250D02*
  ￼￼￼￼￼￼G01X0Y0D01*
  ￼￼￼￼￼￼G01X250Y0D01*
  ￼￼￼￼￼￼￼￼X1000Y1000D02*
  ￼￼￼￼￼￼G01X1500D01*
  ￼￼￼￼￼￼￼￼G01X2000Y1500D01*
  ￼￼￼￼￼￼￼￼X2500D02*
  ￼￼￼￼￼￼￼￼G01Y1000D01*
  ￼￼￼￼￼￼D11*
  ￼￼￼￼￼￼￼￼X1000Y1000D03*
  ￼￼￼￼￼￼X2000D03*
  ￼￼￼￼￼￼X2500D03*
  ￼￼￼￼￼￼Y1500D03*
￼￼￼￼￼￼  X2000D03*
  M02*
'''

describe 'gerber reader class', ->
  r = null
  beforeEach ->
    r = new Reader TEST_GERBER

  it 'should get the next data block', ->
    # normal data blocks should come back as strings with the asterisk removed
    r.nextBlock().should.eql { block: 'G04 test the gerber reader' }
    # parameter blocks should come back as arrays of strings with the % removed
    r.nextBlock().should.eql { param: [ 'FSLAX24Y24' ] }
    r.nextBlock().should.eql { param: [ 'MOIN' ] }
    r.nextBlock().should.eql { param: [ 'ADD10C,0.01', 'ADD11C,0.06' ] }
    r.nextBlock().should.eql { block: 'D10' }

  it 'should return false when there are no more data blocks', ->
    r.nextBlock() for i in [0...19]
    r.nextBlock().should.eql { block: 'M02' }
    r.nextBlock().should.be.false

  it 'should keep track of the line number', ->
    r.line.should.equal 0
    r.nextBlock()
    r.line.should.equal 1
    r.nextBlock()
    r.line.should.equal 2
    r.nextBlock()
    r.line.should.equal 3

  it 'should ignore CR to work with LF (unix) or CRLF (windows)', ->
    rWindows = new Reader 'G04crlf*\r\n%FSLAX24Y24*%\r\n%MOIN*%\r\n%ADD10C,0.01*%'
    rWindows.line.should.equal 0
    rWindows.nextBlock().should.eql { block: 'G04crlf' }
    rWindows.line.should.equal 1
    rWindows.nextBlock().should.eql { param: [ 'FSLAX24Y24' ] }
    rWindows.line.should.equal 2
    rWindows.nextBlock().should.eql { param: [ 'MOIN' ] }
    rWindows.line.should.equal 3
    rWindows.nextBlock().should.eql { param: [ 'ADD10C,0.01' ] }
    rWindows.line.should.equal 4

  it 'should handle multiple blocks on one line', ->
    oneLine = new Reader 'G04 comment*%FSLAX24Y24*%G04 woo*'
    oneLine.line.should.equal 0
    oneLine.nextBlock().should.eql { block: 'G04 comment' }
    oneLine.line.should.equal 1
    oneLine.nextBlock().should.eql { param: [ 'FSLAX24Y24' ] }
    oneLine.line.should.equal 1
    oneLine.nextBlock().should.eql { block: 'G04 woo' }
    oneLine.line.should.equal 1
