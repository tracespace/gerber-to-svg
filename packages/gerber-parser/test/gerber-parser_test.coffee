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
    # it 'should get the name', (done) ->
    #   p.once 'readable', ->
    #     data = p.read()
    #     expect(data.macro.RECT1).to.exist
    #     done()
    #
    #   p.write param 'AMRECT1', 1
    #   p.write param false

    # it 'should know when the aperture macro is over', (done) ->
    #   type = 'macro'
    #   cb = done
    #   results = [
    #     {RECT1: []}
    #     {RECT2: []}
    #   ]
    #
    #   p.on 'readable', handler
    #   p.write param 'AMRECT1', 1
    #   p.write param false, 2
    #   p.write param 'AMRECT2', 3
    #   p.write param false, 4

    # it 'should differentiate between macro and other params ending', (done) ->
    #   handleReadable = ->
    #     result = p.read()
    #     expect(result.macro).to.not.exist
    #
    #   p.on 'readable', handleReadable
    #   p.write param 'FSLAX34Y34', 1
    #   p.write param false, 1
    #
    #   setTimeout ->
    #     p.removeListener 'readable', handleReadable
    #     done()
    #   , 10

    describe 'primitive blocks', ->
      # it 'should parse a circle primitive', (done) ->
      #   p.once 'readable', ->
      #     r = p.read()
      #     expect(r.macro.CIRC1).to.eql [
      #       {shape: 'circle', exp: '1', dia: '5-$1', cx: '1', cy: '2'}
      #     ]
      #     done()
      #
      #   p.write param 'AMCIRC1', 1
      #   p.write param '1,1,5-$1,1,2', 2
      #   p.write param false, 2

      # it 'should parse a vector primitive', (done) ->
      #   type = 'macro'
      #   cb = done
      #   results = [
      #     {
      #       VECT1: [
      #         {
      #           shape: 'vector'
      #           exp: '1'
      #           width: '2'
      #           x1: '3'
      #           y1: '4'
      #           x2: '5'
      #           y2: '6'
      #           rot: '7'
      #         }
      #       ]
      #     }
      #     {
      #       VECT2: [
      #         {
      #           shape: 'vector'
      #           exp: '0'
      #           width: '$1'
      #           x1: '$2'
      #           y1: '$3'
      #           x2: '$4'
      #           y2: '$5'
      #           rot: '$6'
      #         }
      #       ]
      #     }
      #   ]
      #
      #   p.on 'readable', handler
      #   p.write param 'AMVECT1', 1
      #   p.write param '2,1,2,3,4,5,6,7', 2
      #   p.write param false, 2
      #   p.write param 'AMVECT2', 3
      #   p.write param '20,0,$1,$2,$3,$4,$5,$6', 4
      #   p.write param false, 4

      # it 'should parse a rectangle primitive', (done) ->
      #   type = 'macro'
      #   cb = done
      #   results = [
      #     {
      #       RECT1: [
      #         {
      #           shape: 'rect'
      #           exp: '1'
      #           width: '2'
      #           height: '3'
      #           cx: '4'
      #           cy: '5'
      #           rot: '6'
      #         }
      #       ]
      #     }
      #     {
      #       RECT2: [
      #         {
      #           shape: 'rect'
      #           exp: '0'
      #           width: '$1'
      #           height: '$2'
      #           cx: '$3'
      #           cy: '$4'
      #           rot: '$5'
      #         }
      #       ]
      #     }
      #   ]
      #
      #   p.on 'readable', handler
      #   p.write param 'AMRECT1', 1
      #   p.write param '21,1,2,3,4,5,6', 2
      #   p.write param false, 2
      #   p.write param 'AMRECT2', 3
      #   p.write param '21,0,$1,$2,$3,$4,$5', 4
      #   p.write param false, 4

      # it 'should parse a lower left rectangle primitive', (done) ->
      #   type = 'macro'
      #   cb = done
      #   results = [
      #     {
      #       RECT1: [
      #         {
      #           shape: 'lowerLeftRect'
      #           exp: '1'
      #           width: '2'
      #           height: '3'
      #           x: '4'
      #           y: '5'
      #           rot: '6'
      #         }
      #       ]
      #     }
      #     {
      #       RECT2: [
      #         {
      #           shape: 'lowerLeftRect'
      #           exp: '0'
      #           width: '$1'
      #           height: '$2'
      #           x: '$3'
      #           y: '$4'
      #           rot: '$5'
      #         }
      #       ]
      #     }
      #   ]
      #
      #   p.on 'readable', handler
      #   p.write param 'AMRECT1', 1
      #   p.write param '22,1,2,3,4,5,6', 2
      #   p.write param false, 2
      #   p.write param 'AMRECT2', 3
      #   p.write param '22,0,$1,$2,$3,$4,$5', 4
      #   p.write param false, 4

      # it 'should parse a outline polygon', (done) ->
      #   type = 'macro'
      #   cb = done
      #   results = [
      #     {
      #       OUT1: [
      #         {
      #           shape: 'outline'
      #           exp: '1'
      #           points: ['1', '2', '3', '4', '5', '6', '7', '8']
      #           rot: '9'
      #         }
      #       ]
      #     }
      #     {
      #       OUT2: [
      #         {
      #           shape: 'outline'
      #           exp: '0'
      #           points: ['$1', '$2', '$3', '$4', '$5', '$6', '$7', '$8']
      #           rot: '$9'
      #         }
      #       ]
      #     }
      #   ]
      #
      #   p.on 'readable', handler
      #   p.write param 'AMOUT1', 1
      #   p.write param '4,1,3,1,2,3,4,5,6,7,8,9', 2
      #   p.write param false, 2
      #   p.write param 'AMOUT2', 3
      #   p.write param '4,0,3,$1,$2,$3,$4,$5,$6,$7,$8,$9', 4
      #   p.write param false, 4

      it 'should parse a regular polygon', (done) ->
        type = 'macro'
        cb = done
        results = [
          {
            POLY1: [
              {
                shape: 'polygon'
                exp: '1'
                vertices: '3'
                cx: '4'
                cy: '5'
                dia: '6'
                rot: '7'
              }
            ]
          }
          {
            POLY2: [
              {
                shape: 'polygon'
                exp: '0'
                vertices: '$1'
                cx: '$2'
                cy: '$3'
                dia: '$4'
                rot: '$5'
              }
            ]
          }
        ]

        p.on 'readable', handler
        p.write param 'AMPOLY1', 1
        p.write param '5,1,3,4,5,6,7', 2
        p.write param false, 2
        p.write param 'AMPOLY2', 3
        p.write param '5,0,$1,$2,$3,$4,$5', 4
        p.write param false, 4

      it 'should parse a moire primitive', (done) ->
        type = 'macro'
        cb = done
        results = [
          {
            MOIRE1: [
              {
                shape: 'moire'
                exp: '1'
                cx: '1'
                cy: '2'
                outerDia: '3'
                ringThx: '4'
                ringGap: '5'
                maxRings: '6'
                crossThx: '7'
                crossLength: '8'
                rot: '9'
              }
            ]
          }
          {
            MOIRE2: [
              {
                shape: 'moire'
                exp: '0'
                cx: '$1'
                cy: '$2'
                outerDia: '$3'
                ringThx: '$4'
                ringGap: '$5'
                maxRings: '$6'
                crossThx: '$7'
                crossLength: '$8'
                rot: '$9'
              }
            ]
          }
        ]

        p.on 'readable', handler
        p.write param 'AMMOIRE1', 1
        p.write param '6,1,1,2,3,4,5,6,7,8,9', 2
        p.write param false, 2
        p.write param 'AMMOIRE2', 3
        p.write param '6,0,$1,$2,$3,$4,$5,$6,$7,$8,$9', 4
        p.write param false, 4

      it 'should parse a thermal primitive', (done) ->
        type = 'macro'
        cb = done
        results = [
          {
            THERMAL1: [
              {
                shape: 'thermal'
                exp: '1'
                cx: '1'
                cy: '2'
                outerDia: '3'
                innerDia: '4'
                gap: '5'
                rot: '6'
              }
            ]
          }
          {
            THERMAL2: [
              {
                shape: 'thermal'
                exp: '0'
                cx: '$1'
                cy: '$2'
                outerDia: '$3'
                innerDia: '$4'
                gap: '$5'
                rot: '$6'
              }
            ]
          }
        ]

        p.on 'readable', handler
        p.write param 'AMTHERMAL1', 1
        p.write param '7,1,1,2,3,4,5,6', 2
        p.write param false, 2
        p.write param 'AMTHERMAL2', 3
        p.write param '7,0,$1,$2,$3,$4,$5,$6', 4
        p.write param false, 4

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
