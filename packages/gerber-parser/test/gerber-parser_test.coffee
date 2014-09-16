# test suite for GerberParser class
Parser = require '../src/gerber-parser'

param = (p) -> { param: [ p ] }
block = (b) -> { block: b }

describe 'gerber command parser', ->
  p = null
  beforeEach -> p = new Parser

  it 'should ignore comments (start with G04)', ->
    initialFormat = { zero: p.format.zero, places: p.format.places }
    p.parseCommand(block 'G04 MOIN').should.eql {}
    p.parseCommand(block 'G04 this is a comment').should.eql {}
    p.parseCommand(block 'G04 D03').should.eql {}
    p.parseCommand(block 'G04 D02').should.eql {}
    p.parseCommand(block 'G04 G36').should.eql {}
    p.parseCommand(block 'G04 M02').should.eql {}
    p.format.should.eql initialFormat

  describe 'parsing the format block', ->
    it 'should handle it with good options', ->
      p.parseCommand(param 'FSLAX34Y34').should.eql { set: { notation: 'A' } }
      p.format.zero.should.eql 'L'
      p.format.places.should.eql [3,4]
      p.parseCommand(param 'FSTIX77Y77').should.eql { set: { notation: 'I' } }
      p.format.zero.should.eql 'T'
      p.format.places.should.eql [7,7]
    it 'should throw error for bad options', ->
      (-> p.parseCommand(param 'FSLPX34Y34')).should.throw /invalid/
      (-> p.parseCommand(param 'FSFAX34Y34')).should.throw /invalid/
      (-> p.parseCommand(param 'FSLAX12Y34')).should.throw /invalid/
      (-> p.parseCommand(param 'FSLAX34')).should.throw /invalid/
      (-> p.parseCommand(param 'FSLAY34')).should.throw /invalid/
      (-> p.parseCommand(param 'FSLAX3.4Y3.4')).should.throw /invalid/
      (-> p.parseCommand(param 'FSLA')).should.throw /invalid/
      (-> p.parseCommand(param 'FSpoop')).should.throw /invalid/

  describe 'parsing an aperture definition', ->
    it 'should remove leading zeros from the tool code string', ->
      p.parseCommand(param 'ADD010C,1').should.eql {
        tool: { D10: { dia: 1 } }
      }
      p.parseCommand(param 'ADD0011C,1').should.eql {
        tool: { D11: { dia: 1 } }
      }
    describe 'with standard tools', ->
      it 'should handle standard circles', ->
        p.parseCommand(param 'ADD10C,1').should.eql {
          tool: { D10: { dia: 1 } }
        }
        p.parseCommand(param 'ADD11C,1X0.2').should.eql {
          tool: { D11: { dia: 1, hole: { dia: 0.2 } } }
        }
        p.parseCommand(param 'ADD12C,1X0.2X0.3').should.eql {
          tool: { D12: { dia: 1, hole: { width: 0.2, height: 0.3 } } }
        }
      it 'should handle standard rectangles', ->
        p.parseCommand(param 'ADD10R,1X0.5').should.eql {
          tool: { D10: { width: 1, height: 0.5 } }
        }
        p.parseCommand(param 'ADD11R,1X0.5X0.2').should.eql {
          tool: { D11: { width: 1, height: 0.5, hole: { dia: 0.2 } } }
        }
        p.parseCommand(param 'ADD12R,1X0.5X0.2X0.3').should.eql {
          tool: { D12: { width: 1, height: .5, hole:{width: 0.2, height: 0.3 }}}
        }
      it 'should handle standard obrounds', ->
        p.parseCommand(param 'ADD10O,1X0.5').should.eql {
          tool: { D10: { width: 1, height: 0.5, obround: true } }
        }
        p.parseCommand(param 'ADD11O,1X0.5X0.2').should.eql {
          tool: { D11: { width: 1, height: 0.5, obround: true, hole:{dia: 0.2}}}
        }
        p.parseCommand(param 'ADD12O,1X0.5X0.2X0.3').should.eql {
          tool: { D12: { width: 1, height: .5, obround:true, hole: {
                width: 0.2, height: 0.3
              }
            }
          }
        }
      it 'should handle standard polygons', ->
        p.parseCommand(param 'ADD10P,5X3').should.eql {
          tool: { D10: { dia: 5, verticies: 3 } }
        }
        p.parseCommand(param 'ADD11P,5X4X45').should.eql {
          tool: { D11: { dia: 5, verticies: 4, degrees: 45 } }
        }
        p.parseCommand(param 'ADD12P,5X4X0X0.6').should.eql {
          tool: { D12: { dia: 5, verticies: 4, degrees: 0, hole: { dia: .6 } } }
        }
        p.parseCommand(param 'ADD13P,5X4X0X0.6X0.5').should.eql {
          tool: { D13: { dia: 5, verticies: 4, degrees: 0, hole: {
                width: 0.6, height: 0.5
              }
            }
          }
        }

    describe 'with aperture macros', ->
      it 'should parse an aperture macro with modifiers', ->
        p.parseCommand(param 'ADD10CIRC,1X0.5').should.eql {
          tool: { D10: { macro: 'CIRC', mods: [ 1, 0.5 ] } }
        }
      it 'should parse a macro with no modifiers', ->
        p.parseCommand(param 'ADD11RECT').should.eql {
          tool: { D11: { macro: 'RECT', mods: [] } }
        }

  it 'should pass along the blocks if an aperture macro', ->
    p.parseCommand({ param: [ 'AMRECT1', '21,1,1,1,0,0,0' ] }).should.eql {
      macro: [ 'AMRECT1', '21,1,1,1,0,0,0' ]
    }

  describe 'level polarity', ->
    it 'should return a new dark or clean layer', ->
      p.parseCommand(param 'LPD').should.eql { new: { layer: 'D' } }
      p.parseCommand(param 'LPC').should.eql { new: { layer: 'C' } }
    it 'should throw for a bad polarity', ->
      (-> p.parseCommand(param 'LPA')).should.throw /invalid level polarity/

  describe 'step repeat', ->
    it 'should return a new step repeat block with good input', ->
      p.parseCommand(param 'SRX1Y1').should.eql { new: { sr: { x: 1, y: 1 } } }
      p.parseCommand(param 'SRX1Y1I0J0').should.eql {
        new: { sr: { x: 1, y: 1, i: 0, j: 0 } }
      }
      p.parseCommand(param 'SRX2Y3I2.0J3.0').should.eql {
        new: { sr: { x: 2, y: 3, i: 2, j: 3 } }
      }
      p.parseCommand(param 'SR').should.eql { new: { sr: { x: 1, y: 1 } } }
    it 'should throw if bad input', ->
      (-> p.parseCommand(param 'SRX2Y3I4')).should.throw /invalid step/
      (-> p.parseCommand(param 'SRX2Y3J4')).should.throw /invalid step/
      (-> p.parseCommand(param 'SRX-1I1')).should.throw /invalid step/
      (-> p.parseCommand(param 'SRY-1J2')).should.throw /invalid step/
      (-> p.parseCommand(param 'SRX2Y2I-1J1')).should.throw /invalid step/
      (-> p.parseCommand(param 'SRX2Y2I1J-1')).should.throw /invalid step/

  it 'should end the file with an M02', ->
    p.parseCommand(block 'M02').should.eql { set: { done: true } }

  describe 'units commands', ->
    it 'should return a set units with %MOIN*% and %MOMM*%', ->
      p.parseCommand(param 'MOIN').should.eql { set: { units: 'in' } }
      p.parseCommand(param 'MOMM').should.eql { set: { units: 'mm' } }

    it 'should throw an error for invalid units parameters', ->
      (-> p.parseCommand param 'MOKM').should.throw /invalid units/

    it 'should set backup units with G70 (in) and G71 (mm)', ->
      p.parseCommand(block 'G70').should.eql { set: { backupUnits: 'in' } }
      p.parseCommand(block 'G71').should.eql { set: { backupUnits: 'mm' } }

  it 'should change tools with a tool change block', ->
    p.parseCommand(block 'D10').should.eql { set: { currentTool: 'D10' } }
    p.parseCommand(block 'G54D11').should.eql { set: { currentTool: 'D11' } }

  describe 'operating modes', ->
    it 'should turn region mode on and off with a G36 and G37', ->
      p.parseCommand(block 'G36').should.eql { set: { region: true  } }
      p.parseCommand(block 'G37').should.eql { set: { region: false } }
    it 'should set the interpolation mode with G01, 2, and 3', ->
      p.parseCommand(block 'G01').should.eql { set: { mode: 'i'   } }
      p.parseCommand(block 'G1').should.eql  { set: { mode: 'i'   } }
      p.parseCommand(block 'G02').should.eql { set: { mode: 'cw'  } }
      p.parseCommand(block 'G2').should.eql  { set: { mode: 'cw'  } }
      p.parseCommand(block 'G03').should.eql { set: { mode: 'ccw' } }
      p.parseCommand(block 'G3').should.eql  { set: { mode: 'ccw' } }
    it 'should set the arc quadrant mode with G74 (single) and 75 (multi)', ->
      p.parseCommand(block 'G74').should.eql { set: { quad: 's' } }
      p.parseCommand(block 'G75').should.eql { set: { quad: 'm' } }

  describe 'operations', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [2,2]
    it 'should parse an interpolation command', ->
      p.parseCommand(block 'X22Y0D01').should.eql {
        op: { do: 'int', x: 0.22, y: 0 }
      }
      p.parseCommand(block 'Y110D1').should.eql {
        op: { do: 'int', y: 1.10 }
      }
    it 'should parse a move command', ->
      p.parseCommand(block 'X300Y1D02').should.eql {
        op: { do: 'move', x: 3, y: 0.01 }
      }
      p.parseCommand(block 'X-100D2').should.eql {
        op: { do: 'move', x: -1 }
      }
    it 'should parse a flash command', ->
      p.parseCommand(block 'X75Y-140D03').should.eql {
        op: { do: 'flash', x: 0.75, y: -1.4 }
      }
      p.parseCommand(block 'X1Y1D3').should.eql {
        op: { do: 'flash', x: 0.01, y: 0.01 }
      }
    it 'should interpolate with an inline mode set', ->
      p.parseCommand(block 'G01X01Y01D01').should.eql {
        set: { mode: 'i' }, op: { do: 'int', x: 0.01, y:0.01 }
      }
      p.parseCommand(block 'G02X01Y01D01').should.eql {
        set: { mode: 'cw' }, op: { do: 'int', x: 0.01, y:0.01 }
      }
      p.parseCommand(block 'G03X01Y01D01').should.eql {
        set: { mode: 'ccw' }, op: { do: 'int', x: 0.01, y:0.01 }
      }
    it 'should send a last operation command if the op code is missing', ->
      p.parseCommand(block 'X01Y01').should.eql {
        op: { do: 'last', x: 0.01, y: 0.01 }
      }
