# test suite for coordinate parser function

parseCoord = require '../src/coord-parser'

format = { places: [2, 3], zeros: '' }
describe 'coordinate parser', ->
  it 'should throw if passed an incorrect format', ->
    (-> parseCoord 'X1Y1', {}).should.throw /format undefined/
  
  it 'should parse properly with leading zero suppression', ->
      format.zero = 'L'
      parseCoord('X10', format).should.eql { x: 10 }
      parseCoord('Y15', format).should.eql { y: 15 }
      parseCoord('I20', format).should.eql { i: 20 }
      parseCoord('J-40', format).should.eql { j: -40 }
      parseCoord('X1000Y-2000I3J432', format).should.eql {
        x: 1000, y: -2000, i: 3, j: 432 
      }
    
  it 'should parse properly with trailing zero suppression', ->
      format.zero = 'T'
      parseCoord('X10', format).should.eql { x: 10000 }
      parseCoord('Y15', format).should.eql { y: 15000 }
      parseCoord('I02', format).should.eql { i: 2000 }
      parseCoord('J-04', format).should.eql { j: -4000 }
      parseCoord('X0001Y-0002I3J432', format).should.eql {
        x: 10, y: -20, i: 30000, j: 43200 
      }
    
    
  it 'should parse properly with explicit decimals mixed in', ->
      format.zero = 'L'
      parseCoord('X1.1', format).should.eql { x: 1100 }
      parseCoord('Y1.5', format).should.eql { y: 1500 }
      parseCoord('I20', format).should.eql { i: 20 }
      parseCoord('J-40', format).should.eql { j: -40 }
      parseCoord('X1.1Y-2.02I3.3J43.2', format).should.eql {
        x: 1100, y: -2020, i: 3300, j: 43200 
      }
