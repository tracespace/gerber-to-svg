// test suite for normalize coordinate function
// input: a coordinate string from a gerber file
// output: an integer in 1/1000's of whatever unit the Gerber is in
'use strict'

var expect = require('chai').expect
var normalize = require('../lib/_normalize-coord')

var FACTOR = 1000

describe('normalize coordinate', function() {
  it('should return NaN for bad input', function() {
    expect(normalize()).to.be.NaN
    expect(normalize('0.1.2')).to.be.NaN
    expect(normalize('45', {zero: 'L'})).to.be.NaN
    expect(normalize('78', {zero: 'L', places: ['a', 2]})).to.be.NaN
    expect(normalize('90', {zero: 'L', places: [2, 'b']})).to.be.NaN
    expect(normalize('123', {zero: 'L', places: []})).to.be.NaN
    expect(normalize('456', {zero: 'foo', places: [2, 4]})).to.be.NaN
  })

  it('should convert decimal numbers into proper coords', function() {
    expect(normalize('1.3', {places: [2, 4]})).to.equal(1.3 * FACTOR)
    expect(normalize('-.343', {places: [2, 3]})).to.equal(-.343 * FACTOR)
    expect(normalize('+4.3478', {places: [2, 2]})).to.equal(4.3478 * FACTOR)
    expect(normalize('10', {places: [3, 4]})).to.equal(10 * FACTOR)
  })

  it('should convert trailing zero suppressed numbers into proper coords', function() {
    expect(normalize('13', {places: [2, 4], zero: 'T'})).to.equal(13 * FACTOR)
    expect(normalize('-343', {places: [2, 3], zero: 'T'})).to.equal(-34.3 * FACTOR)
    expect(normalize('+4347', {places: [2, 2], zero: 'T'})).to.equal(43.47 * FACTOR)
    expect(normalize('1', {places: [2, 4], zero: 'T'})).to.equal(10 * FACTOR)
  })

  it('should convert leading zero suppressed numbers into proper coords', function() {
    expect(normalize('13', {places: [2, 4], zero: 'L'})).to.equal(.0013 * FACTOR)
    expect(normalize('-343', {places: [2, 3], zero: 'L'})).to.equal(-.343 * FACTOR)
    expect(normalize('+4347', {places: [2, 2], zero: 'L'})).to.equal(43.47 * FACTOR)
    expect(normalize('10', {places: [2, 4], zero: 'L'})).to.equal(.0010 * FACTOR)
  })
})
