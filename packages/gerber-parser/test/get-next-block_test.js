// tests for function that gets the next block from a chunk
'use strict'

const expect = require('chai').expect
const partial = require('lodash.partial')
const getNextBlock = require('../lib/_get-next-block')

describe('get next block', function() {
  it ('should throw with a bad filetype', function() {
    const bad = function() {getNextBlock('foo', '', 0)}
    expect(bad).to.throw(/filetype/)
  })

  describe('from gerber files', function() {
    const getNext = partial(getNextBlock, 'gerber')

    it('should split at *', function() {
      const chunk = 'M02*'
      const result = getNext(chunk, 0)

      expect(result.block).to.equal('M02')
    })

    it('should return characters read', function() {
      const chunk = 'G01*G02*G03*'
      const res1 = getNext(chunk, 0)
      const res2 = getNext(chunk, 4)
      const res3 = getNext(chunk, 8)

      expect(res1.block).to.equal('G01')
      expect(res2.block).to.equal('G02')
      expect(res3.block).to.equal('G03')
      expect(res1.read).to.equal(4)
      expect(res2.read).to.equal(4)
      expect(res3.read).to.equal(4)
    })

    it('should return newlines read', function() {
      const chunk = 'G01*\nG02*\nG03*\n'
      const res1 = getNext(chunk, 0)
      const res2 = getNext(chunk, 4)
      const res3 = getNext(chunk, 9)

      expect(res1.block).to.equal('G01')
      expect(res2.block).to.equal('G02')
      expect(res3.block).to.equal('G03')
      expect(res1.read).to.equal(4)
      expect(res2.read).to.equal(5)
      expect(res3.read).to.equal(5)
      expect(res1.lines).to.equal(0)
      expect(res2.lines).to.equal(1)
      expect(res3.lines).to.equal(1)
    })

    it('should skip the end percent of a param', function() {
      const chunk = '%FSLAX24Y24*%\n%MOIN*%\n'
      const res1 = getNext(chunk, 0)
      const res2 = getNext(chunk, 13)

      expect(res1.block).to.equal('%FSLAX24Y24')
      expect(res2.block).to.equal('%MOIN')
      expect(res1.read).to.equal(13)
      expect(res2.read).to.equal(8)
      expect(res1.lines).to.equal(0)
      expect(res2.lines).to.equal(1)
    })
  })

  describe('from drill files', function() {
    const getNext = partial(getNextBlock, 'drill')

    it('should split at newlines', function() {
      const chunk = 'G90\nG05\nM72\nM30\n'
      const res1 = getNext(chunk, 0)
      const res2 = getNext(chunk, 4)
      const res3 = getNext(chunk, 8)
      const res4 = getNext(chunk, 12)

      expect(res1.block).to.equal('G90')
      expect(res2.block).to.equal('G05')
      expect(res3.block).to.equal('M72')
      expect(res4.block).to.equal('M30')
      expect(res1.read).to.equal(4)
      expect(res2.read).to.equal(4)
      expect(res3.read).to.equal(4)
      expect(res4.read).to.equal(4)
      expect(res1.lines).to.equal(1)
      expect(res2.lines).to.equal(1)
      expect(res3.lines).to.equal(1)
      expect(res4.lines).to.equal(1)
    })
  })
})
