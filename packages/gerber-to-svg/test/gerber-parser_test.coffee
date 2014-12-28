# test suite for GerberParser class
Parser = require '../src/gerber-parser'
expect = require('chai').expect

# svg coordinate factor
factor = require('../src/svg-coord').factor

param = (p) -> { param: [ p ] }
block = (b) -> { block: b }

describe 'gerber command parser', ->
  p = null
  beforeEach -> p = new Parser

  it 'should ignore comments (start with G04)', ->
    initialFormat = { zero: p.format.zero, places: p.format.places }
    expect( p.parseCommand block 'G04 MOIN' ).to.eql {}
    expect( p.parseCommand block 'G04 this is a comment' ).to.eql {}
    expect( p.parseCommand block 'G04 D03' ).to.eql {}
    expect( p.parseCommand block 'G04 D02' ).to.eql {}
    expect( p.parseCommand block 'G04 G36' ).to.eql {}
    expect( p.parseCommand block 'G04 M02' ).to.eql {}
    expect( p.format ).to.eql initialFormat

  describe 'parsing the format block', ->
    it 'should handle it with good options', ->
      expect( p.parseCommand param 'FSLAX34Y34' ).to.eql { 
        set: { notation: 'A' }
      }
      expect( p.format.zero ).to.eql 'L'
      expect( p.format.places ).to.eql [3,4]
      expect( p.parseCommand param 'FSTIX77Y77' ).to.eql {
        set: { notation: 'I' } 
      }
      expect( p.format.zero ).to.eql 'T'
      expect( p.format.places ).to.eql [7,7]
    it 'should throw error for bad options', ->
      expect( -> p.parseCommand param 'FSLPX34Y34' ).to.throw /invalid/
      expect( -> p.parseCommand param 'FSFAX34Y34' ).to.throw /invalid/
      expect( -> p.parseCommand param 'FSLAX12Y34' ).to.throw /invalid/
      expect( -> p.parseCommand param 'FSLAX34' ).to.throw /invalid/
      expect( -> p.parseCommand param 'FSLAY34' ).to.throw /invalid/
      expect( -> p.parseCommand param 'FSLAX3.4Y3.4' ).to.throw /invalid/
      expect( -> p.parseCommand param 'FSLA' ).to.throw /invalid/
      expect( -> p.parseCommand param 'FSpoop' ).to.throw /invalid/

  describe 'parsing an aperture definition', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [2, 2]
    it 'should remove leading zeros from the tool code string', ->
      expect( p.parseCommand param 'ADD010C,1' ).to.eql {
        tool: { D10: { dia: 1*factor } }
      }
      expect( p.parseCommand param 'ADD0011C,1' ).to.eql {
        tool: { D11: { dia: 1*factor } }
      }
    describe 'with standard tools', ->
      it 'should handle standard circles', ->
        expect( p.parseCommand param 'ADD10C,1' ).to.eql {
          tool: { D10: { dia: 1*factor } }
        }
        expect( p.parseCommand param 'ADD11C,1X0.2' ).to.eql {
          tool: { D11: { dia: 1*factor, hole: { dia: .2*factor } } }
        }
        expect( expect( p.parseCommand param 'ADD12C,1X0.2X0.3' ) ).to.eql {
          tool: { D12: { dia: 1*factor, hole: {
                width: .2*factor, height: .3*factor
              }
            }
          }
        }
      it 'should handle standard rectangles', ->
        expect( p.parseCommand param 'ADD10R,1X0.5' ).to.eql {
          tool: { D10: { width: 1*factor, height: .5*factor } }
        }
        expect( p.parseCommand param 'ADD11R,1X0.5X0.2' ).to.eql {
          tool: { D11: { width: 1*factor, height: .5*factor, hole: {
                dia: .2*factor 
              }
            }
          }
        }
        expect( p.parseCommand param 'ADD12R,1X0.5X0.2X0.3').to.eql {
          tool: { D12: { width: 1*factor, height: .5*factor, hole: {
                width: .2*factor, height: .3*factor
              }
            }
          }
        }
      it 'should handle standard obrounds', ->
        expect( p.parseCommand param 'ADD10O,1X0.5' ).to.eql {
          tool: { D10: { width: 1*factor, height: .5*factor, obround: true } }
        }
        expect( p.parseCommand param 'ADD11O,1X0.5X0.2' ).to.eql {
          tool: { D11: { width:1*factor, height:.5*factor, obround: true, hole:{ 
                dia: .2*factor
              }
            }
          }
        }
        expect( p.parseCommand param 'ADD12O,1X0.5X0.2X0.3').to.eql {
          tool: { D12: { width:1*factor, height:.5*factor, obround: true, hole:{
                width: .2*factor, height: .3*factor
              }
            }
          }
        }
      it 'should handle standard polygons', ->
        expect( p.parseCommand param 'ADD10P,5X3' ).to.eql {
          tool: { D10: { dia: 5*factor, verticies: 3 } }
        }
        expect( p.parseCommand param 'ADD11P,5X4X45' ).to.eql {
          tool: { D11: { dia: 5*factor, verticies: 4, degrees: 45 } }
        }
        expect( p.parseCommand param 'ADD12P,5X4X0X0.6' ).to.eql {
          tool: { D12: { dia: 5*factor, verticies: 4, degrees: 0, hole: { 
                dia: .6*factor
              }
            }
          }
        }
        expect( p.parseCommand param 'ADD13P,5X4X0X0.6X0.5' ).to.eql {
          tool: { D13: { dia: 5*factor, verticies: 4, degrees: 0, hole: {
                width: .6*factor, height: .5*factor
              }
            }
          }
        }

    describe 'with aperture macros', ->
      it 'should parse an aperture macro with modifiers', ->
        expect( p.parseCommand param 'ADD10CIRC,1X0.5' ).to.eql {
          tool: { D10: { macro: 'CIRC', mods: [ 1, 0.5 ] } }
        }
      it 'should parse a macro with no modifiers', ->
        expect( p.parseCommand param 'ADD11RECT' ).to.eql {
          tool: { D11: { macro: 'RECT', mods: [] } }
        }

  it 'should pass along the blocks if an aperture macro', ->
    expect( p.parseCommand { param: [ 'AMRECT1', '21,1,1,1,0,0,0' ] } ).to.eql {
      macro: [ 'AMRECT1', '21,1,1,1,0,0,0' ]
    }

  describe 'level polarity', ->
    it 'should return a new dark or clean layer', ->
      expect( p.parseCommand param 'LPD' ).to.eql { new: { layer: 'D' } }
      expect( p.parseCommand param 'LPC' ).to.eql { new: { layer: 'C' } }
    it 'should throw for a bad polarity', ->
      expect( -> p.parseCommand param 'LPA' ).to.throw /invalid level polarity/

  describe 'step repeat', ->
    it 'should return a new step repeat block with good input', ->
      p.format.places = [2, 2]
      expect( p.parseCommand param 'SRX1Y1' ).to.eql { 
        new: { sr: { x: 1, y: 1 } }
      }
      expect( p.parseCommand param 'SRX1Y1I0J0' ).to.eql {
        new: { sr: { x: 1, y: 1, i: 0, j: 0 } }
      }
      expect( p.parseCommand param 'SRX2Y3I2.0J3.0' ).to.eql {
        new: { sr: { x: 2, y: 3, i: 2*factor, j: 3*factor } }
      }
      expect( p.parseCommand param 'SR' ).to.eql { new: { sr: { x: 1, y: 1 } } }
    it 'should throw if bad input', ->
      expect( -> p.parseCommand param 'SRX2Y3I4' ).to.throw /invalid step/
      expect( -> p.parseCommand param 'SRX2Y3J4' ).to.throw /invalid step/
      expect( -> p.parseCommand param 'SRX-1I1' ).to.throw /invalid step/
      expect( -> p.parseCommand param 'SRY-1J2' ).to.throw /invalid step/
      expect( -> p.parseCommand param 'SRX2Y2I-1J1' ).to.throw /invalid step/
      expect( -> p.parseCommand param 'SRX2Y2I1J-1' ).to.throw /invalid step/

  it 'should end the file with an M02', ->
    expect( p.parseCommand(block 'M02') ).to.eql { set: { done: true } }

  describe 'units commands', ->
    it 'should return a set units with %MOIN*% and %MOMM*%', ->
      expect( p.parseCommand(param 'MOIN') ).to.eql { set: { units: 'in' } }
      expect( p.parseCommand(param 'MOMM') ).to.eql { set: { units: 'mm' } }

    it 'should throw an error for invalid units parameters', ->
      expect( (-> p.parseCommand param 'MOKM') ).to.throw /invalid units/

    it 'should set backup units with G70 (in) and G71 (mm)', ->
      expect( p.parseCommand(block 'G70') ).to.eql { set: { backupUnits: 'in' } }
      expect( p.parseCommand(block 'G71') ).to.eql { set: { backupUnits: 'mm' } }

  it 'should change tools with a tool change block', ->
    expect( p.parseCommand(block 'D10') ).to.eql { set: { currentTool: 'D10' } }
    expect( p.parseCommand(block 'G54D11') ).to.eql { set: { currentTool: 'D11' } }

  describe 'operating modes', ->
    it 'should turn region mode on and off with a G36 and G37', ->
      expect( p.parseCommand(block 'G36') ).to.eql { set: { region: true  } }
      expect( p.parseCommand(block 'G37') ).to.eql { set: { region: false } }
    it 'should set the interpolation mode with G01, 2, and 3', ->
      expect( p.parseCommand(block 'G01') ).to.eql { set: { mode: 'i'   } }
      expect( p.parseCommand(block 'G1') ).to.eql  { set: { mode: 'i'   } }
      expect( p.parseCommand(block 'G02') ).to.eql { set: { mode: 'cw'  } }
      expect( p.parseCommand(block 'G2') ).to.eql  { set: { mode: 'cw'  } }
      expect( p.parseCommand(block 'G03') ).to.eql { set: { mode: 'ccw' } }
      expect( p.parseCommand(block 'G3') ).to.eql  { set: { mode: 'ccw' } }
    it 'should set the arc quadrant mode with G74 (single) and 75 (multi)', ->
      expect( p.parseCommand(block 'G74') ).to.eql { set: { quad: 's' } }
      expect( p.parseCommand(block 'G75') ).to.eql { set: { quad: 'm' } }

  describe 'operations', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [2,2]
    it 'should parse an interpolation command', ->
      expect( p.parseCommand(block 'X22Y0D01') ).to.eql {
        op: { do: 'int', x: .22*factor, y: 0 }
      }
      expect( p.parseCommand(block 'Y110D1') ).to.eql {
        op: { do: 'int', y: 1.1*factor }
      }
    it 'should parse a move command', ->
      expect( p.parseCommand(block 'X300Y1D02') ).to.eql {
        op: { do: 'move', x: 3*factor, y: .01*factor }
      }
      expect( p.parseCommand(block 'X-100D2') ).to.eql {
        op: { do: 'move', x: -1*factor }
      }
    it 'should parse a flash command', ->
      expect( p.parseCommand(block 'X75Y-140D03') ).to.eql {
        op: { do: 'flash', x: .75*factor, y: -1.4*factor }
      }
      expect( p.parseCommand(block 'X1Y1D3') ).to.eql {
        op: { do: 'flash', x: .01*factor, y: .01*factor }
      }
    it 'should interpolate with an inline mode set', ->
      expect( p.parseCommand(block 'G01X01Y01D01') ).to.eql {
        set: { mode: 'i' }, op: { do: 'int', x: .01*factor, y: .01*factor }
      }
      expect( p.parseCommand(block 'G02X01Y01D01') ).to.eql {
        set: { mode: 'cw' }, op: { do: 'int', x: .01*factor, y: .01*factor }
      }
      expect( p.parseCommand(block 'G03X01Y01D01') ).to.eql {
        set: { mode: 'ccw' }, op: { do: 'int', x: .01*factor, y: .01*factor }
      }
    it 'should send a last operation command if the op code is missing', ->
      expect( p.parseCommand(block 'X01Y01') ).to.eql {
        op: { do: 'last', x: .01*factor, y: .01*factor }
      }
