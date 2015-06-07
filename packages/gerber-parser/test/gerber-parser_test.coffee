# test suite for GerberParser class
expect = require('chai').expect
Parser = require '../src/gerber-parser'
Warning = require '../src/warning'
# svg coordinate F
F = require('../src/svg-coord').factor

param = (param, line) -> { param: param, line: line }
block = (block, line) -> { block: block, line: line }

describe 'gerber command parser', ->
  p = null
  resultCount = null
  results = null
  handler = null
  type = null
  cb = null
  beforeEach ->
    p = new Parser
    resultCount = 0
    results = []

    handler = ->
      data = p.read()
      expect(data[type]).to.eql results[resultCount]
      if ++resultCount >= results.length
        p.removeListener 'readable', handler
        cb()

  it 'should ignore comments (start with G04)', (done) ->
    initialFormat = { zero: p.format.zero, places: p.format.places }

    p.once 'readable', ->
      throw new Error 'comment triggered a push'

    p.write block 'G04 MOIN'
    p.write block 'G04 this is a comment'
    p.write block 'G04 D03'
    p.write block 'G04 D02'
    p.write block 'G04 G36'
    p.write block 'G04 M02'

    setTimeout ->
      expect(p.format).to.eql initialFormat
      done()
    , 1

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

  describe 'parsing unit commands', ->
    it 'should set inches with %MOIN*%', (done) ->
      p.once 'readable', ->
        expect(p.read().set).to.eql {units: 'in'}
        done()

      p.write param 'MOIN', 1

    it 'should set millimeters with %MOMM*%', (done) ->
      p.once 'readable', ->
        expect(p.read().set).to.eql {units: 'mm'}
        done()

      p.write param 'MOMM', 1

    it 'should error for invalid units parameters', (done) ->
      p.once 'error', (e) ->
        expect(e.message).to.match /line 4 .*invalid units/
        done()

      p.write param 'MOKM', 4

    it 'should set backup units with G70 (in) and G71 (mm)', (done) ->
      type = 'set'
      cb = done
      results = [{backupUnits: 'in'}, {backupUnits: 'mm'}]

      p.on 'readable', handler
      p.write block 'G70', 1
      p.write block 'G71', 2

  describe 'parsing an aperture definition', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [2, 2]
      type = 'tool'

    it 'should get the tool code with leading zeros removed', (done) ->
      toolCount = 0
      tools = ['D10', 'D11', 'D12']

      handler = ->
        data = p.read()
        expect(data.tool).to.have.key tools[toolCount]
        if ++toolCount >= tools.length
          p.removeListener 'readable', handler
          done()

      p.on 'readable', handler
      p.write param 'ADD010C,1', 1
      p.write param 'ADD0011C,1', 2
      p.write param 'ADD12C,1', 2

    describe 'with standard tools', ->
      it 'should handle standard circles', (done) ->
        cb = done
        results = [
          {D10: {dia: 1 * F}}
          {D11: {dia: 1 * F, hole: {dia: .2 * F}}}
          {D12: {dia: 1 * F, hole: {width: .2 * F, height: .3 * F}}}
        ]

        p.on 'readable', handler
        p.write param 'ADD10C,1', 1
        p.write param 'ADD11C,1X0.2', 2
        p.write param 'ADD12C,1X0.2X0.3', 3

      it 'should handle standard rectangles', (done) ->
        cb = done
        results = [
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

        p.on 'readable', handler
        p.write param 'ADD10R,1X0.5', 1
        p.write param 'ADD11R,1X0.5X0.2', 2
        p.write param 'ADD12R,1X0.5X0.2X0.3', 3

      it 'should handle standard obrounds', (done) ->
        cb = done
        results = [
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

        p.on 'readable', handler
        p.write param 'ADD10O,1X0.5', 1
        p.write param 'ADD11O,1X0.5X0.2', 2
        p.write param 'ADD12O,1X0.5X0.2X0.3', 3

      it 'should handle standard polygons', (done) ->
        cb = done
        results = [
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

        p.on 'readable', handler
        p.write param 'ADD10P,5X3', 1
        p.write param 'ADD11P,5X4X45', 2
        p.write param 'ADD12P,5X4X0X0.6', 3
        p.write param 'ADD13P,5X4X0X0.6X0.5', 4

      describe 'error checking', ->
        it 'should not allow negative diameters', (done) ->
          count = 0
          commands = [
            'ADD10C,-1'
            'ADD11P,-4X5'
          ]

          handler = (e) ->
            expect(e.message).to.match /diameter cannot be negative/
            if ++count >= commands.length
              p.removeListener 'error', handler
              done()

          p.on 'error', handler
          p.write param c for c in commands

        it 'should not allow negative side widths', (done) ->
          count = 0
          commands = [
            'ADD10R,-1X1'
            'ADD11O,-2X4'
          ]

          handler = (e) ->
            expect(e.message).to.match /width cannot be negative/
            if ++count >= commands.length
              p.removeListener 'error', handler
              done()

          p.on 'error', handler
          p.write param c for c in commands

        it 'should not allow negative side heights', (done) ->
          count = 0
          commands = [
            'ADD10R,1X-1'
            'ADD11O,2X-4'
          ]

          handler = (e) ->
            expect(e.message).to.match /height cannot be negative/
            if ++count >= commands.length
              p.removeListener 'error', handler
              done()

          p.on 'error', handler
          p.write param c for c in commands

        it 'should not allow invalid numbers of vertices', (done) ->
          count = 0
          commands = [
            'ADD10P,6X2'
            'ADD10P,8X13'
          ]

          handler = (e) ->
            expect(e.message).to.match /between 3 and 12/
            if ++count >= commands.length
              p.removeListener 'error', handler
              done()

          p.on 'error', handler
          p.write param c for c in commands

        it 'should not allow negative hole dimensions', (done) ->
          count = 0
          commands = [
            'ADD10C,6X-2'
            'ADD11R,4X3X-2X1'
            'ADD12O,4X3X2X-1'
          ]

          handler = (e) ->
            expect(e.message).to.match /hole.*cannot be negative/
            if ++count >= commands.length
              p.removeListener 'error', handler
              done()

          p.on 'error', handler
          p.write param c for c in commands

        describe 'for holes', ->
          it 'should not allow holes bigger than circle tools', (done) ->
            count = 0
            commands = [
              'ADD10C,50X51'
              'ADD11C,100X81X60'
              'ADD12C,100X60X81'
            ]

            handler = (e) ->
              expect(e.message).to.match /hole.*larger than the shape/
              if ++count >= commands.length
                p.removeListener 'error', handler
                done()

            p.on 'error', handler
            p.write param c for c in commands

          it 'should not allow holes bigger than rectangles/obrounds', (done) ->
            count = 0
            commands = [
              'ADD13R,10X50X11'
              'ADD13R,50X10X11'
              'ADD14O,50X10X40X11'
              'ADD15O,10X50X11X40'
            ]

            handler = (e) ->
              expect(e.message).to.match /hole.*larger than the shape/
              if ++count >= commands.length
                p.removeListener 'error', handler
                done()

            p.on 'error', handler
            p.write param c for c in commands

          it 'should not allow holes bigger than polygons', (done) ->
            count = 0
            commands = [
              'ADD16P,100X7X0X91'
              'ADD17P,100X5X0X71X71'
            ]

            handler = (e) ->
              expect(e.message).to.match /hole.*larger than the shape/
              if ++count >= commands.length
                p.removeListener 'error', handler
                done()

            p.on 'error', handler
            p.write param c for c in commands

        it 'should allow zero size circles without complaint', (done) ->
          fail = (e) ->
            p.removeListener 'warning', fail
            p.removeListener 'error', fail
            throw new Error e.message

          p.on 'error', fail
          p.on 'warning', fail
          p.once 'readable', ->
            p.removeListener 'error', fail
            p.removeListener 'warning', fail
            done()
          p.write param 'ADD10C,0'

        it 'should warn that zero-size rects are not allowed', (done) ->
          count = 0
          commands = [
            'ADD11R,0X2'
            'ADD12R,1X0'
            'ADD13O,0X2'
            'ADD14O,1X0'
          ]

          handler = (w) ->
            expect(w).to.be.an.instanceOf Warning
            expect(w.message).to.match /zero-size/
            if ++count >= commands.length
              p.removeListener 'warning', handler
              done()

          p.on 'warning', handler
          p.write param c for c in commands

        it 'should warn that zero-size polygons are not allowed', (done) ->
          p.once 'warning', (w) ->
            expect(w).to.be.an.instanceOf Warning
            expect(w.message).to.match /zero-size/
            done()

          p.write param 'ADD10P,0X4'

    describe 'with aperture macros', ->
      it 'should parse an aperture macro with modifiers', (done) ->
        p.once 'readable', ->
          data = p.read()
          expect(data.tool).to.eql {D10: {macro: 'CIRC', mods: [1, 0.5]}}
          done()

        p.write param 'ADD10CIRC,1X0.5', 1

      it 'should parse a macro with no modifiers', (done) ->
        p.once 'readable', ->
          data = p.read()
          expect(data.tool).to.eql {D11: {macro: 'RECT', mods: []}}
          done()

        p.write param 'ADD11RECT', 1

  describe 'aperture macro blocks', ->
    it 'should pass along the blocks if an aperture macro', (done) ->
      p.once 'readable', ->
        data = p.read()
        expect(data.macro).to.eql {RECT1: ['21,1,1,1,0,0,0']}
        done()

      p.write param 'AMRECT1', 1
      p.write param '21,1,1,1,0,0,0', 2
      p.write param false

    it 'should know when the aperture macro is over', (done) ->
      type = 'macro'
      cb = done
      results = [
        {RECT1: ['0 macro comment', '21,1,1,1,0,0,0']}
        {RECT2: ['0 macro comment', '21,1,1,1,0,0,0']}
      ]

      p.on 'readable', handler
      p.write param 'AMRECT1', 1
      p.write param '0 macro comment', 2
      p.write param '21,1,1,1,0,0,0', 3
      p.write param false, 3
      p.write param 'AMRECT2', 4
      p.write param '0 macro comment', 5
      p.write param '21,1,1,1,0,0,0', 6
      p.write param false, 6

  describe 'level polarity', ->

    it 'should return a new clear or dark layer', (done) ->
      type = 'new'
      cb = done
      results = [{layer: 'D'}, {layer: 'C'}]

      p.on 'readable', handler
      p.write param 'LPD', 1
      p.write param 'LPC', 2

    it 'should error for a bad polarity', (done) ->
      p.once 'error', (e) ->
        expect(e.message).to.match /line 3 .*level polarity/
        done()

      p.write param 'LPA', 3

  describe 'step repeat', ->
    it 'should return a new step repeat block with good input', (done) ->
      type = 'new'
      cb = done
      results = [
        {sr: {x: 1, y: 1}}
        {sr: {x: 1, y: 1, i: 0, j: 0}}
        {sr: {x: 2, y: 3, i: 2 * F, j: 3 * F}}
        {sr: {x: 1, y: 1}}
      ]

      p.format.places = [2, 2]
      p.on 'readable', handler
      p.write param 'SRX1Y1', 1
      p.write param 'SRX1Y1I0J0', 2
      p.write param 'SRX2Y3I2.0J3.0', 3
      p.write param 'SR', 4

    it 'should throw if bad input', (done) ->
      errorCount = 0
      errors = [
        /line 1 .*I must be a positive number/
        /line 2 .*J must be a positive number/
        /line 3 .*X must be a positive integer/
        /line 4 .*Y must be a positive integer/
        /line 5 .*I must be a positive number/
        /line 6 .*J must be a positive number/
      ]

      handler = (e) ->
        expect(e.message).to.match errors[errorCount]
        if ++errorCount >= errors.length
          p.removeListener 'error', handler
          done()

      p.on 'error', handler
      p.write param 'SRX2Y3J4', 1
      p.write param 'SRX2Y3I4', 2
      p.write param 'SRX-1I1', 3
      p.write param 'SRY-1J2', 4
      p.write param 'SRX2Y2I-1J1', 5
      p.write param 'SRX2Y2I1J-1', 6

  it 'should end the file with an M02', (done) ->
    p.once 'readable', ->
      data = p.read()
      expect(data.set).to.eql {done: true}
      done()

    p.write block 'M02', 1

  it 'should change tools with a tool change block', (done) ->
    type = 'set'
    cb = done
    results = [{currentTool: 'D10'}, {currentTool: 'D11'}]

    p.on 'readable', handler
    p.write block 'D10', 1
    p.write block 'G54D011', 2

  describe 'operating modes', ->
    beforeEach -> type = 'set'

    it 'should turn region mode on and off with a G36 and G37', (done) ->
      cb = done
      results = [{region: true}, {region: false}]

      p.on 'readable', handler
      p.write block 'G36', 1
      p.write block 'G37', 1

    it 'should set the interpolation mode with G01, 2, and 3', (done) ->
      cb = done
      results = [
        {mode: 'i'}
        {mode: 'i'}
        {mode: 'cw'}
        {mode: 'cw'}
        {mode: 'ccw'}
        {mode: 'ccw'}
      ]

      p.on 'readable', handler
      p.write block 'G01', 1
      p.write block 'G1', 2
      p.write block 'G02', 3
      p.write block 'G2', 4
      p.write block 'G03', 5
      p.write block 'G3', 6

    it 'should set the arc mode with G74 (single) and 75 (multi)', (done) ->
      cb = done
      results = [{quad: 's'}, {quad: 'm'}]

      p.on 'readable', handler
      p.write block 'G74', 1
      p.write block 'G75', 2

  describe 'operations', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [2,2]
      type = 'op'

    it 'should parse an interpolation command', (done) ->
      cb = done
      results = [
        {do: 'int', x: 1 * F, y: 1 * F, i: 2 * F, j: 2 * F}
        {do: 'int', x: .22 * F, y: 0}
        {do: 'int', x: 1.1 * F}
        {do: 'int', y: 1.1 * F}
        {do: 'int'}
      ]

      p.on 'readable', handler
      p.write block 'X100Y100I200J200D01', 2
      p.write block 'X22Y0D01', 2
      p.write block 'X110D1', 3
      p.write block 'Y110D1', 4
      p.write block 'D01', 5

    it 'should parse a move command', (done) ->
      cb = done
      results = [
        {do: 'move', x: 3 * F, y: .01 * F}
        {do: 'move', x: -1 * F}
        {do: 'move'}
      ]

      p.on 'readable', handler
      p.write block 'X300Y1D02', 1
      p.write block 'X-100D2', 2
      p.write block 'D02', 3

    it 'should parse a flash command', (done) ->
      cb = done
      results = [
        {do: 'flash', x: 3 * F, y: .01 * F}
        {do: 'flash', x: -1 * F}
        {do: 'flash'}
      ]

      p.on 'readable', handler
      p.write block 'X300Y1D03', 1
      p.write block 'X-100D3', 2
      p.write block 'D03', 3

    it 'should interpolate with an inline mode set', (done) ->
      blockCount = 0
      results = [
        {mode: 'i'}, {do: 'int', x: .01 * F, y: .01 * F}
        {mode: 'cw'}, {do: 'int', x: .01 * F, y: .01 * F}
        {mode: 'ccw'}, {do: 'int', x: .01 * F, y: .01 * F}
      ]

      handler = ->
        data = p.read()
        expect(data.set).to.eql results[blockCount]
        expect(data.op).to.eql results[blockCount + 1]
        blockCount += 2
        if blockCount >= results.length
          p.removeListener 'readable', handler
          done()

      p.on 'readable', handler
      p.write block 'G01X01Y01D01', 1
      p.write block 'G02X01Y01D01', 2
      p.write block 'G03X01Y01D01', 3

    it 'should send a last operation command if op code is missing', (done) ->
      p.once 'readable', ->
        expect(p.read().op).to.eql {do: 'last', x: .01 * F, y: .01 * F}
        done()

      p.write block 'X01Y01'

  it 'should not emit anything if passed empty param', (done) ->
    p.once 'readable', ->
      throw new Error 'empty block emitted something'

    p.write param '', 100
    setTimeout done, 10

  it 'should not emit anything if passed empty block', (done) ->
    p.once 'readable', ->
      throw new Error 'empty param emitted something'

    p.write block '', 100
    setTimeout done, 10

  it 'should handle empty objects in the stream without complaint', (done) ->
    p.once 'error', -> throw new Error 'complained'
    p.once 'warning', -> throw new Error 'complained'

    reads = 0
    handleReadable = ->
      p.read()
      if ++reads >= 2
        p.removeListener 'readable', handleReadable
        done()

    p.on 'readable', handleReadable
    p.write param 'MOMM', 1
    p.write {}
    p.write block 'G71', 2
