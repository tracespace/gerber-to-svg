// test suite for coordinate parser function
'use strict'

// expect = require('chai').expect
// parseCoord = require '../src/coord-parser'
// # svg coordinate factor
// factor = require('../src/svg-coord').factor
//
// format = { places: [2, 3], zeros: null }
// describe 'coordinate parser', ->
//   it 'should throw if passed an incorrect format', ->
//     expect( -> parseCoord 'X1Y1', {} ).to.throw /format undefined/
//
//   it 'should parse properly with leading zero suppression', ->
//     format.zero = 'L'
//     expect( parseCoord 'X10', format ).to.eql { x: .01 * factor }
//     expect( parseCoord 'Y15', format ).to.eql { y: .015 * factor }
//     expect( parseCoord 'I20', format ).to.eql { i: .02 * factor }
//     expect( parseCoord 'J-40', format ).to.eql { j: -.04 * factor }
//     expect( parseCoord 'X1000Y-2000I3J432', format ).to.eql {
//       x: 1 * factor, y: -2 * factor, i: .003 * factor, j: .432 * factor
//     }
//
//   it 'should parse properly with trailing zero suppression', ->
//     format.zero = 'T'
//     expect( parseCoord 'X10', format ).to.eql { x: 10 * factor }
//     expect( parseCoord 'Y15', format ).to.eql { y: 15 * factor }
//     expect( parseCoord 'I02', format ).to.eql { i: 2 * factor }
//     expect( parseCoord 'J-04', format ).to.eql { j: -4 * factor }
//     expect( parseCoord 'X0001Y-0002I3J432', format ).to.eql {
//       x: .01 * factor, y: -.02 * factor, i: 30 * factor, j: 43.2 * factor
//     }
//
//   it 'should parse properly with explicit decimals mixed in', ->
//     format.zero = 'L'
//     expect( parseCoord 'X1.1', format ).to.eql { x: 1.1 * factor }
//     expect( parseCoord 'Y1.5', format ).to.eql { y: 1.5 * factor }
//     expect( parseCoord 'I20', format ).to.eql { i: .02 * factor }
//     expect( parseCoord 'J-40', format ).to.eql { j: -.04 * factor }
//     expect( parseCoord 'X1.1Y-2.02I3.3J43.2', format ).to.eql {
//       x: 1.1 * factor, y: -2.02 * factor, i: 3.3 * factor, j: 43.2 * factor
//     }
