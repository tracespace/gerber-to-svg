// test suite for parse gerber function
// takes a string, a transform stream, and a done callback
'use strict'

const expect = require('chai').expect
const bind = require('lodash.bind')
const _ = bind.placeholder

const parseGerber = require('../lib/_parse-gerber')

describe.skip('parse gerber function', function() {
  let transform = {}
  let data = []
  let warnings = []
  let lines = 0
  let error
  let isDone = false
  let parse
  const _parsed = function(o) {
    data.push(o)
  }
  const _warn = function(w) {
    warnings.push(w)
  }
  const _line = function() {
    lines++
  }
  const done = function(e) {
    if (e) {
      error = e
    }
    isDone = true
  }

  beforeEach(function() {
    transform = {_parsed, _warn, _line}
    lines = 0
    data = []
    warnings = []
    error = null
    isDone = false
    parse = bind(parseGerber, null, _, transform, done)
  })

  it.skip('should ignore comment blocks and count lines', function() {
    const COMMENTS = [
      'G04 MOIN*',
      'G04 this is a comment*',
      'G04 D03*',
      'G04 D02*',
      'G04 G36*',
      'G04 M02*'
    ].join('\n')
    parse(COMMENTS)

    expect(lines).to.equal(5)
    expect(data).to.be.empty
    expect(error).to.be.null
    expect(isDone).to.be.true
  })

  describe('parsing the format block', function() {
    it('should parse leading zero suppression', function() {
      let format = '%FSLAX34Y34*%'
      parse(format)

      expect(transform.zero).to.equal('L')
      expect(error).to.be.null
      expect(isDone).to.be.true
    })

    it('should parse trailing zero suppression', function() {
      let format = '%FSTAX34Y34*%'
      parse(format)

      expect(transform.zero).to.equal('T')
      expect(error).to.be.null
      expect(isDone).to.be.true
    })

    it('should not overwrite existing suppression', function() {
      let format = '%FSTAX34Y34*%'
      transform.zero = 'L'
      parse(format)

      expect(transform.zero).to.equal('L')
      expect(error).to.be.null
      expect(isDone).to.be.true
    })

    it('should warn and default to leading if missing', function() {
      let format = '%FSAX34Y34*%'
      parse(format)

      expect(transform.zero).to.equal('L')
      expect(warnings[0]).to.match(/suppression missing/)
      expect(error).to.be.null
      expect(isDone).to.be.true
    })

    it('should parse notation', function() {
      let format = '%FSLAX34Y34*%'
      parse(format)

      expect(data[0].set.notation).to.equal('A')
      expect(error).to.be.null
      expect(isDone).to.be.true

      format = '%FSLIX34Y34*%'
      parse(format)

      expect(data[1].set.notation).to.equal('I')
      expect(error).to.be.null
      expect(isDone).to.be.true

      // should still parse if zero suppression is missing
      format = '%FSAX34Y34*%'
      parse(format)

      expect(data[2].set.notation).to.equal('A')
      expect(error).to.be.null
      expect(isDone).to.be.true
    })

    it('should warn and default to absolute if missing', function() {
      let format = '%FSLX34Y34*%'
      parse(format)

      expect(data[0].set.notation).to.equal('A')
      expect(warnings[0]).to.match(/notation missing/)
      expect(error).to.be.null
      expect(isDone).to.be.true
    })

    it('should parse places and set the epsilon value', function() {
      let format = '%FSLAX34Y34*%'
      parse(format)

      expect(transform.places).to.eql([3, 4])
      expect(data[0].set.epsilon).to.equal(0.15)
      expect(error).to.be.null
      expect(isDone).to.be.true
    })

    it('should not override places', function() {
      let format = '%FSLAX34Y34*%'
      transform.places = [4, 7]
      parse(format)

      expect(transform.places).to.eql([4, 7])
      expect(data[0].set.epsilon).to.equal(0.00015)
      expect(error).to.be.null
      expect(isDone).to.be.true
    })

    it.skip('should call done with error if the FS block is bad', function() {

    })
  })
})
