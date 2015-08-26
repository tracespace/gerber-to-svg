// test suite for the top level gerber parser class
'use strict'

const Transform = require('stream').Transform
const expect = require('chai').expect
const parser = require('../lib/gerber-parser')

describe('gerber parser factory', function() {
  it('should return a transform stream', function() {
    let p = parser()
    expect(p).to.be.an.instanceOf(Transform)
  })

  it('should allow the zero suppression to be set by the constructor', function() {
    let p = parser({zero: 'L'})
    expect(p.zero).to.equal('L')
    p = parser({zero: 'T'})
    expect(p.zero).to.equal('T')
  })

  it('should allow the number places format to be set by the constructor', function() {
    let p = parser({places: [1, 4]})
    expect(p.places).to.eql([1, 4])
    p = parser({places: [3, 4]})
    expect(p.places).to.eql([3, 4])
  })

  it('should throw with bad options to the contructor', function() {
    let p
    let badOpts = {places: 'string'}
    expect(function() {p = parser(badOpts)}).to.throw(/places/)
    badOpts = {places: [1, 2, 3]}
    expect(function() {p = parser(badOpts)}).to.throw(/places/)
    badOpts = {places: ['a', 'b']}
    expect(function() {p = parser(badOpts)}).to.throw(/places/)
    badOpts = {zero: 4}
    expect(function() {p = parser(badOpts)}).to.throw(/zero/)
    badOpts = {zero: 'F'}
    expect(function() {p = parser(badOpts)}).to.throw(/zero/)
    void p
  })
})
