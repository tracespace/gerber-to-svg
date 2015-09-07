// test suite for the top level gerber parser class
// test subset - parsing drill files
'use strict'

const expect = require('chai').expect
const partial = require('lodash.partial')

const parser = require('../lib/gerber-parser')

describe('gerber parser with gerber files', function() {
  let p
  const pFactory = partial(parser, {filetype: 'drill'})

  // convenience function to expect an array of results
  const expectResults = function(expected, done) {
    const handleData = function(res) {
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
        throw new Error(`should not have emitted: ${d}`)
      })
      p.once('warning', function(w) {
        throw new Error(`should not have warned: ${w.message}`)
      })
      p.once('error', function(e) {
        throw new Error(`should not have errored: ${e.message}`)
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
      })

      it('should set backupUnits and backupNota', function(done) {
        const expected = [
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
    const expected = [
      {cmd: 'done', line: 1},
      {cmd: 'done', line: 2}
    ]

    expectResults(expected, done)
    p.write('M00\n')
    p.write('M30\n')
  })


  describe('parsing unit set', function() {
    it('should set units and suppression with INCH / METRIC', function(done) {
      const expected = [
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
      const expected = [
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
    beforeEach(function() {
      p.format.zero = 'L'
      p.format.places = [2, 4]
    })

    it('should send a tool command', function(done) {
      const expectedTools = [
        {shape: 'circle', val: [0.015], hole: []},
        {shape: 'circle', val: [0.142], hole: []}
      ]
      const expected = [
        {cmd: 'tool', line: 1, key: '1', val: expectedTools[0]},
        {cmd: 'tool', line: 2, key: '13', val: expectedTools[1]}
      ]

      expectResults(expected, done)
      p.write('T1C0.015\n')
      p.write('T13C0.142\n')
    })

    // it 'should ignore feedrate and spindle speed', ->
    //   expect( p.parseCommand 'T1C0.01F100S5').to.eql {
    //     tool: { T1: { dia: .01 * factor } }
    //   }
    // it 'should ignore leading zeros in tool name', ->
    //   expect( p.parseCommand 'T01C0.015' ).to.eql {
    //     tool: { T1: { dia: .015 * factor } }
    //   }
  })
})
