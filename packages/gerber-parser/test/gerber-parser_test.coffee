# test suite for GerberParser class
expect = require('chai').expect
Parser = require '../src/gerber-parser'
# svg coordinate F
F = require('../src/svg-coord').factor

param = (param, line) -> { param: param, line: line }
block = (block, line) -> { block: block, line: line }

describe 'gerber command parser', ->
  p = null
  beforeEach -> p = new Parser

  it 'should ignore comments (start with G04)', ->
    initialFormat = { zero: p.format.zero, places: p.format.places }

    p.once 'readable', ->
      throw new Error 'comment triggered a push'

    p.write block 'G04 MOIN'
    p.write block 'G04 this is a comment'
    p.write block 'G04 D03'
    p.write block 'G04 D02'
    p.write block 'G04 G36'
    p.write block 'G04 M02'

    setTimeout((-> expect(p.format).to.eql initialFormat), 1)

  describe 'parsing the format block', ->
    it 'should parse absolute notation', (done) ->
      p.once 'readable', ->
        data = p.read()
        expect(data.line).to.eql 2
        expect(data.set).to.eql {notation: 'A'}
        done()

      p.write param 'FSLAX34Y34', 2

    it 'should parse incremental notation', (done) ->
      p.once 'readable', ->
        data = p.read()
        expect(data.line).to.eql 3
        expect(data.set).to.eql {notation: 'I'}
        done()

      p.write param 'FSLIX34Y34', 3

    it 'should parse zero suppression and coordinate places', ->
      p.write param 'FSTAX77Y77', 1
      expect(p.format.zero).to.eql 'T'
      expect(p.format.places).to.eql [7,7]
      p = new Parser()
      p.write param 'FSLAX34Y34', 1
      expect(p.format.zero).to.eql 'L'
      expect(p.format.places).to.eql [3,4]


    it 'should not override user set places or zero suppression', ->
      p = new Parser {places: [4, 7], zero: 'T'}
      p.write param 'FSLAX34Y34'
      expect(p.format.zero).to.eql 'T'
      expect(p.format.places).to.eql [4,7]

    it 'should emit an error for bad notation', (done) ->
      p.once 'error', (e) ->
        expect(e.message).to.match /line 5 .* notation/
        done()

      p.write param 'FSLPX34Y34', 5

    it 'should emit an error for bad zero suppression', (done) ->
      p.once 'error', (e) ->
        expect(e.message).to.match /line 3 .* suppression/
        done()

      p.write param 'FSQAX34Y34', 3

    it 'should emit an error for bad coordinate places', (done) ->
      eCount = 0
      handler = (e) ->
        expect(e.message).to.match /line 6 .* coordinate/
        if ++eCount > 4
          p.removeListener 'error', handler
          done()

      p.on 'error', handler
      p.write param 'FSLAX12Y34', 6
      p.write param 'FSLAX34', 6
      p.write param 'FSLAY34', 6
      p.write param 'FSLAX3.4Y3.4', 6
      p.write param 'FSLAX88Y88', 6

  describe 'parsing an aperture definition', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [2, 2]

    it 'should get the tool code with leading zeros removed', (done) ->
      toolCount = 0
      tools = ['D10', 'D11', 'D12']

      handler = ->
        data = p.read()
        expect(data.tool).to.have.key tools[toolCount++]
        if toolCount >= tools.length
          p.removeListener 'readable', handler
          done()

      p.on 'readable', handler
      p.write param 'ADD010C,1', 1
      p.write param 'ADD0011C,1', 2
      p.write param 'ADD12C,1', 2

    describe 'with standard tools', ->

      it 'should handle standard circles', (done) ->
        circleCount = 0
        circles = [
          {D10: {dia: 1 * F}}
          {D11: {dia: 1 * F, hole: {dia: .2 * F}}}
          {D12: {dia: 1 * F, hole: {width: .2 * F, height: .3 * F}}}
        ]

        handler = ->
          data = p.read()
          expect(data.tool).to.eql circles[circleCount]
          if ++circleCount >= circles.length
            p.removeListener 'readable', handler
            done()

        p.on 'readable', handler
        p.write param 'ADD10C,1', 1
        p.write param 'ADD11C,1X0.2', 2
        p.write param 'ADD12C,1X0.2X0.3', 3

      it 'should handle standard rectangles', (done) ->
        rectCount = 0
        rects = [
          {D10: {width: 1 * F, height: .5 * F}}
          {D11: {width: 1 * F, height: .5 * F, hole: {dia: .2 * F}}}
          {
            D12: {
              width: 1 * F
              height: .5 * F
              hole: {width: .2 * F, height: .3 * F}
            }
          }
        ]

        handler = ->
          data = p.read()
          expect(data.tool).to.eql rects[rectCount]
          if ++rectCount >= rects.length
            p.removeListener 'readable', handler
            done()

        p.on 'readable', handler
        p.write param 'ADD10R,1X0.5', 1
        p.write param 'ADD11R,1X0.5X0.2', 2
        p.write param 'ADD12R,1X0.5X0.2X0.3', 3

      it 'should handle standard obrounds', (done) ->
        obroundCount = 0
        obrounds = [
          {D10: {width: 1 * F, height: .5 * F, obround: true}}
          {
            D11: {
              width: 1 * F, height: .5 * F, obround: true, hole: {dia: .2 * F}
            }
          }
          {
            D12: {
              width: 1 * F
              height: .5 * F
              obround: true
              hole: {width: .2 * F, height: .3 * F}
            }
          }
        ]

        handler = ->
          data = p.read()
          expect(data.tool).to.eql obrounds[obroundCount]
          if ++obroundCount >= obrounds.length
            p.removeListener 'readable', handler
            done()

        p.on 'readable', handler
        p.write param 'ADD10O,1X0.5', 1
        p.write param 'ADD11O,1X0.5X0.2', 2
        p.write param 'ADD12O,1X0.5X0.2X0.3', 3

      it 'should handle standard polygons', (done) ->
        polyCount = 0
        polys = [
          {D10: {dia: 5 * F, vertices: 3}}
          {D11: {dia: 5 * F, vertices: 4, degrees: 45}}
          {D12: {dia: 5 * F, vertices: 4, degrees: 0, hole: {dia: .6 * F}}}
          {
            D13: {
              dia: 5 * F, vertices: 4, degrees: 0, hole: {
                width: .6 * F, height: .5 * F
              }
            }
          }
        ]

        handler = ->
          data = p.read()
          expect(data.tool).to.eql polys[polyCount]
          if ++polyCount >= polys.length
            p.removeListener 'readable', handler
            done()

        p.on 'readable', handler
        p.write param 'ADD10P,5X3', 1
        p.write param 'ADD11P,5X4X45', 2
        p.write param 'ADD12P,5X4X0X0.6', 3
        p.write param 'ADD13P,5X4X0X0.6X0.5', 4


    describe 'with aperture macros', ->
      it 'should parse an aperture macro with modifiers', ->
        p.once 'readable', ->
          data = p.read()
          expect(data.tool).to.eql {D10: {macro: 'CIRC', mods: [1, 0.5]}}

        p.write param 'ADD10CIRC,1X0.5', 1

  #
  #     it 'should parse a macro with no modifiers', ->
  #       expect( p.parseCommand param 'ADD11RECT' ).to.eql {
  #         tool: { D11: { macro: 'RECT', mods: [] } }
  #       }
  #
  # it 'should pass along the blocks if an aperture macro', ->
  #   expect( p.parseCommand { param: [ 'AMRECT1', '21,1,1,1,0,0,0' ] } ).to.eql {
  #     macro: [ 'AMRECT1', '21,1,1,1,0,0,0' ]
  #   }
  #
  # describe 'level polarity', ->
  #
  #   it 'should return a new dark or clean layer', ->
  #     expect( p.parseCommand param 'LPD' ).to.eql { new: { layer: 'D' } }
  #     expect( p.parseCommand param 'LPC' ).to.eql { new: { layer: 'C' } }
  #
  #   it 'should throw for a bad polarity', ->
  #     expect( -> p.parseCommand param 'LPA' ).to.throw /invalid level polarity/
  #
  # describe 'step repeat', ->
  #
  #   it 'should return a new step repeat block with good input', ->
  #     p.format.places = [2, 2]
  #     expect( p.parseCommand param 'SRX1Y1' ).to.eql {
  #       new: { sr: { x: 1, y: 1 } }
  #     }
  #     expect( p.parseCommand param 'SRX1Y1I0J0' ).to.eql {
  #       new: { sr: { x: 1, y: 1, i: 0, j: 0 } }
  #     }
  #     expect( p.parseCommand param 'SRX2Y3I2.0J3.0' ).to.eql {
  #       new: { sr: { x: 2, y: 3, i: 2 * F, j: 3 * F } }
  #     }
  #     expect( p.parseCommand param 'SR' ).to.eql { new: { sr: { x: 1, y: 1 } } }
  #
  #   it 'should throw if bad input', ->
  #     expect( -> p.parseCommand param 'SRX2Y3I4' ).to.throw /invalid step/
  #     expect( -> p.parseCommand param 'SRX2Y3J4' ).to.throw /invalid step/
  #     expect( -> p.parseCommand param 'SRX-1I1' ).to.throw /invalid step/
  #     expect( -> p.parseCommand param 'SRY-1J2' ).to.throw /invalid step/
  #     expect( -> p.parseCommand param 'SRX2Y2I-1J1' ).to.throw /invalid step/
  #     expect( -> p.parseCommand param 'SRX2Y2I1J-1' ).to.throw /invalid step/
  #
  # it 'should end the file with an M02', ->
  #   expect( p.parseCommand block 'M02' ).to.eql { set: { done: true } }
  #
  # describe 'units commands', ->
  #
  #   it 'should return a set units with %MOIN*% and %MOMM*%', ->
  #     expect( p.parseCommand param 'MOIN' ).to.eql { set: { units: 'in' } }
  #     expect( p.parseCommand param 'MOMM' ).to.eql { set: { units: 'mm' } }
  #
  #   it 'should throw an error for invalid units parameters', ->
  #     expect( -> p.parseCommand param 'MOKM' ).to.throw /invalid units/
  #
  #   it 'should set backup units with G70 (in) and G71 (mm)', ->
  #     expect( p.parseCommand block 'G70' ).to.eql { set: { backupUnits: 'in' } }
  #     expect( p.parseCommand block 'G71' ).to.eql { set: { backupUnits: 'mm' } }
  #
  # it 'should change tools with a tool change block', ->
  #   expect( p.parseCommand block 'D10' ).to.eql { set: { currentTool: 'D10' } }
  #   expect( p.parseCommand block 'G54D11' ).to.eql { set: {currentTool: 'D11'} }
  #
  # describe 'operating modes', ->
  #
  #   it 'should turn region mode on and off with a G36 and G37', ->
  #     expect( p.parseCommand block 'G36' ).to.eql { set: { region: true  } }
  #     expect( p.parseCommand block 'G37' ).to.eql { set: { region: false } }
  #
  #   it 'should set the interpolation mode with G01, 2, and 3', ->
  #     expect( p.parseCommand block 'G01' ).to.eql { set: { mode: 'i'   } }
  #     expect( p.parseCommand block 'G1' ).to.eql  { set: { mode: 'i'   } }
  #     expect( p.parseCommand block 'G02' ).to.eql { set: { mode: 'cw'  } }
  #     expect( p.parseCommand block 'G2' ).to.eql  { set: { mode: 'cw'  } }
  #     expect( p.parseCommand block 'G03' ).to.eql { set: { mode: 'ccw' } }
  #     expect( p.parseCommand block 'G3' ).to.eql  { set: { mode: 'ccw' } }
  #
  #   it 'should set the arc quadrant mode with G74 (single) and 75 (multi)', ->
  #     expect( p.parseCommand block 'G74' ).to.eql { set: { quad: 's' } }
  #     expect( p.parseCommand block 'G75' ).to.eql { set: { quad: 'm' } }
  #
  # describe 'operations', ->
  #
  #   beforeEach ->
  #     p.format.zero = 'L'
  #     p.format.places = [2,2]
  #
  #   it 'should parse an interpolation command', ->
  #     expect( p.parseCommand block 'X22Y0D01' ).to.eql {
  #       op: { do: 'int', x: .22 * F, y: 0 }
  #     }
  #     expect( p.parseCommand block 'Y110D1' ).to.eql {
  #       op: { do: 'int', y: 1.1 * F }
  #     }
  #
  #   it 'should parse a move command', ->
  #     expect( p.parseCommand block 'X300Y1D02' ).to.eql {
  #       op: { do: 'move', x: 3 * F, y: .01 * F }
  #     }
  #     expect( p.parseCommand block 'X-100D2' ).to.eql {
  #       op: { do: 'move', x: -1 * F }
  #     }
  #
  #   it 'should parse a flash command', ->
  #     expect( p.parseCommand block 'X75Y-140D03' ).to.eql {
  #       op: { do: 'flash', x: .75 * F, y: -1.4 * F }
  #     }
  #     expect( p.parseCommand block 'X1Y1D3' ).to.eql {
  #       op: { do: 'flash', x: .01 * F, y: .01 * F }
  #     }
  #
  #   it 'should interpolate with an inline mode set', ->
  #     expect( p.parseCommand block 'G01X01Y01D01' ).to.eql {
  #       set: { mode: 'i' }
  #       op: { do: 'int', x: .01 * F, y: .01 * F }
  #     }
  #     expect( p.parseCommand block 'G02X01Y01D01' ).to.eql {
  #       set: { mode: 'cw' }
  #       op: { do: 'int', x: .01 * F, y: .01 * F }
  #     }
  #     expect( p.parseCommand block 'G03X01Y01D01' ).to.eql {
  #       set: { mode: 'ccw' }
  #       op: { do: 'int', x: .01 * F, y: .01 * F }
  #     }
  #
  #   it 'should send a last operation command if the op code is missing', ->
  #     expect( p.parseCommand block 'X01Y01' ).to.eql {
  #       op: { do: 'last', x: .01 * F, y: .01 * F }
  #     }
