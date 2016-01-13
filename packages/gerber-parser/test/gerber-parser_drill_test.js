// test suite for the top level gerber parser class
// test subset - parsing drill files
'use strict'

var expect = require('chai').expect
var partial = require('lodash.partial')

var parser = require('../lib')

describe('gerber parser with gerber files', function() {
  var p
  var pFactory = partial(parser, {filetype: 'drill'})

  // convenience function to expect an array of results
  var expectResults = function(expected, done) {
    var handleData = function(res) {
      expect(res).to.eql(expected.shift())
      if (!expected.length) {
        return done()
      }
    }

    p.on('data', handleData)
  }

  beforeEach(function() {
    p = pFactory()
  })

  afterEach(function() {
    p.removeAllListeners('data')
    p.removeAllListeners('warning')
    p.removeAllListeners('error')
  })

  describe('comments', function() {
    it('should do nothing with most comments', function(done) {
      p.once('data', function(d) {
        throw new Error('should not have emitted: ' + d)
      })
      p.once('warning', function(w) {
        throw new Error('should not have warned: ' + w.message)
      })
      p.once('error', function(e) {
        throw new Error('should not have errored: ' + e.message)
      })

      p.write(';INCH\n')
      p.write(';this is a comment\n')
      p.write(';M71\n')
      p.write(';T1C0.015\n')
      p.write(';T1\n')
      p.write(';X0016Y0158\n')
      setTimeout(done, 1)
    })

    describe('kicad format hints', function() {
      it('should set format and suppresion if included', function() {
        p.write(';FORMAT={3:3/ absolute / metric / suppress trailing zeros}\n')
        expect(p.format.zero).to.equal('T')
        expect(p.format.places).to.eql([3, 3])

        p = pFactory()
        p.write(';FORMAT={2:4/ absolute / inch / suppress leading zeros}\n')
        expect(p.format.zero).to.equal('L')
        expect(p.format.places).to.eql([2, 4])

        p = pFactory()
        p.write(';FORMAT={-:-/ absolute / inch / decimal}\n')
        expect(p.format.zero).to.equal('D')
        expect(p.format.places).to.eql([])

        p = pFactory()
        p.write(';FORMAT={3:3/ absolute / metric / keep zeros}\n')
        expect(p.format.zero).to.equal('L')
        expect(p.format.places).to.eql([3, 3])
      })

      it('should set backupUnits and backupNota', function(done) {
        var expected = [
          {cmd: 'set', line: 1, key: 'backupNota', val: 'A'},
          {cmd: 'set', line: 1, key: 'backupUnits', val: 'mm'},
          {cmd: 'set', line: 2, key: 'backupNota', val: 'I'},
          {cmd: 'set', line: 2, key: 'backupUnits', val: 'in'}
        ]

        expectResults(expected, done)
        p.write(';FORMAT={3:3/ absolute / metric / suppress trailing zeros}\n')
        p.write(';FORMAT={2:4/ incremental / inch / suppress leading zeros}\n')
      })
    })
  })

  it('should call done with M00 and M30', function(done) {
    var expected = [
      {cmd: 'done', line: 1},
      {cmd: 'done', line: 2}
    ]

    expectResults(expected, done)
    p.write('M00\n')
    p.write('M30\n')
  })

  it('should set notation with G90 and G91', function(done) {
    var expected = [
      {cmd: 'set', line: 1, key: 'nota', val: 'A'},
      {cmd: 'set', line: 2, key: 'nota', val: 'I'}
    ]

    expectResults(expected, done)
    p.write('G90\n')
    p.write('G91\n')
  })

  describe('parsing unit set', function() {
    it('should set units and suppression with INCH / METRIC', function(done) {
      var expected = [
        {cmd: 'set', line: 1, key: 'units', val: 'in'},
        {cmd: 'set', line: 2, key: 'units', val: 'mm'},
        {cmd: 'set', line: 3, key: 'units', val: 'in'},
        {cmd: 'set', line: 4, key: 'units', val: 'mm'}
      ]

      expectResults(expected, done)
      p.write('INCH\n')
      p.write('METRIC\n')
      p.write('INCH,TZ\n')
      p.write('METRIC,LZ\n')
    })

    it('should set units with M71 and M72', function(done) {
      var expected = [
        {cmd: 'set', line: 1, key: 'units', val: 'in'},
        {cmd: 'set', line: 2, key: 'units', val: 'mm'}
      ]

      expectResults(expected, done)
      p.write('M72\n')
      p.write('M71\n')
    })

    it('should set places format when the units are set', function() {
      p.write('M71\n')
      expect(p.format.places).to.eql([3, 3])

      p = pFactory()
      p.write('M72\n')
      expect(p.format.places).to.eql([2, 4])

      p = pFactory()
      p.write('METRIC\n')
      expect(p.format.places).to.eql([3, 3])

      p = pFactory()
      p.write('INCH\n')
      expect(p.format.places).to.eql([2, 4])
    })

    it('should not overwrite places format', function() {
      p.format.places = [3, 4]

      p.write('M71\n')
      expect(p.format.places).to.eql([3, 4])
      p.write('M72\n')
      expect(p.format.places).to.eql([3, 4])
      p.write('INCH\n')
      expect(p.format.places).to.eql([3, 4])
      p.write('METRIC\n')
      expect(p.format.places).to.eql([3, 4])
    })
  })

  describe('setting zero suppression', function() {
    it('should set zero suppression if included with units', function() {
      p.write('INCH,TZ\n')
      expect(p.format.zero).to.equal('L')

      p = pFactory()
      p.write('METRIC,LZ\n')
      expect(p.format.zero).to.equal('T')
    })

    it('should not overwrite suppression', function() {
      p.format.zero = 'L'
      p.write('METRIC,LZ\n')
      p.write('INCH,LZ\n')
      expect(p.format.zero).to.equal('L')

      p.format.zero = 'T'
      p.write('METRIC,TZ\n')
      p.write('INCH,TZ\n')
      expect(p.format.zero).to.equal('T')
    })
  })

  describe('parsing tool definitions', function() {
    it('should send a tool command', function(done) {
      var expectedTools = [
        {shape: 'circle', val: [0.015], hole: []},
        {shape: 'circle', val: [0.142], hole: []}
      ]
      var expected = [
        {cmd: 'tool', line: 1, key: '1', val: expectedTools[0]},
        {cmd: 'tool', line: 2, key: '13', val: expectedTools[1]}
      ]

      expectResults(expected, done)
      p.write('T1C0.015\n')
      p.write('T13C0.142\n')
    })

    it('should ignore feedrate and spindle speed', function(done) {
      var expectedTools = [
        {shape: 'circle', val: [0.01], hole: []}
      ]
      var expected = [
        {cmd: 'tool', line: 1, key: '1', val: expectedTools[0]}
      ]

      expectResults(expected, done)
      p.write('T1C0.01F100S5\n')
    })

    it('should ignore leading zeros in tool name', function(done) {
      var expectedTools = [
        {shape: 'circle', val: [0.015], hole: []}
      ]
      var expected = [
        {cmd: 'tool', line: 1, key: '23', val: expectedTools[0]}
      ]

      expectResults(expected, done)
      p.write('T0023C0.015\n')
    })
  })

  it('should set the tool with a tool number', function(done) {
    var expected = [
      {cmd: 'set', line: 1, key: 'tool', val: '1'},
      {cmd: 'set', line: 2, key: 'tool', val: '14'},
      {cmd: 'set', line: 3, key: 'tool', val: '5'},
      {cmd: 'set', line: 4, key: 'tool', val: '0'},
      {cmd: 'set', line: 5, key: 'tool', val: '0'}
    ]

    expectResults(expected, done)
    p.write('T1\n')
    p.write('T14\n')
    p.write('T0005\n')
    p.write('T0\n')
    p.write('T000\n')
  })

  describe('parsing drill commands', function() {
    it('should work with trailing suppression', function(done) {
      p.format.places = [2, 4]
      p.format.zero = 'T'

      var expected = [
        {cmd: 'op', line: 1, key: 'flash', val: {x: 0.16, y: 1.58}},
        {cmd: 'op', line: 2, key: 'flash', val: {x: -1.795, y: 1.08}}
      ]

      expectResults(expected, done)
      p.write('X0016Y0158\n')
      p.write('X-01795Y0108\n')
    })

    it('should work with leading zeros suppressed', function(done) {
      p.format.places = [2,4]
      p.format.zero = 'L'

      var expected = [
        {cmd: 'op', line: 1, key: 'flash', val: {x: 0.005, y: 1.55}},
        {cmd: 'op', line: 2, key: 'flash', val: {x: 1.685, y: -0.33}}
      ]

      expectResults(expected, done)
      p.write('X50Y15500\n')
      p.write('X16850Y-3300\n')
    })

    it('should parse with the places format', function(done) {
      var expected = [
        {cmd: 'op', line: 1, key: 'flash', val: {x: .755, y: 1.4}},
        {cmd: 'op', line: 2, key: 'flash', val: {x: 7.55, y: 0.014}},
        {cmd: 'op', line: 3, key: 'flash', val: {x: 8, y: 1.24}},
        {cmd: 'op', line: 4, key: 'flash', val: {x: 80, y: 12.4}}
      ]

      expectResults(expected, done)

      p.format.places = [2,4]
      p.format.zero = 'L'
      p.write('X7550Y14000\n')

      p.format.places = [3,3]
      p.write('X7550Y14\n')

      p.format.zero = 'T'
      p.format.places = [2,4]
      p.write('X08Y0124\n')

      p.format.places = [3,3]
      p.write('X08Y0124\n')
    })

    it('should parse decimal coordinates', function(done) {
      p.format.zero = 'L'
      p.format.places = [2,4]

      var expected = [
        {cmd: 'op', line: 1, key: 'flash', val: {x: 0.755, y: 1.4}}
      ]

      expectResults(expected, done)
      p.write('X0.7550Y1.4000\n')
    })

    it('should parse tool change at beginning / end of line', function(done) {
      p.format.zero = 'T'
      p.format.places = [2,4]

      var expected = [
        {cmd: 'set', line: 1, key: 'tool', val: '1'},
        {cmd: 'op', line: 1, key: 'flash', val: {x: 1, y: 1}},
        {cmd: 'set', line: 2, key: 'tool', val: '1'},
        {cmd: 'op', line: 2, key: 'flash', val: {x: 1, y: 1}}
      ]

      expectResults(expected, done)
      p.write('T01X01Y01\n')
      p.write('X01Y01T01\n')
    })

    it('should warn / assume trailing if missing', function(done) {
      p.format.places = [2, 4]
      p.once('warning', function(w) {
        expect(w.message).to.match(/assuming trailing/)
        expect(p.format.zero).to.equal('T')
        done()
      })

      p.write('X1Y1\n')
    })

    it('should warn / assume [2, 4] places if missing', function(done) {
      p.format.zero = 'L'
      p.once('warning', function(w) {
        expect(w.message).to.match(/assuming \[2, 4\]/)
        expect(p.format.places).to.eql([2, 4])
        done()
      })

      p.write('X1Y1\n')
    })
  })

  describe('parsing slot commands', function() {
    it('should parse the slot commands', function(done) {
      p.format.places = [2, 4]
      p.format.zero = 'T'

      var expected = [
        {cmd: 'op', line: 1, key: 'move', val: {x: 0.16, y: 1.58}},
        {cmd: 'set', line: 1, key: 'mode', val: 'i'},
        {cmd: 'op', line: 1, key: 'int', val: {x: 1.795, y: -1.08}},
        {cmd: 'op', line: 2, key: 'flash', val: {x: 1.23, y: -0.01}},
        {cmd: 'op', line: 3, key: 'move', val: {x: 2.0, y: 0.1}},
        {cmd: 'set', line: 3, key: 'mode', val: 'i'},
        {cmd: 'op', line: 3, key: 'int', val: {y: -0.1}},
        {cmd: 'op', line: 4, key: 'move', val: {y: 3.09}},
        {cmd: 'set', line: 4, key: 'mode', val: 'i'},
        {cmd: 'op', line: 4, key: 'int', val: {y: 3.29}}
      ]

      expectResults(expected, done)
      p.write('X0016Y0158G85X01795Y-0108\n')
      p.write('X0123Y-0001\n')
      p.write('X0200Y0010G85Y-0010\n')
      p.write('Y0309G85Y0329\n')
    })
  })
})
