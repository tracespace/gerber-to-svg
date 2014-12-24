# test suite for getSvgCoord function

svgCoord = require '../src/svg-coord'
getSvgCoord = svgCoord.get
fact = svgCoord.factor

describe 'get svg coord function', ->
  it "should return NaN for bad input", ->
    getSvgCoord('0.1.2', { places: [2, 4], zero: 'L' }).should.be.NaN
    getSvgCoord('123',   { zero: 'L' }).should.be.NaN
  
  it 'should convert decimal numbers into proper coords', ->
    getSvgCoord('1.3',   { places: [2, 4] }).should.equal 1.3     * fact
    getSvgCoord('-.343', { places: [2, 3] }).should.equal -.343   * fact
    getSvgCoord('+4.3478',{ places: [2, 2] }).should.equal 4.3478 * fact
    getSvgCoord('10',    { places: [3, 4] }).should.equal 10      * fact
    
  it 'should convert trailing zero suppressed numbers into proper coords', ->
    getSvgCoord('13',   { places: [2, 4], zero: 'T' }).should.equal 13    * fact
    getSvgCoord('-343', { places: [2, 3], zero: 'T' }).should.equal -34.3 * fact
    getSvgCoord('+4347',{ places: [2, 2], zero: 'T' }).should.equal 43.47 * fact
    getSvgCoord('10',   { places: [2, 4], zero: 'T' }).should.equal 10    * fact
  
  it 'should convert leading zero suppressed numbers into proper coords', ->
    getSvgCoord('13',   { places: [2, 4], zero: 'L' }).should.equal .0013 * fact
    getSvgCoord('-343', { places: [2, 3], zero: 'L' }).should.equal -.343 * fact
    getSvgCoord('+4347',{ places: [2, 2], zero: 'L' }).should.equal 43.47 * fact
    getSvgCoord('10',   { places: [2, 4], zero: 'L' }).should.equal .0010 * fact
