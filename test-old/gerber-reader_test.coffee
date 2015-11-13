# test suite for the gerber file reader
Reader = require '../src/gerber-reader'
expect = require('chai').expect

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
    expect( r.nextBlock() ).to.eql { block: 'G04 test the gerber reader' }
    # parameter blocks should come back as arrays of strings with the % removed
    expect( r.nextBlock() ).to.eql { param: [ 'FSLAX24Y24' ] }
    expect( r.nextBlock() ).to.eql { param: [ 'MOIN' ] }
    expect( r.nextBlock() ).to.eql { param: [ 'ADD10C,0.01', 'ADD11C,0.06' ] }
    expect( r.nextBlock() ).to.eql { block: 'D10' }

  it 'should return false when there are no more data blocks', ->
    r.nextBlock() for i in [0...19]
    expect( r.nextBlock() ).to.eql { block: 'M02' }
    expect( r.nextBlock() ).to.be.false

  it 'should keep track of the line number', ->
    expect( r.line ).to.equal 0
    r.nextBlock()
    expect( r.line ).to.equal 1
    r.nextBlock()
    expect( r.line ).to.equal 2
    r.nextBlock()
    expect( r.line ).to.equal 3

  it 'should ignore CR to work with LF (unix) or CRLF (windows)', ->
    rWindows = new Reader 'G04cl*\r\n%FSLAX24Y24*%\r\n%MOIN*%\r\n%ADD10C,0.01*%'
    expect( rWindows.line ).to.equal 0
    expect( rWindows.nextBlock() ).to.eql { block: 'G04cl' }
    expect( rWindows.line ).to.equal 1
    expect( rWindows.nextBlock() ).to.eql { param: [ 'FSLAX24Y24' ] }
    expect( rWindows.line ).to.equal 2
    expect( rWindows.nextBlock() ).to.eql { param: [ 'MOIN' ] }
    expect( rWindows.line ).to.equal 3
    expect( rWindows.nextBlock() ).to.eql { param: [ 'ADD10C,0.01' ] }
    expect( rWindows.line ).to.equal 4

  it 'should handle multiple blocks on one line', ->
    oneLine = new Reader 'G04 comment*%FSLAX24Y24*%G04 woo*'
    expect( oneLine.line ).to.equal 0
    expect( oneLine.nextBlock() ).to.eql { block: 'G04 comment' }
    expect( oneLine.line ).to.equal 1
    expect( oneLine.nextBlock() ).to.eql { param: [ 'FSLAX24Y24' ] }
    expect( oneLine.line ).to.equal 1
    expect( oneLine.nextBlock() ).to.eql { block: 'G04 woo' }
    expect( oneLine.line ).to.equal 1
