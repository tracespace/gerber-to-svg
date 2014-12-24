# test suite for getSvgCoord function

getSvgCoord = require '../src/get-svg-coord'

describe 'get integer function', ->
  it "should return NaN for bad input", ->
    getSvgCoord('0.1.2', { places: [2, 4], zero: 'L' }).should.be.NaN
    getSvgCoord('123',   { zero: 'L' }).should.be.NaN
  
  it 'should convert decimal numbers into integers', ->
    getSvgCoord('1.3',    { places: [2, 4] } ).should.equal 13000
    getSvgCoord('-.343',  { places: [2, 3] } ).should.equal -343
    getSvgCoord('+4.347', { places: [2, 2] } ).should.equal 434
    getSvgCoord('10',     { places: [3, 4] } ).should.equal 100000
    
  it 'should convert trailing zero suppressed numbers into integers', ->
    getSvgCoord('13',    { places: [2, 4], zero: 'T' } ).should.equal 130000
    getSvgCoord('-343',  { places: [2, 3], zero: 'T' } ).should.equal -34300
    getSvgCoord('+4347', { places: [2, 2], zero: 'T' } ).should.equal 4347
    getSvgCoord('10',    { places: [2, 4], zero: 'T' } ).should.equal 100000
  
  it 'should leave leading zero suppressed number alone', ->
    getSvgCoord('13',    { places: [2, 4], zero: 'L' } ).should.equal 13
    getSvgCoord('-343',  { places: [2, 3], zero: 'L' } ).should.equal -343
    getSvgCoord('+4347', { places: [2, 2], zero: 'L' } ).should.equal 4347
    getSvgCoord('10',    { places: [2, 4], zero: 'L' } ).should.equal 10
