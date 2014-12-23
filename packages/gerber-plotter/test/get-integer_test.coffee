# test suite for getInteger function

getInteger = require '../src/get-integer'

describe 'get integer function', ->
  it "should return NaN for bad input", ->
    getInteger('0.1.2', { places: [2, 4], zero: 'L' }).should.be.NaN
    getInteger('123',   { zero: 'L' }).should.be.NaN
  
  it 'should convert decimal numbers into integers', ->
    getInteger('1.3',    { places: [2, 4] } ).should.equal 13000
    getInteger('-.343',  { places: [2, 3] } ).should.equal -343
    getInteger('+4.347', { places: [2, 2] } ).should.equal 434
    getInteger('10',     { places: [3, 4] } ).should.equal 100000
    
  it 'should convert trailing zero suppressed numbers into integers', ->
    getInteger('13',    { places: [2, 4], zero: 'T' } ).should.equal 130000
    getInteger('-343',  { places: [2, 3], zero: 'T' } ).should.equal -34300
    getInteger('+4347', { places: [2, 2], zero: 'T' } ).should.equal 4347
    getInteger('10',    { places: [2, 4], zero: 'T' } ).should.equal 100000
  
  it 'should leave leading zero suppressed number alone', ->
    getInteger('13',    { places: [2, 4], zero: 'L' } ).should.equal 13
    getInteger('-343',  { places: [2, 3], zero: 'L' } ).should.equal -343
    getInteger('+4347', { places: [2, 2], zero: 'L' } ).should.equal 4347
    getInteger('10',    { places: [2, 4], zero: 'L' } ).should.equal 10
