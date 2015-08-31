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

  describe 'parsing an aperture definition', ->
    beforeEach ->
      p.format.zero = 'L'
      p.format.places = [2, 2]
      type = 'tool'

    describe 'with standard tools', ->

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

  describe 'aperture macro blocks', ->

    describe 'primitive blocks', ->

      it 'should parse a variable definition', (done) ->
        p.once 'readable', ->
          result = p.read()
          expect(result.macro.VAR1).to.eql [{modifier: '$3', value: '$1+$2'}]
          done()

        p.write param 'AMVAR1', 1
        p.write param '$3=$1+$2', 2
        p.write param false, 2

      it 'should parse multiple things (including comments)', (done) ->
        p.once 'readable', ->
          result = p.read()
          expect(result.macro.MACRO1).to.deep.eql [
            {
              shape: 'outline'
              exp: '1'
              points: ['1', '2', '3', '4', '5', '6', '7', '8']
              rot: '9'
            }
            {shape: 'circle', exp: '0', dia: '5-$1', cx: '1', cy: '2'}
            {modifier: '$3', value: '$1+$2'}
            {
              shape: 'rect'
              exp: '1'
              width: '2'
              height: '3'
              cx: '4'
              cy: '5'
              rot: '6'
            }
          ]
          done()

        p.write param 'AMMACRO1', 1
        p.write param '0 outline polygon', 2
        p.write param '4,1,3,1,2,3,4,5,6,7,8,9', 3
        p.write param '0 circle', 4
        p.write param '1,0,5-$1,1,2', 5
        p.write param '0 variable set', 6
        p.write param '$3=$1+$2', 7
        p.write param '0 rectangle', 8
        p.write param '21,1,2,3,4,5,6', 9
        p.write param '0 macro end', 10
        p.write param false, 11

      it 'should warn if uppercase X used for multiplication', (done) ->
        warned = false
        p.once 'warning', (w) ->
          expect(w.message).to.match /line 7 .*multiplication/
          warned = true

        p.once 'readable', ->
          result = p.read()
          expect(result.macro.VAR1[0].value).to.eql '$1x($2x$3)'
          expect(warned).to.be.true
          done()

        p.write param 'AMVAR1', 6
        p.write param '$3=$1X($2X$3)', 7
        p.write param false, 7
