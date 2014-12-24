# test suite for coordinate parser function

parseCoord = require '../src/coord-parser'
factor = require('../src/svg-coord').factor

format = { places: [2, 3], zeros: null }
describe 'coordinate parser', ->
  it 'should throw if passed an incorrect format', ->
    (-> parseCoord 'X1Y1', {}).should.throw /format undefined/
  
  it 'should parse properly with leading zero suppression', ->
      format.zero = 'L'
      parseCoord('X10', format).should.eql { x: .01*factor }
      parseCoord('Y15', format).should.eql { y: .015*factor }
      parseCoord('I20', format).should.eql { i: .02*factor }
      parseCoord('J-40', format).should.eql { j: -.04*factor }
      parseCoord('X1000Y-2000I3J432', format).should.eql {
        x: 1*factor, y: -2*factor, i: .003*factor, j: .432*factor 
      }
    
  it 'should parse properly with trailing zero suppression', ->
      format.zero = 'T'
      parseCoord('X10', format).should.eql { x: 10*factor }
      parseCoord('Y15', format).should.eql { y: 15*factor }
      parseCoord('I02', format).should.eql { i: 2*factor }
      parseCoord('J-04', format).should.eql { j: -4*factor }
      parseCoord('X0001Y-0002I3J432', format).should.eql {
        x: .01*factor, y: -.02*factor, i: 30*factor, j: 43.2*factor 
      }
    
    
  it 'should parse properly with explicit decimals mixed in', ->
      format.zero = 'L'
      parseCoord('X1.1', format).should.eql { x: 1.1*factor }
      parseCoord('Y1.5', format).should.eql { y: 1.5*factor }
      parseCoord('I20', format).should.eql { i: .02*factor }
      parseCoord('J-40', format).should.eql { j: -.04*factor }
      parseCoord('X1.1Y-2.02I3.3J43.2', format).should.eql {
        x: 1.1*factor, y: -2.02*factor, i: 3.3*factor, j: 43.2*factor 
      }
