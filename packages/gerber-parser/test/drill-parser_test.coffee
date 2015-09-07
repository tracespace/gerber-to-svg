# test suit for the NC drill file parser
expect = require('chai').expect
Parser = require '../src/drill-parser'

# warnings hook
warnings = require './warn-capture'
# svg coordinate scaling factor
factor = require('../src/svg-coord').factor

describe 'NC drill file parser', ->
  p = null
  beforeEach -> p = new Parser()

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


  it 'should return a set tool for a bare tool number', ->
    expect( p.parseCommand('T1') ).to.eql { set: { currentTool: 'T1' } }
    expect( p.parseCommand('T14') ).to.eql { set: { currentTool: 'T14' } }
  it 'should ignore leading zeros in tool name', ->
    expect( p.parseCommand('T01') ).to.eql { set: { currentTool: 'T1' } }
  it 'should return a set notation to abs with G90', ->
    expect( p.parseCommand('G90') ).to.eql { set: { notation: 'A' } }
  it 'should return a set notation to inc with G91', ->
    expect( p.parseCommand('G91') ).to.eql { set: { notation: 'I' } }

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
