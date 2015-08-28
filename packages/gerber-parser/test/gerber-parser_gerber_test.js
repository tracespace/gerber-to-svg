// test suite for the top level gerber parser class
// test subset - parsing gerber files
'use strict'

const expect = require('chai').expect
const partial = require('lodash.partial')

const parser = require('../lib/gerber-parser')

describe('gerber parser with gerber files', function() {
  let p
  const pFactory = partial(parser, {filetype: 'gerber'})
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
      expect(res.cmd).to.equal('set')
      expect(res.key).to.equal('done')
      expect(res.val).to.equal(true)
      expect(res.line).to.equal(0)
      done()
    })

    p.write('M02*')
  })

  describe.skip('parsing the format block', function() {
    it('should parse zero suppression', function() {
      let format = '%FSLAX34Y34*%'
      p.write(format)
      expect(p.zero).to.equal('L')

      p = pFactory()
      format = '%FSTAX34Y34*%'
      p.write(format)
      expect(p.zero).to.equal('L')
    })
  })
})
