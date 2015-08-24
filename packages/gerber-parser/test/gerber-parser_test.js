// test suite for the top level gerber parser class
'use strict'

const Transform = require('stream').Transform
const expect = require('chai').expect
const Parser = require('../lib/gerber-parser')

describe('gerber parser', function() {
  it('should be a transform stream', function() {
    let p = new Parser()
    expect(p).to.be.an.instanceOf(Transform)
  })

  it('should initialize a format object with zero and places keys', function() {
    let p = new Parser()
    expect(p.format).to.have.keys(['zero', 'places'])
    expect(p.format.zero).to.be.null
    expect(p.format.places).to.be.null
  })

  it('should allow the zero suppression to be set by the constructor', function() {
    let p = new Parser({zero: 'L'})
    expect(p.format.zero).to.equal('L')
    p = new Parser({zero: 'T'})
    expect(p.format.zero).to.equal('T')
  })

  it('should allow the number places format to be set by the constructor', function() {
    let p = new Parser({places: [1, 4]})
    expect(p.format.places).to.eql([1, 4])
    p = new Parser({places: [3, 4]})
    expect(p.format.places).to.eql([3, 4])
  })

  it('should throw with bad options to the contructor', function() {
    var p
    
    let badOpts = {places: 'string'}
    expect(function() {p = new Parser(badOpts)}).to.throw(/places/)
    badOpts = {places: [1, 2, 3]}
    expect(function() {p = new Parser(badOpts)}).to.throw(/places/)
    badOpts = {places: ['a', 'b']}
    expect(function() {p = new Parser(badOpts)}).to.throw(/places/)
    badOpts = {zero: 4}
    expect(function() {p = new Parser(badOpts)}).to.throw(/zero/)
    badOpts = {zero: 'F'}
    expect(function() {p = new Parser(badOpts)}).to.throw(/zero/)

    void p
  })
})
