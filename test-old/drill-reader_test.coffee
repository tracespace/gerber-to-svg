# test suit for the NC drill file parser
Reader = require '../src/drill-reader'
expect = require('chai').expect

# twenty line test file
TEST_DRILL = '''
  M48
  ;FORMAT={2:4/ absolute / inch / keep zeros}
  FMAT,2
  INCH,TZ
  T1C0.015
  T2C0.020
  %
  G90
  G05
  M72
  T1
  X001600Y015800
  X003250Y014000
  X003700Y014000
  T2
  X001050Y011450
  X001200Y018900
  X004500Y024750
  T0
  M30
'''

describe 'drill file reader class', ->
  r = null
  beforeEach ->
    r = new Reader TEST_DRILL

  it 'should get the next data block', ->
    expect( r.nextBlock() ).to.eql 'M48'
    expect( r.nextBlock() ).to.eql ';FORMAT={2:4/ absolute / inch / keep zeros}'
    expect( r.nextBlock() ).to.eql 'FMAT,2'
    expect( r.nextBlock() ).to.eql 'INCH,TZ'

  it 'should return false when there are no more data blocks', ->
    r.nextBlock() for i in [0...19]
    expect( r.nextBlock() ).to.eql 'M30'
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
    rWindows = new Reader 'M48\r\nFMAT,2\r\nINCH,TZ\r\nT1C0.015\r\n'
    expect( rWindows.line ).to.equal 0
    expect( rWindows.nextBlock() ).to.eql 'M48'
    expect( rWindows.line ).to.equal 1
    expect( rWindows.nextBlock() ).to.eql 'FMAT,2'
    expect( rWindows.line ).to.equal 2
    expect( rWindows.nextBlock() ).to.eql 'INCH,TZ'
    expect( rWindows.line ).to.equal 3
