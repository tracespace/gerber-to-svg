# test suit for the NC drill file parser
expect = require('chai').expect
Parser = require '../src/drill-parser'

# warnings hook
warnings = require './warn-capture'
# svg coordinate scaling factor
factor = require('../src/svg-coord').factor

describe 'NC drill file parser', ->
  p = null
  beforeEach -> p = new Parser

  it "should ignore comments (start with ';')", ->
    initialFmat = p.fmat
    initialFormat = { zero: p.format.zero, places: p.format.places }
    expect( p.parseCommand ';INCH' ).to.eql {}
    expect( p.parseCommand ';M71' ).to.eql {}
    expect( p.parseCommand ';T1C0.015' ).to.eql {}
    expect( p.parseCommand ';T1' ).to.eql {}
    expect( p.parseCommand ';X0016Y0158' ).to.eql {}
    expect( p.parseCommand ';INCH,TZ' ).to.eql {}
    expect( p.fmat ).to.eql initialFmat
    expect( p.format ).to.eql initialFormat
  it 'should return a done command with M00 or M30', ->
    expect( p.parseCommand 'M00' ).to.eql { set: { done: true } }
    expect( p.parseCommand 'M30' ).to.eql { set: { done: true } }
  it 'should return a set units command with INCH and METRIC', ->
    expect( p.parseCommand 'INCH' ).to.eql { set: { units: 'in' } }
    expect( p.parseCommand 'METRIC' ).to.eql { set: { units: 'mm' } }
  it 'should also set units with M71 and M72', ->
    expect( p.parseCommand 'M71' ).to.eql { set: { units: 'mm' } }
    expect( p.parseCommand 'M72' ).to.eql { set: { units: 'in' } }
  it 'should be able to set the zero suppression', ->
    # excellon specifies which zeros to keep
    # also check that whitespace doesn't throw it off
    p.parseCommand 'INCH,TZ'
    expect( p.format.zero ).to.eql 'L'
    p.parseCommand 'INCH,LZ'
    expect( p.format.zero ).to.eql 'T'
    p.parseCommand 'INCH,TZ'
    expect( p.format.zero ).to.eql 'L'
    p.parseCommand 'INCH,LZ'
    expect( p.format.zero ).to.eql 'T'
  it 'should warn and fall back to leading suppression if unspecified', ->
    p.format.places = [2,4]
    # have a backup
    expect( p.format.zero? ).to.not.be.true
    warnings.hook()
    p.parseCommand 'X50Y15500'
    expect( p.format.zero ).to.eql 'L'
    expect( warnings.unhook() ).to.match /assuming leading zero suppression/
  it 'should warn and fall back to 2:4 format if unspecified', ->
    p.format.zero = 'L'
    expect( p.format.places? ).to.not.be.true
    warnings.hook()
    p.parseCommand 'X50Y15500'
    expect( p.format.places ).to.eql [ 2, 4 ]
    expect( warnings.unhook() ).to.match /assuming 2\:4/
  it 'should use 3.3 format for metric and 2.4 for inches', ->
    p.parseCommand 'INCH'
    expect( p.format.places ).to.eql [ 2, 4 ]
    p.parseCommand 'METRIC'
    expect( p.format.places ).to.eql [ 3, 3 ]
  describe 'tool definitions', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [ 2, 4 ]
    it 'should return a define tool command for tool definitions', ->
      expect( p.parseCommand 'T1C0.015' ).to.eql {
        tool: { T1: { dia: .015 * factor } }
      }
      expect( p.parseCommand 'T13C0.142' ).to.eql {
        tool: { T13: { dia: .142 * factor } }
      }
    it 'should ignore feedrate and spindle speed', ->
      expect( p.parseCommand 'T1C0.01F100S5').to.eql {
        tool: { T1: { dia: .01 * factor } }
      }
    it 'should ignore leading zeros in tool name', ->
      expect( p.parseCommand 'T01C0.015' ).to.eql {
        tool: { T1: { dia: .015 * factor } }
      }
  it 'should assume FMAT,2, but identify FMAT,1', ->
    expect( p.fmat ).to.eql 'FMAT,2'
    expect( p.parseCommand('FMAT,1') ).to.eql {}
    expect( p.fmat ).to.eql 'FMAT,1'
    expect( p.parseCommand('M70') ).to.eql { set: { units: 'in' } }
  it 'should return a set tool for a bare tool number', ->
    expect( p.parseCommand('T1') ).to.eql { set: { currentTool: 'T1' } }
    expect( p.parseCommand('T14') ).to.eql { set: { currentTool: 'T14' } }
  it 'should ignore leading zeros in tool name', ->
    expect( p.parseCommand('T01') ).to.eql { set: { currentTool: 'T1' } }
  it 'should return a set notation to abs with G90', ->
    expect( p.parseCommand('G90') ).to.eql { set: { notation: 'abs' } }
  it 'should return a set notation to inc with G91', ->
    expect( p.parseCommand('G91') ).to.eql { set: { notation: 'inc' } }
  it 'M70 (fmat1), M71, and M72 should still set units', ->
    expect( p.parseCommand('M71') ).to.eql { set: { units: 'mm' } }
    expect( p.parseCommand('M72') ).to.eql { set: { units: 'in' } }
    p.fmat = 'FMAT,1'
    expect( p.parseCommand('M70') ).to.eql { set: { units: 'in' } }

  describe 'drilling (flashing) at coordinates', ->
    it 'should parse the coordinates into numbers in suppress trailing zero', ->
      p.format.zero = 'T'
      p.format.places = [2,4]
      expect( p.parseCommand('X0016Y0158') ).to.eql {
        op: { do: 'flash', x: .16 * factor, y: 1.58 * factor}
      }
      expect( p.parseCommand('X-01795Y0108') ).to.eql {
        op: { do: 'flash', x: -1.795 * factor, y: 1.08 * factor }
      }
    it 'should parse coordinates with leading zeros suppressed', ->
      p.format.zero = 'L'
      p.format.places = [2,4]
      expect( p.parseCommand('X50Y15500') ).to.eql {
        op: { do: 'flash', x: .0050 * factor, y: 1.55 * factor }
      }
      expect( p.parseCommand('X16850Y-3300') ).to.eql {
        op: { do: 'flash', x: 1.685 * factor, y: -.33 * factor }
      }
    it 'should parse coordinates according to the places format', ->
      p.format.zero = 'L'
      p.format.places = [2,4]
      expect( p.parseCommand('X7550Y14000') ).to.eql {
        op: { do: 'flash', x: .755 * factor, y: 1.4 * factor }
      }
      p.format.places = [3,3]
      expect( p.parseCommand('X7550Y14') ).to.eql {
        op: { do: 'flash', x: 7.55 * factor, y: .014 * factor }
      }
      p.format.zero = 'T'
      p.format.places = [2,4]
      expect( p.parseCommand('X08Y0124') ).to.eql {
        op: { do: 'flash', x: 8 * factor, y: 1.24 * factor }
      }
      p.format.places = [3,3]
      expect( p.parseCommand('X08Y0124') ).to.eql {
        op: { do: 'flash', x: 80 * factor, y: 12.4 * factor }
      }
    it 'should parse decimal coordinates', ->
      p.format.zero = 'L'
      p.format.places = [2,4]
      expect( p.parseCommand('X0.7550Y1.4000') ).to.eql {
        op: { do: 'flash', x: 0.755 * factor, y: 1.4 * factor }
      }
      p.format.places = [3,3]
      expect( p.parseCommand('X7.550Y14') ).to.eql {
        op: { do: 'flash', x: 7.55 * factor, y: .014 * factor }
      }
    it 'should recognize a tool change at the beginning or end of the line', ->
      p.format.zero = 'T'
      p.format.places = [2,4]
      expect( p.parseCommand('T01X01Y01') ).to.eql {
        set: { currentTool: 'T1' }
        op: { do: 'flash', x: 1 * factor, y: 1 * factor }
      }
      expect( p.parseCommand('X01Y01T01') ).to.eql {
        set: { currentTool: 'T1' }
        op: { do: 'flash', x: 1 * factor, y: 1 * factor }
      }
