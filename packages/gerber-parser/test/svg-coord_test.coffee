# test suite for getSvgCoord function
expect = require('chai').expect
svgCoord = require '../src/svg-coord'
getSvgCoord = svgCoord.get
fact = svgCoord.factor

describe 'get svg coord function', ->

  it "should factor the coordinates by #{fact}", ->
    expect(fact).to.equal 1000

  it 'should return NaN for bad input', ->
    expect(getSvgCoord()).to.be.NaN
    expect(getSvgCoord '0.1.2').to.be.NaN
    expect(getSvgCoord '123', {zero: 'L'}).to.be.NaN
    expect(getSvgCoord '123', {zero: 'L', places: ['a', 2]}).to.be.NaN
    expect(getSvgCoord '123', {zero: 'L', places: [2, 'b']}).to.be.NaN
    expect(getSvgCoord '123', {zero: 'L', places: []}).to.be.NaN
    expect(getSvgCoord '123', {zero: 'foo', places: [2, 4]}).to.be.NaN

  it 'should convert decimal numbers into proper coords', ->
    expect(getSvgCoord '1.3', {places: [2, 4]}).to.equal 1.3 * fact
    expect(getSvgCoord '-.343', {places: [2, 3]}).to.equal -.343 * fact
    expect(getSvgCoord '+4.3478', {places: [2, 2]}).to.equal 4.3478 * fact
    expect(getSvgCoord '10', {places: [3, 4]}).to.equal 10 * fact

  it 'should convert trailing zero suppressed numbers into proper coords', ->
    expect(getSvgCoord '13', {places: [2, 4], zero: 'T'})
      .to.equal 13 * fact
    expect(getSvgCoord '-343', {places: [2, 3], zero: 'T'})
      .to.equal -34.3 * fact
    expect(getSvgCoord '+4347', {places: [2, 2], zero: 'T'})
      .to.equal 43.47 * fact
    expect(getSvgCoord '1', {places: [2, 4], zero: 'T'})
      .to.equal 10 * fact

  it 'should convert leading zero suppressed numbers into proper coords', ->
    expect(getSvgCoord '13', {places: [2, 4], zero: 'L'})
      .to.equal .0013 * fact
    expect(getSvgCoord '-343', {places: [2, 3], zero: 'L'})
      .to.equal -.343 * fact
    expect(getSvgCoord '+4347', {places: [2, 2], zero: 'L'})
      .to.equal 43.47 * fact
    expect(getSvgCoord '10', {places: [2, 4], zero: 'L'})
      .to.equal .0010 * fact
