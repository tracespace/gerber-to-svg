# tests for the aperture macro class
expect = require('chai').expect
filter = require 'lodash.filter'

Macro = require '../src/macro-tool'
factor = require('../src/svg-coord').factor
Warning = require '../src/warning'

describe 'tool macro class', ->
  m = null
  beforeEach -> m = new Macro()

  it 'should save the blocks for processing', ->
    circle = {shape: 'circle', exp: '1', dia: '5-$1', cx: '1', cy: '2'}
    variable = {modifier: '$3', value: '$1+$2'}
    m = new Macro [circle, variable]
    expect(m.blocks[0]).to.equal circle
    expect(m.blocks[1]).to.equal variable

  describe 'getNumber method', ->
    it 'should return a number if passed a string of a number', ->
      expect(m.getNumber '2.4').to.equal 2.4

    it 'should return the modifier if passed a reference to a modifier', ->
      m.modifiers.$2 = 3.5
      expect(m.getNumber '$2').to.equal 3.5

    it 'should get all the numbers in an array', ->
      m.modifiers.$1 = 1
      m.modifiers.$2 = 2
      expect(m.getNumber ['$1', '$2', '3', '4']).to.eql [1, 2, 3, 4]

    describe 'arithmetic evaluate method', ->
      it 'should obey order of operations', ->
        expect(m.getNumber '1+2x3').to.equal 7
        expect(m.getNumber '1-2x3').to.equal -5
        expect(m.getNumber '1+1/2').to.equal 1.5
        expect(m.getNumber '1-1/2').to.equal 0.5

      it 'should allow parentheses to overide order of operations', ->
        expect(m.getNumber '(1+2)x3').to.equal 9
        expect(m.getNumber '(1-2)x3').to.equal -3
        expect(m.getNumber '(1+1)/2').to.equal 1
        expect(m.getNumber '(1-1)/2').to.equal 0

    it 'should return a number if passed a string with arithmetic', ->
      m.modifiers.$1 = 2.6
      expect(m.getNumber '$1+5').to.equal 7.6

  describe 'primitive method', ->
    describe 'for circles', ->
      it 'should add a circle to the shapes and the bbox', ->
        m.primitive {shape: 'circle', exp: '1', dia: '5', cx: '1', cy: '2'}
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].circle).to.contain {
          cx: 1 * factor, cy: 2 * factor, r: 2.5 * factor
        }
        expect(m.masks).to.eql []
        expect(m.bbox).to.eql [
          -1.5 * factor, -0.5 * factor, 3.5 * factor, 4.5 * factor
        ]

    describe 'for vector lines', ->
      it 'should add a vector line to the shapes and bbox', ->
        m.primitive {
          shape: 'vector'
          exp: '1'
          width: '5'
          x1: '1'
          y1: '1'
          x2: '15'
          y2: '1'
          rot: '0'
        }
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].line).to.contain {
          x1: 1 * factor
          y1: 1 * factor
          x2: 15 * factor
          y2: 1 * factor
          'stroke-width': 5 * factor
          'stroke-linecap': 'butt'
        }
        expect(m.masks).to.eql []
        expect(m.bbox).to.eql [
          1 * factor, -1.5 * factor, 15 * factor, 3.5 * factor
        ]

      it 'should be able to rotate the line', ->
        m.primitive {
          shape: 'vector'
          exp: '1'
          width: '5', x1: '1', y1: '0', x2: '10', y2: '0', rot: '90'
        }
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].line.transform).to.eql 'rotate(90)'
        expect(m.bbox).to.eql [
          -2.5 * factor, 1 * factor, 2.5 * factor, 10 * factor
        ]

    describe 'for center rects', ->
      it 'should add a center rect to the shapes and bbox', ->
        m.primitive {
          shape: 'rect'
          exp: '1'
          width: '4', height: '5', cx: '1', cy: '2', rot: '0'
        }
        expect(m.shapes[0].rect).to.contain {
          x: -1 * factor
          y: -0.5 * factor
          width: 4 * factor
          height: 5 * factor
        }
        expect(m.masks).to.be.empty
        expect(m.bbox).to.eql [
          -1 * factor, -.5 * factor, 3 * factor, 4.5 * factor
        ]

      it 'should be able to rotate the rect', ->
        m.primitive {
          shape: 'rect'
          exp: '1'
          width: '5', height: '10', cx: '0', cy: '0', rot: '270'
        }
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].rect.transform).to.eql 'rotate(270)'
        expect(m.bbox).to.eql [
          -5 * factor, -2.5 * factor, 5 * factor, 2.5 * factor
        ]

    describe 'for lower left rects', ->

      it 'should add a lower left rect to the shapes and box', ->
        m.primitive {
          shape: 'lowerLeftRect'
          exp: '1'
          width: '6', height: '6', x: '-1', y: '-1', rot: '0'
        }
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].rect).to.contain {
          x: -1 * factor
          y: -1 * factor
          width: 6 * factor
          height: 6 * factor
        }
        expect(m.masks).to.be.empty
        expect(m.bbox).to.eql [
          -1 * factor, -1 * factor, 5 * factor, 5 * factor
        ]

      it 'should be able to rotate the rect', ->
        m.primitive {
          shape: 'lowerLeftRect'
          exp: '1'
          width: '5', height: '10', x: '0', y: '0', rot: '180'
        }
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].rect.transform).to.eql 'rotate(180)'
        expect(m.bbox).to.eql [-5 * factor, -10 * factor, 0, 0]

    describe 'for outline polygons', ->
      it 'should add an outline polygon to the shapes and bbox', ->
        m.primitive {
          shape: 'outline'
          exp: '1'
          points: ['1', '1', '2', '2', '1', '3', '0', '2', '1', '1']
          rot: '0'
        }
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].polygon.points).to.eql "
          #{1 * factor},#{1 * factor}
          #{2 * factor},#{2 * factor}
          #{1 * factor},#{3 * factor}
          #{0 * factor},#{2 * factor}
          #{1 * factor},#{1 * factor}
        "
        expect(m.masks).to.be.empty
        expect(m.bbox).to.eql [0, 1 * factor, 2 * factor, 3 * factor]

      it 'should be able to rotate the outline', ->
        m.primitive {
          shape: 'outline'
          exp: '1'
          points: ['1', '1', '2', '2', '1', '3', '0', '2', '1', '1']
          rot: '-90'
        }
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].polygon.transform).to.eql 'rotate(-90)'
        expect(m.bbox).to.eql [1 * factor, -2 * factor, 3 * factor, 0]

    describe 'for regular polygons', ->
      it 'should add a regular polygon to the shapes and bbox', ->
        m.primitive {
          shape: 'polygon'
          exp: '1'
          vertices: '4', cx: '0', cy: '0', dia: '5', rot: '0'
        }
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].polygon.points).to.eql "
          #{2.5 * factor},0
          0,#{2.5 * factor}
          #{-2.5 * factor},0
          0,#{-2.5 * factor}
        "
        expect(m.masks).to.be.empty
        expect(m.bbox).to.eql [
          -2.5 * factor, -2.5 * factor, 2.5 * factor, 2.5 * factor
        ]

      it 'should be able to rotate the polygon if the center is 0,0', ->
        m.primitive {
          shape: 'polygon'
          exp: '1'
          vertices: '4', cx: '0', cy: '0', dia: '5', rot: '45'
        }
        d = 2.5 * factor / Math.sqrt 2
        expect(m.bbox[0] + d).to.be.closeTo 0, 0.0000001
        expect(m.bbox[1] + d).to.be.closeTo 0, 0.0000001
        expect(m.bbox[2] - d).to.be.closeTo 0, 0.0000001
        expect(m.bbox[3] - d).to.be.closeTo 0, 0.0000001

      it 'should warn and not rotate if center is not 0, 0', (done) ->
        warnings = 0
        polygons = [
          {
            shape: 'polygon'
            exp: '1'
            vertices: '4', cx: '1', cy: '0', dia: '6', rot: '45'
          }
          {
            shape: 'polygon'
            exp: '1'
            vertices: '4', cx: '0', cy: '1', dia: '6', rot: '45'
          }
        ]
        points = [
          "#{4 * factor},0
           #{1 * factor},#{3 * factor}
           #{-2 * factor},0
           #{1 * factor},#{-3 * factor}"
          "#{3 * factor},#{1 * factor}
           0,#{4 * factor}
           #{-3 * factor},#{1 * factor}
           0,#{-2 * factor}"
        ]

        handleWarning = (w) ->
          expect(w).to.be.an.instanceOf Warning
          expect(w.message).to.match /rotate.*center/
          setTimeout ->
            expect(m.shapes[warnings].polygon.points).to.eql points[warnings]
            if ++warnings >= polygons.length
              m.removeListener 'warning', handleWarning
              done()
            else
              m.primitive polygons[warnings]
          , 1

        m.on 'warning', handleWarning
        m.primitive polygons[warnings]

    describe 'for moirés', ->
      it 'should add a moiré to the shapes and bbox', ->
        m.primitive {
          shape: 'moire'
          cx: '0', cy: '0', outerDia: '20'
          ringThx: '2', ringGap: '2', maxRings: '3'
          crossThx: '2', crossLength: '22', rot: '0'
        }
        lines = filter m.shapes, 'line'
        rings = filter m.shapes, 'circle'
        expect(lines).to.have.length 2
        expect(rings).to.have.length 3
        expect(m.bbox).to.eql [
          -11 * factor, -11 * factor, 11 * factor, 11 * factor
        ]

      it 'should rotate the crosshairs if center is 0, 0', ->
        m.primitive {
          shape: 'moire'
          cx: '0', cy: '0', outerDia: '20'
          ringThx: '2', ringGap: '2', maxRings: '3'
          crossThx: '2', crossLength: '22', rot: '45'
        }
        lines = filter m.shapes, (s) -> s.line?.transform is 'rotate(45)'
        expect(lines).to.have.length 2

      it 'should warn and not rotate if center is not 0, 0', (done) ->
        warnings = 0
        handleWarning = (w) ->
          expect(w).to.be.an.instanceOf Warning
          expect(w.message).to.match /moiré.*center/
          warnings++

        m.on 'warning', handleWarning
        m.primitive {
          shape: 'moire'
          cx: '1', cy: '0', outerDia: '20'
          ringThx: '2', ringGap: '2', maxRings: '3'
          crossThx: '2', crossLength: '22', rot: '45'
        }
        m.primitive {
          shape: 'moire'
          cx: '0', cy: '1', outerDia: '20'
          ringThx: '2', ringGap: '2', maxRings: '3'
          crossThx: '2', crossLength: '22', rot: '45'
        }

        setTimeout ->
          lines = filter m.shapes, 'line'
          rings = filter m.shapes, 'circle'
          rotatedLines = filter lines, 'line.transform'
          expect(lines).to.have.length 4
          expect(rings).to.have.length 6
          expect(rotatedLines).to.be.empty
          expect(warnings).to.equal 2
          done()
        , 10

    describe 'for thermals', ->
      it 'should add a thermal to the shapes, mask, and bbox', ->
        m.primitive {
          shape: 'thermal'
          cx: '0', cy: '0', outerDia: '10', innerDia: '8', gap: '2', rot: '0'
        }

        maskCircles = filter m.masks[0].mask._, 'circle'
        maskRects = filter m.masks[0].mask._, 'rect'
        expect(m.masks).to.have.length 1
        expect(maskCircles).to.have.length 1
        expect(maskRects).to.have.length 2

        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].circle).to.exist

      it 'should rotate the cutout if center is 0,0', ->
        m.primitive {
          shape: 'thermal'
          cx: '0', cy: '0', outerDia: '10', innerDia: '8', gap: '2', rot: '30'
        }
        res = filter m.masks[0].mask._, (s) -> s.rect?.transform is 'rotate(30)'
        expect(res).to.have.length 2

      it 'should warn and not rotate if center is not 0, 0', (done) ->
        warnings = 0
        handleWarning = (w) ->
          expect(w).to.be.an.instanceOf Warning
          expect(w.message).to.match /thermal.*center/
          warnings++

        m.on 'warning', handleWarning
        m.primitive {
          shape: 'thermal'
          cx: '1', cy: '0', outerDia: '10', innerDia: '8', gap: '2', rot: '30'
        }
        m.primitive {
          shape: 'thermal'
          cx: '0', cy: '2', outerDia: '10', innerDia: '8', gap: '2', rot: '30'
        }

        setTimeout ->
          rects = filter m.masks[0].mask._, 'rect'
          rects = rects.concat filter m.masks[1].mask._, 'rect'
          circles = filter m.shapes, 'circle'
          rotatedRects = filter rects, 'rect.transform'
          expect(rects).to.have.length 4
          expect(circles).to.have.length 2
          expect(rotatedRects).to.be.empty
          expect(warnings).to.equal 2
          done()
        , 10

    it 'should be able to have a few primitives involved', ->
      # add a circle
      m.primitive {shape: 'circle', exp: '1', dia: '10', cx: '0', cy: '0'}
      # add another circle
      m.primitive {shape: 'circle', exp: '1', dia: '10', cx: '2', cy: '2'}
      # add a rectangle
      m.primitive {
        shape: 'rect', exp: '1'
        width: '5', height: '10', cx: '0', cy: '0', rot: '0'
      }
      expect(m.shapes).to.have.length 3

    describe 'exposure', ->
      it "shouldn't do anything if there's no existing shape", ->
        m.primitive {shape: 'circle', exp: '0', dia: '5', cx: '0', cy: '0'}
        expect(m.masks).to.be.empty
        expect(m.shapes).to.be.empty

      it 'should add a mask to only existing shape', ->
        m.primitive {shape: 'circle', exp: '1', dia: '10', cx: '0', cy: '0'}
        # cut out a smaller circle
        m.primitive {shape: 'circle', exp: '0', dia: '5', cx: '0', cy: '0'}
        expect(m.masks).to.have.length 1
        expect(m.masks[0].mask._).to.deep.contain.members [
          {
            rect: {
              x: -5 * factor
              y: -5 * factor
              width: 10 * factor
              height: 10 * factor
              fill: '#fff'
            }
          }
          {circle: {cx: 0, cy: 0, r: 2.5 * factor, fill: '#000'}}
        ]
        # get mask id
        maskId = m.masks[0].mask.id
        # check that shape was masked
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].circle.mask).to.eql "url(##{maskId})"

      it 'should group up previous shapes if theres several and mask them', ->
        # add a few circles
        m.primitive {shape: 'circle', exp: '1', dia: '10', cx: '0', cy: '0'}
        m.primitive {shape: 'circle', exp: '1', dia: '9', cx: '5', cy: '0'}
        # cut out a smaller circle
        m.primitive {shape: 'circle', exp: '0', dia: '5', cx: '5', cy: '0'}
        # mask should use the bounding box
        expect(m.masks.length).to.equal 1
        expect(m.masks[0].mask._).to.deep.contain.members [
          {
            rect: {
              x: -5 * factor
              y: -5 * factor
              width: 14.5 * factor
              height: 10 * factor
              fill: '#fff'
            }
          }
          {circle: {cx: 5 * factor, cy: 0, r: 2.5 * factor, fill: '#000'}}
        ]
        maskId = m.masks[0].mask.id
        # shapes should be a single group
        expect(m.shapes).to.have.length 1
        expect(m.shapes[0].g.mask).to.eql "url(##{maskId})"
        expect(m.shapes[0].g._).to.have.length 2
        expect(m.shapes[0].g._[0].circle).to.contain {r: 5 * factor}
        expect(m.shapes[0].g._[1].circle).to.contain {r: 4.5 * factor}

      it 'should add several clear shapes in a row to the same mask', ->
        # add a rectangle
        m.primitive {
          shape: 'rect', exp: '1'
          width: '10', height: '5', cx: '1', cy: '0', rot: '0'
        }
        # clear out two smaller circles
        m.primitive {shape: 'circle', exp: '0', dia: '3', cx: '3', cy: '0'}
        m.primitive {shape: 'circle', exp: '0', dia: '2', cx: '-3', cy: '0'}
        expect(m.shapes.length).to.equal 1
        expect(m.masks.length).to.equal 1
        expect(m.masks[0].mask._).to.have.length 3
        expect(m.masks[0].mask._[0].rect).to.contain {width: 10 * factor}
        expect(m.masks[0].mask._[1].circle).to.contain {r: 1.5 * factor}
        expect(m.masks[0].mask._[2].circle).to.contain {r: 1 * factor}

  describe 'run method', ->
    it 'should set modifiers that are passed in', ->
      MODIFIERS = [1, 1.5, 0, -0.76]
      result = m.run 'D10', MODIFIERS
      expect(m.modifiers.$1).to.equal 1
      expect(m.modifiers.$2).to.equal 1.5
      expect(m.modifiers.$3).to.equal 0
      expect(m.modifiers.$4).to.equal -0.76

    it 'should call the primitive method on primitives', ->
      m.blocks = [{shape: 'circle', exp: '1', dia: '5', cx: '0', cy: '0'}]
      m.run()
      expect(m.shapes[0].circle).to.contain {r: 2.5 * factor, cx: 0, cy: 0}

    it 'should set modifiers on modifier expressions', ->
      m.blocks = [{modifier: '$1', value: '1+2'}]
      m.run()
      expect(m.modifiers.$1).to.equal 3

    it 'should return a pad array with a single shape in it', ->
      m.blocks = [{shape: 'circle', exp: '1', dia: '5', cx: '0', cy: '0'}]
      result = m.run()
      expect(result.pad).to.have.length 1
      expect(result.pad[0].circle).to.contain {r: 2.5 * factor, cx: 0, cy: 0}

    it 'should return a group if there were several primitives', ->
      m.blocks = [
        {shape: 'circle', exp: '1', dia: '5', cx: '0', cy: '0'}
        {shape: 'circle', exp: '1', dia: '5', cx: '5', cy: '5'}
      ]
      result = m.run 'D10'
      expect(result.pad[0].g._).to.have.length 2
      circle0 = result.pad[0].g._[0].circle
      circle1 = result.pad[0].g._[1].circle
      expect(circle0).to.contain {cx: 0, cy: 0}
      expect(circle1).to.contain {cx: 5 * factor, cy: 5 * factor}

    it 'should give take a tool code to generate an id and return it', ->
      m.blocks = [{shape: 'circle', exp: '1', dia: '5', cx: '0', cy: '0'}]
      result = m.run 'D10'
      expect(result.padId).to.match /tool-D10-pad/
      expect(result.pad[0].circle.id).to.equal result.padId

      m = new Macro [
        {shape: 'circle', exp: '1', dia: '5', cx: '0', cy: '0'}
        {shape: 'circle', exp: '1', dia: '5', cx: '5', cy: '5'}
      ]
      result = m.run 'D11'
      expect(result.padId).to.match /tool-D11-pad/
      expect(result.pad[0].g.id).to.equal result.padId

    it 'should return any masks at the front of the pad array', ->
      m.blocks = [
        {shape: 'circle', exp: '1', dia: '5', cx: '0', cy: '0'}
        {shape: 'circle', exp: '0', dia: '2', cx: '0', cy: '0'}
      ]
      result = m.run 'D10'
      expect(result.pad).to.have.length 2
      expect(result.pad[0].mask).to.exist
      expect(result.pad[1].circle).to.exist

    it 'should return the bounding box', ->
      m.blocks = [{shape: 'circle', exp: '1', dia: '4', cx: '0', cy: '0'}]
      result = m.run()
      expect(result.bbox).to.eql [
        -2 * factor, -2 * factor, 2 * factor, 2 * factor
      ]

    it 'should return a false flag for being traceable', ->
      result = m.run()
      expect(result.trace).to.be.false

    it 'should be able to create multiple tools from the same macro', ->
      m.blocks = [{shape: 'circle', exp: '1', dia: '$1', cx: '0', cy: '0'}]
      result = m.run 'D10', [1]
      expect(result.pad.length).to.equal 1
      expect(result.pad[0].circle.r).to.equal 0.5 * factor
      result = m.run 'D11', [2]
      expect(result.pad.length).to.equal 1
      expect(result.pad[0].circle.r).to.equal 1 * factor
