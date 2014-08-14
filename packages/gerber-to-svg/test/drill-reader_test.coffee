# test suit for the NC drill file parser
Reader = require '../src/drill-reader'

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
    r.nextBlock().should.eql 'M48'
    r.nextBlock().should.eql ';FORMAT={2:4/ absolute / inch / keep zeros}'
    r.nextBlock().should.eql 'FMAT,2'
    r.nextBlock().should.eql 'INCH,TZ'

  it 'should return false when there are no more data blocks', ->
    r.nextBlock() for i in [0...19]
    r.nextBlock().should.eql 'M30'
    r.nextBlock().should.be.false

  it 'should keep track of the line number', ->
    r.line.should.equal 1
    r.nextBlock()
    r.line.should.equal 2
    r.nextBlock()
    r.line.should.equal 3

  it 'should ignore CR to work with LF (unix) or CRLF (windows)', ->
    rWindows = new Reader 'M48\r\nFMAT,2\r\nINCH,TZ\r\nT1C0.015\r\n'
    rWindows.line.should.equal 1
    rWindows.nextBlock().should.eql 'M48'
    rWindows.line.should.equal 2
    rWindows.nextBlock().should.eql 'FMAT,2'
    rWindows.line.should.equal 3
    rWindows.nextBlock().should.eql 'INCH,TZ'
