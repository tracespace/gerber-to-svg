# test suite for Parser parent class
stream = require 'stream'
expect = require('chai').expect
Parser = require '../src/parser'

describe 'Parser class', ->
  it 'should be a transform stream', ->
    p = new Parser()
    expect(p).to.be.an.instanceOf stream.Transform

  it 'should initialize a format object with zero and places keys', ->
    p = new Parser()
    expect(p.format).to.have.keys ['zero', 'places']
    expect(p.format.zero).to.be.null
    expect(p.format.places).to.be.null

  it 'should allow the zero suppression to be set by the constructor', ->
    p = new Parser {zero: 'L'}
    expect(p.format.zero).to.equal 'L'
    p = new Parser {zero: 'T'}
    expect(p.format.zero).to.equal 'T'

  it 'should allow the number places format to be set by the constructor', ->
    p = new Parser {places: [1, 4]}
    expect(p.format.places).to.eql [1, 4]
    p = new Parser {places: [3, 4]}
    expect(p.format.places).to.eql [3, 4]

  it 'should throw with bad options to the contructor', ->
    expect(-> p = new Parser {places: 'string'}).to.throw /places/
    expect(-> p = new Parser {places: [1, 2, 3]}).to.throw /places/
    expect(-> p = new Parser {places: ['a', 'b']}).to.throw /places/
    expect(-> p = new Parser {zero: 4}).to.throw /zero/
    expect(-> p = new Parser {zero: 'F'}).to.throw /zero/
