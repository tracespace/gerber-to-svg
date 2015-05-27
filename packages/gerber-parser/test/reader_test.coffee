# test suite for stream based file reader
stream = require('stream')
expect = require('chai').expect
Reader = require('../src/reader')

describe 'file reader transform stream', ->
  reader = null
  beforeEach ->
    reader = new Reader()

  it 'should output a block and a line number', (done) ->
    reader.once 'readable', ->
      data = reader.read()
      expect(data.line).to.equal 1
      expect(data.block).to.equal 'G04 test the gerber reader'
      done()

    reader.write 'G04 test the gerber reader*'

  it 'should handle split lines', (done) ->
    blockCount = 0
    blocks = ['X2000D03', 'X2500D03', 'Y1500D03']

    handler = ->
      data = reader.read()
      expect(data.line).to.equal 1
      expect(data.block).to.equal blocks[blockCount++]
      if blockCount is 3
        reader.removeListener 'readable', handler
        done()

    reader.on 'readable', handler
    reader.write 'X2000'
    reader.write 'D03*X25'
    reader.write '00D03*Y15'
    reader.write '00D03*'

  it 'should count lines and ignore carriage returns', (done) ->
    blockCount = 0
    blocks = ['X2000D03', 'X2500D03', 'Y1500D03']

    handler = ->
      data = reader.read()
      expect(data.line).to.equal blockCount + 1
      expect(data.block).to.equal blocks[blockCount++]
      if blockCount is 3
        reader.removeListener 'readable', handler
        done()

    reader.on 'readable', handler
    reader.write 'X2000D03*\n'
    reader.write 'X2500D03*\r\n'
    reader.write 'Y1500D03*\n'

  it 'should recognize params', (done) ->
    reader.once 'readable', ->
      data = reader.read()
      expect(data.param).to.equal 'FSLAX24Y24'
      done()

    reader.write '%FSLAX24Y24*%'

  it 'should recognize multiple param blocks', (done) ->
    paramCount = 0
    params = ['FSLAX24Y24', 'MOIN', 'ADD10C,0.01']

    handler = ->
      data = reader.read()
      expect(data.param).to.equal params[paramCount++]
      if paramCount is 3
        reader.removeListener 'readable', handler
        done()

    reader.on 'readable', handler
    reader.write '%FSLAX24Y24*MOIN*ADD10C,0.01*%'
