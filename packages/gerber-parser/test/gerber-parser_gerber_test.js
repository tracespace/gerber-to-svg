// test suite for the top level gerber parser class
// test subset - parsing gerber files
'use strict'

const expect = require('chai').expect
const partial = require('lodash.partial')

const parser = require('../lib/gerber-parser')

describe('gerber parser with gerber files', function() {
  let p
  const pFactory = partial(parser, {filetype: 'gerber'})

  // convenience function to expect an array of results
  const expectResults = function(expected, done) {
    const handleData = function(res) {
      expect(res).to.eql(expected.shift())
      if (!expected.length) {
        p.removeListener('data', handleData)
        return done()
      }
    }

    p.on('data', handleData)
  }

  beforeEach(function() {
    p = pFactory()
  })

  it('should do nothing with comments', function(done) {
    p.once('data', function() {
      throw new Error('should not have emitted from comments')
    })

    p.write('G04 MOIN*')
    p.write('G04 this is a comment*')
    p.write('G04 D03*')
    p.write('G04 D02*')
    p.write('G04 G36*')
    p.write('G04 M02*')
    setTimeout(done, 1)
  })

  it('should end the file with a M02', function(done) {
    p.once('data', function(res) {
      expect(res.cmd).to.equal('done')
      expect(res.line).to.equal(0)
      done()
    })

    p.write('M02*\n')
  })

  describe('general set commands (G-codes)', function() {
    it('should set region mode on/off with G36/7', function(done) {
      const expected = [
        {cmd: 'set', key: 'region', val: true, line: 0},
        {cmd: 'set', key: 'region', val: false, line: 1}
      ]

      expectResults(expected, done)
      p.write('G36*\nG37*\n')
    })

    it('should set interpolation mode with G01/2/3', function(done) {
      const expected = [
        {cmd: 'set', key: 'mode', val: 'i', line: 0},
        {cmd: 'set', key: 'mode', val: 'cw', line: 1},
        {cmd: 'set', key: 'mode', val: 'ccw', line: 2},
        {cmd: 'set', key: 'mode', val: 'i', line: 3},
        {cmd: 'set', key: 'mode', val: 'cw', line: 4},
        {cmd: 'set', key: 'mode', val: 'ccw', line: 5}
      ]

      expectResults(expected, done)
      p.write('G01*\nG02*\nG03*\n')
      p.write('G1*\nG2*\nG3*\n')
    })

    it('should set the arc mode with G74/5', function(done) {
      const expected = [
        {cmd: 'set', key: 'arc', val: 's', line: 0},
        {cmd: 'set', key: 'arc', val: 'm', line: 1}
      ]

      expectResults(expected, done)
      p.write('G74*\nG75*\n')
    })
  })

  describe('unit set commands (MO parameter)', function() {
    it('should set units with %MOIN*% and %MOMM*%', function(done) {
      const expected = [
        {cmd: 'set', key: 'units', val: 'in', line: 0},
        {cmd: 'set', key: 'units', val: 'mm', line: 1}
      ]

      expectResults(expected, done)
      p.write('%MOIN*%\n')
      p.write('%MOMM*%\n')
    })

    it('should set backup units with G70/1', function(done) {
      const expected = [
        {cmd: 'set', key: 'backupUnits', val: 'in', line: 0},
        {cmd: 'set', key: 'backupUnits', val: 'mm', line: 1}
      ]

      expectResults(expected, done)
      p.write('G70*\nG71*\n')
    })
  })

  describe('format block', function() {
    it('should parse zero suppression', function() {
      let format = '%FSLAX34Y34*%'
      p.write(format)
      expect(p.format.zero).to.equal('L')

      p = pFactory()
      format = '%FSTAX34Y34*%'
      p.write(format)
      expect(p.format.zero).to.equal('T')
    })

    it('should warn trailing suppression is deprected', function(done) {
      p.once('warning', function(w) {
        expect(w.line).to.equal(0)
        expect(w.message).to.match(/trailing zero suppression/)
        done()
      })

      p.write('%FSTAX34Y34*%\n')
    })

    it('should parse places format', function() {
      let format = '%FSLAX34Y34*%'
      p.write(format)
      expect(p.format.places).to.eql([3, 4])

      p = pFactory()
      format = '%FSLAX77Y77*%'
      p.write(format)
      expect(p.format.places).to.eql([7, 7])
    })

    it('should not override user-set places or suppression', function() {
      const format = '%FSLAX34Y34*%'
      p.format.zero = 'T'
      p.format.places = [7, 7]
      p.write(format)
      expect(p.format.zero).to.equal('T')
      expect(p.format.places).to.eql([7, 7])
    })

    it('should set notation and epsilon', function(done) {
      const format1 = '%FSLAX34Y34*%\n'
      const format2 = '%FSLIX77Y77*%\n'
      // ensure it parses if suppression is missing
      const format3 = '%FSAX66Y66*%\n'
      const expected = [
        {cmd: 'set', line: 0, key: 'nota', val: 'A'},
        {cmd: 'set', line: 0, key: 'epsilon', val: 0.15},
        {cmd: 'set', line: 1, key: 'nota', val: 'I'},
        {cmd: 'set', line: 1, key: 'epsilon', val: 0.00015},
        {cmd: 'set', line: 2, key: 'nota', val: 'A'},
        {cmd: 'set', line: 2, key: 'epsilon', val: 0.0015}
      ]

      expectResults(expected, done)
      // clear places format between writes to simulate new parsers
      p.write(format1)
      p.format.places = []
      p.write(format2)
      p.format.places = []
      p.write(format3)
    })

    it('should warn and set leading if suppression missing', function(done) {
      const format = '%FSAX34Y34*%\n'
      p.once('warning', function(w) {
        expect(w.line).to.equal(0)
        expect(w.message).to.match(/suppression missing/)
        expect(p.format.zero).to.equal('L')
        done()
      })

      p.write(format)
    })
  })

  describe('new level commands (SR/LP parameters)', function() {
    it('should parse a new level polarity', function(done) {
      const expected = [
        {cmd: 'level', line: 0, key: 'polarity', val: 'D'},
        {cmd: 'level', line: 1, key: 'polarity', val: 'C'}
      ]

      expectResults(expected, done)
      p.write('%LPD*%\n%LPC*%')
    })

    it('should parse a new step-repeat level', function(done) {
      const expected = [
        {
          cmd: 'level',
          line: 0,
          key: 'stepRep',
          val: {x: 1, y: 1, i: 0, j: 0}
        },
        {
          cmd: 'level',
          line: 1,
          key: 'stepRep',
          val: {x: 2, y: 3, i: 2000, j: 3000}
        },
        {
          cmd: 'level',
          line: 2,
          key: 'stepRep',
          val: {x: 1, y: 1, i: 0, j: 0}
        }
      ]

      expectResults(expected, done)
      p.format.places = [2, 2]
      p.write('%SRX1Y1I0J0*%\n')
      p.write('%SRX2Y3I2.0J3.0*%\n')
      p.write('%SR*%\n')
    })
  })

  describe('tool changes and definitions', function() {
    beforeEach(function() {
      p.format.zero = 'L'
      p.format.places = [2, 2]
    })

    it('should parse a tool change block', function(done) {
      const expected = [
        {cmd: 'set', line: 0, key: 'tool', val: '10'},
        {cmd: 'set', line: 1, key: 'tool', val: '11'},
        {cmd: 'set', line: 2, key: 'tool', val: '12'}
      ]

      expectResults(expected, done)
      p.write('D10*\n')
      p.write('G54D11*\n')
      p.write('D00012*\n')
    })

    it('should handle standard circles', function(done) {
      const expectedTools = [
        {shape: 'circle', val: 1000, hole: 0},
        {shape: 'circle', val: 1000, hole: 100},
        {shape: 'circle', val: 1000, hole: [200, 300]}
      ]
      const expected = [
        {cmd: 'tool', line: 0, key: '10', val: expectedTools[0]},
        {cmd: 'tool', line: 1, key: '11', val: expectedTools[1]},
        {cmd: 'tool', line: 2, key: '12', val: expectedTools[2]}
      ]

      expectResults(expected, done)
      p.write('%ADD10C,1*%\n')
      p.write('%ADD11C,1X0.1*%\n')
      p.write('%ADD12C,1X0.2X0.3*%\n')
    })

    it('should handle standard rectangles/obrounds', function(done) {
      const expectedTools = [
        {shape: 'rect', val: [1000, 2000], hole: 0},
        {shape: 'obround', val: [3000, 4000], hole: 100},
        {shape: 'rect', val: [5000, 6000], hole: [200, 300]}
      ]
      const expected = [
        {cmd: 'tool', line: 0, key: '10', val: expectedTools[0]},
        {cmd: 'tool', line: 1, key: '11', val: expectedTools[1]},
        {cmd: 'tool', line: 2, key: '12', val: expectedTools[2]}
      ]

      expectResults(expected, done)
      p.write('%ADD10R,1X2*%\n')
      p.write('%ADD11O,3.0X4.0X0.1*%\n')
      p.write('%ADD12R,5X6X0.2X0.3*%\n')
    })

    it('should handle standard polygons', function(done) {
      const expectedTools = [
        {shape: 'poly', val: [1000, 5], hole: 0},
        {shape: 'poly', val: [2000, 6, 45], hole: 0},
        {shape: 'poly', val: [3000, 7, 0], hole: 100},
        {shape: 'poly', val: [4000, 8, 0], hole: [200, 300]}
      ]
      const expected = [
        {cmd: 'tool', line: 0, key: '10', val: expectedTools[0]},
        {cmd: 'tool', line: 1, key: '11', val: expectedTools[1]},
        {cmd: 'tool', line: 2, key: '12', val: expectedTools[2]},
        {cmd: 'tool', line: 3, key: '13', val: expectedTools[3]}
      ]

      expectResults(expected, done)
      p.write('%ADD10P,1X5*%\n')
      p.write('%ADD11P,2X6X45*%\n')
      p.write('%ADD12P,3X7X0X0.1*%\n')
      p.write('%ADD13P,4X8X0X0.2X0.3*%\n')
    })

    it('should handle aperture macros', function(done) {
      const expectedTools = [
        {shape: 'CIRC', val: [1, 0.5], hole: 0},
        {shape: 'RECT', val: [], hole: 0}
      ]
      const expected = [
        {cmd: 'tool', line: 0, key: '10', val: expectedTools[0]},
        {cmd: 'tool', line: 1, key: '11', val: expectedTools[1]}
      ]

      expectResults(expected, done)
      p.write('%ADD10CIRC,1X0.5*%\n')
      p.write('%ADD11RECT*%\n')
    })
  })

  describe('aperture macros', function() {

  })

  describe('operations', function() {
    beforeEach(function() {
      p.format.zero = 'L'
      p.format.places = [2,4]
    })

    it('should parse an interpolation command', function(done) {
      const expected = [
        {cmd: 'op', line: 0, key: 'int', val: {x: 10, y: 20, i: 30, j: 40}},
        {cmd: 'op', line: 1, key: 'int', val: {x: 11, y: 0}},
        {cmd: 'op', line: 2, key: 'int', val: {x: 22}},
        {cmd: 'op', line: 3, key: 'int', val: {y: 33}},
        {cmd: 'op', line: 4, key: 'int', val: {}}
      ]

      expectResults(expected, done)
      p.write('X100Y200I300J400D01*\n')
      p.write('X110Y0D01*\n')
      p.write('X220D1*\n')
      p.write('Y330D1*\n')
      p.write('D01*\n')
    })

    it('should parse a move command', function(done) {
      const expected = [
        {cmd: 'op', line: 0, key: 'move', val: {x: 30, y: 0.1}},
        {cmd: 'op', line: 1, key: 'move', val: {x: -10}},
        {cmd: 'op', line: 2, key: 'move', val: {}}
      ]

      expectResults(expected, done)
      p.write('X300Y1D02*\n')
      p.write('X-100D2*\n')
      p.write('D02*\n')
    })

    it('should parse a flash command', function(done) {
      const expected = [
        {cmd: 'op', line: 0, key: 'flash', val: {x: 30, y: 0.1}},
        {cmd: 'op', line: 1, key: 'flash', val: {x: -10}},
        {cmd: 'op', line: 2, key: 'flash', val: {}}
      ]

      expectResults(expected, done)
      p.write('X300Y1D03*\n')
      p.write('X-100D3*\n')
      p.write('D03*\n')
    })

    it('should send "last" operation if op code is missing', function(done) {
      const expected = [
        {cmd: 'op', line: 0, key: 'last', val: {x: 30, y: 0.1}},
        {cmd: 'op', line: 1, key: 'last', val: {x: -10}}
      ]

      expectResults(expected, done)
      p.write('X300Y1*\n')
      p.write('X-100*\n')
    })

    it('should interpolate with inline mode set', function(done) {
      const expected = [
        {cmd: 'set', line: 0, key: 'mode', val: 'i'},
        {cmd: 'op', line: 0, key: 'int', val: {x: 0.1, y: 0.1}},
        {cmd: 'set', line: 1, key: 'mode', val: 'cw'},
        {cmd: 'op', line: 1, key: 'int', val: {x: 0.1, y: 0.1}},
        {cmd: 'set', line: 2, key: 'mode', val: 'ccw'},
        {cmd: 'op', line: 2, key: 'int', val: {x: 0.1, y: 0.1}}
      ]

      expectResults(expected, done)
      p.write('G01X01Y01D01*\n')
      p.write('G02X01Y01D01*\n')
      p.write('G03X01Y01D01*\n')
    })
  })
})
