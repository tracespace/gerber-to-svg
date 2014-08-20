# test suite for GerberParser class
Parser = require '../src/gerber-parser'
streamCapture = require './stream-capture'
stderr = -> streamCapture(process.stderr)

param = (p) -> { param: [ p ] }
block = (b) -> { block: b }

describe 'gerber command parser', ->
  p = null
  beforeEach -> p = new Parser

  it 'should ignore comments (start with G04)', ->
    initialFormat = { zero: p.format.zero, places: p.format.places }
    p.parseCommand(block 'G04 MOIN').should.eql {}
    p.parseCommand(block 'G04 this is a comment').should.eql {}
    p.parseCommand(block 'G04 D03').should.eql {}
    p.parseCommand(block 'G04 D02').should.eql {}
    p.parseCommand(block 'G04 G36').should.eql {}
    p.parseCommand(block 'G04 M02').should.eql {}
    p.format.should.eql initialFormat

  it 'should end the file with an M02', ->
    p.parseCommand(block 'M02').should.eql { set: { done: true } }

  describe 'units commands', ->
    it 'should return a set units with %MOIN*% and %MOMM*%', ->
      p.parseCommand(param 'MOIN').should.eql { set: { units: 'in' } }
      p.parseCommand(param 'MOMM').should.eql { set: { units: 'mm' } }

    it 'should throw an error for invalid units parameters', ->
      (-> p.parseCommand param 'MOKM').should.throw /invalid units/

    it 'should set backup units with G70 (in) and G71 (mm)', ->
      p.parseCommand(block 'G70').should.eql { set: { backupUnits: 'in' } }
      p.parseCommand(block 'G71').should.eql { set: { backupUnits: 'mm' } }

  describe 'operating modes', ->
    it 'should turn region mode on and off with a G36 and G37', ->
      p.parseCommand(block 'G36').should.eql { set: { region: true  } }
      p.parseCommand(block 'G37').should.eql { set: { region: false } }
    it 'should set the interpolation mode with G01, 2, and 3', ->
      p.parseCommand(block 'G01').should.eql { set: { mode: 'i'   } }
      p.parseCommand(block 'G1').should.eql  { set: { mode: 'i'   } }
      p.parseCommand(block 'G02').should.eql { set: { mode: 'cw'  } }
      p.parseCommand(block 'G2').should.eql  { set: { mode: 'cw'  } }
      p.parseCommand(block 'G03').should.eql { set: { mode: 'ccw' } }
      p.parseCommand(block 'G3').should.eql  { set: { mode: 'ccw' } }
    it 'should set the arc quadrant mode with G74 (single) and 75 (multi)', ->
      p.parseCommand(block 'G74').should.eql { set: { quad: 's' } }
      p.parseCommand(block 'G75').should.eql { set: { quad: 'm' } }

  describe 'operations', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [2,2]
    it 'should parse an interpolation command', ->
      p.parseCommand(block 'X22Y0D01').should.eql {
        op: { do: 'int', x: 0.22, y: 0 }
      }
      p.parseCommand(block 'Y110D1').should.eql {
        op: { do: 'int', y: 1.10 }
      }
    it 'should parse a move command', ->
      p.parseCommand(block 'X300Y1D02').should.eql {
        op: { do: 'move', x: 3, y: 0.01 }
      }
      p.parseCommand(block 'X-100D2').should.eql {
        op: { do: 'move', x: -1 }
      }
    it 'should parse a flash command', ->
      p.parseCommand(block 'X75Y-140D03').should.eql {
        op: { do: 'flash', x: 0.75, y: -1.4 }
      }
      p.parseCommand(block 'X1Y1D3').should.eql {
        op: { do: 'flash', x: 0.01, y: 0.01 }
      }
    it 'should interpolat with an inline mode set', ->
      p.parseCommand(block 'G01X01Y01D01').should.eql {
        set: { mode: 'i' }, op: { do: 'int', x: 0.01, y:0.01 }
      }
      p.parseCommand(block 'G02X01Y01D01').should.eql {
        set: { mode: 'cw' }, op: { do: 'int', x: 0.01, y:0.01 }
      }
      p.parseCommand(block 'G03X01Y01D01').should.eql {
        set: { mode: 'ccw' }, op: { do: 'int', x: 0.01, y:0.01 }
      }
