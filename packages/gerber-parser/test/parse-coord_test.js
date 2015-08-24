// test suite for coordinate parser function
'use strict'

const expect = require('chai').expect
const parseCoord = require('../lib/_parse-coord')

// svg coordinate FACTOR
const FACTOR = 1000
const FORMAT = {places: [2, 3], zeros: null}

describe('coordinate parser', function() {
  it('should throw if passed an incorrect FORMAT', function() {
    expect(function() {parseCoord('X1Y1', {})}).to.throw(/format undefined/)
  })

  it('should parse properly with leading zero suppression', function() {
    FORMAT.zero = 'L'
    expect(parseCoord('X10', FORMAT)).to.eql({x: .01 * FACTOR})
    expect(parseCoord('Y15', FORMAT)).to.eql({y: .015 * FACTOR})
    expect(parseCoord('I20', FORMAT)).to.eql({i: .02 * FACTOR})
    expect(parseCoord('J-40', FORMAT)).to.eql({j: -.04 * FACTOR})
    expect(parseCoord('X1000Y-2000I3J432', FORMAT)).to.eql({
      x: 1 * FACTOR, y: -2 * FACTOR, i: .003 * FACTOR, j: .432 * FACTOR
    })
  })

  it('should parse properly with trailing zero suppression', function() {
    FORMAT.zero = 'T'
    expect(parseCoord('X10', FORMAT)).to.eql({x: 10 * FACTOR})
    expect(parseCoord('Y15', FORMAT)).to.eql({y: 15 * FACTOR})
    expect(parseCoord('I02', FORMAT)).to.eql({i: 2 * FACTOR})
    expect(parseCoord('J-04', FORMAT)).to.eql({j: -4 * FACTOR})
    expect(parseCoord('X0001Y-0002I3J432', FORMAT)).to.eql({
      x: .01 * FACTOR, y: -.02 * FACTOR, i: 30 * FACTOR, j: 43.2 * FACTOR
    })
  })

  it('should parse properly with explicit decimals mixed in', function() {
    FORMAT.zero = 'L'
    expect(parseCoord('X1.1', FORMAT)).to.eql({x: 1.1 * FACTOR})
    expect(parseCoord('Y1.5', FORMAT)).to.eql({y: 1.5 * FACTOR})
    expect(parseCoord('I20', FORMAT)).to.eql({i: .02 * FACTOR})
    expect(parseCoord('J-40', FORMAT)).to.eql({j: -.04 * FACTOR})
    expect(parseCoord('X1.1Y-2.02I3.3J43.2', FORMAT)).to.eql({
      x: 1.1 * FACTOR, y: -2.02 * FACTOR, i: 3.3 * FACTOR, j: 43.2 * FACTOR
    })
  })

  it('should return an empty object if no string is passed in', function() {
    expect(parseCoord()).to.eql({})
  })
})
