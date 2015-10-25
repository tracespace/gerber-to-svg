# unit tests for shape objects
shapes = require '../src/pad-shapes'
expect = require('chai').expect

describe 'shape functions', ->
  describe 'for lower left rectangles', ->
    it 'should return a rectangle given the proper parameters', ->
      result = shapes.lowerLeftRect { x: 1, y: 3, width: 10, height: 5 }
      expect( result.shape.rect.x ).to.equal 1
      expect( result.shape.rect.y ).to.equal 3
      expect( result.shape.rect.width ).to.equal 10
      expect( result.shape.rect.height ).to.equal 5
    it 'should throw errors for missing parameters', ->
      expect( -> shapes.lowerLeftRect { y: 3, width: 10, height: 5 } )
        .to.throw /requires x/
      expect( -> shapes.lowerLeftRect { x: 1, width: 10, height: 5 } )
        .to.throw /requires y/
      expect( -> shapes.lowerLeftRect { x: 1, y: 3, height: 5 } )
        .to.throw /requires width/
      expect( -> shapes.lowerLeftRect { x: 1, y: 3, width: 10 } )
        .to.throw /requires height/
    it 'should calculate the bounding box', ->
      result = shapes.lowerLeftRect { x: 1, y: 3, width: 10, height: 5 }
      expect( result.bbox ).to.eql [ 1, 3, 11, 8 ]

  describe 'for outline polygons', ->
    it 'should return a polygon given proper parameters', ->
      result = shapes.outline {points: [0, 0, 1, 0, 1, 1, 0, 0]}
      expect(result.shape.polygon.points).to.eql '0,0 1,0 1,1 0,0'

    it 'should throw an error if the paramter isnt an array or is missing', ->
      expect(-> shapes.outline {}).to.throw /requires points array/
      expect(-> shapes.outline {points: 5}).to.throw /requires points array/
      expect(-> shapes.outline {points: [5, 2]})
        .to.throw /requires more than one point/
      expect(-> shapes.outline {points: [5, 2, 6, 7, 8]})
        .to.throw /must be even/

    it 'should throw an error if the last point doesnt match the first', ->
      expect(-> shapes.outline {points: [1, 0, 0, 1]})
        .to.throw /last point must match first point/

    it 'should calculate the bounding box', ->
      result = shapes.outline {points: [0, 0, 1, 0, 1, 1, 0, 0]}
      expect(result.bbox).to.eql [0, 0, 1, 1]

  describe 'for moirés', ->
    it 'should return an array of objects that creates a moiré', ->
      result = shapes.moire {
        cx: 0
        cy: 0
        outerDia: 16
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }
      expect( result.shape ).to.deep.eql [
        {
          line: {
            x1: -6
            y1: 0
            x2: 6
            y2: 0
            'stroke-width': 0.5
            'stroke-linecap': 'butt'
          }
        }
        {
          line: {
            x1: 0
            y1: -6
            x2: 0
            y2: 6
            'stroke-width': 0.5
            'stroke-linecap': 'butt'
          }
        }
        { circle: { cx: 0, cy: 0, r: 7, 'stroke-width': 2, fill: 'none' } }
        { circle: { cx: 0, cy: 0, r: 3, 'stroke-width': 2, fill: 'none' } }
      ]
    it 'should throw errors for missing parameters', ->
      expect( -> shapes.moire {
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).to.throw /requires x center/
      expect( -> shapes.moire {
        cx: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).to.throw /requires y center/
      expect( -> shapes.moire {
        cx: 0
        cy: 0
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).to.throw /requires outer diameter/
      expect( -> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).to.throw /requires ring thickness/
      expect( -> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).to.throw /requires ring gap/
      expect( -> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        crossLength: 12
        crossThx: 0.5
      }).to.throw /requires max rings/
      expect( -> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossThx: 0.5
      }).to.throw /requires crosshair length/
      expect( -> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
      }).to.throw /requires crosshair thickness/
    it 'should calculate the bounding box', ->
      result = shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }
      expect( result.bbox ).to.eql [ -6, -6, 6, 6 ]
      result = shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 8
        crossThx: 0.5
      }
      expect( result.bbox ).to.eql [ -5, -5, 5, 5 ]

  describe 'for thermals', ->
    it 'should return a thermal given proper parameters', ->
      result = shapes.thermal {cx: 0, cy: 0, outerDia: 10, innerDia: 8, gap: 3}
      maskId = result.shape[0].mask.id
      expect( result.shape[0].mask._ ).to.deep.eql [
        { circle: { cx: 0, cy: 0, r: 5, fill: '#fff' } }
        { rect: { x: -5, y: -1.5, width: 10, height: 3, fill: '#000' } }
        { rect: { x: -1.5, y: -5, width: 3, height: 10, fill: '#000' } }
      ]
      expect( result.shape[1].circle ).to.eql {
        cx: 0
        cy: 0,
        r: 4.5
        fill: 'none'
        'stroke-width': 1
        mask: "url(##{maskId})"
      }

    it 'should throw errors if parameters are missing', ->
      expect( -> shapes.thermal { cy: 0, outerDia: 10, innerDia: 8, gap: 3 })
        .to.throw /requires x center/
      expect( -> shapes.thermal { cx: 0, outerDia: 10, innerDia: 8, gap: 3 })
        .to.throw /requires y center/
      expect( -> shapes.thermal { cx: 0, cy: 0, innerDia: 8, gap: 3 })
        .to.throw /requires outer diameter/
      expect( -> shapes.thermal { cx: 0, cy: 0, outerDia: 10, gap: 3 })
        .to.throw /requires inner diameter/
      expect( -> shapes.thermal { cx: 0, cy: 0, outerDia: 10, innerDia: 8 })
        .to.throw /requires gap/
    it 'should calculate the bounding box', ->
      r = shapes.thermal { cx: 0, cy: 0, outerDia: 10, innerDia: 8, gap: 3 }
      expect( r.bbox ).to.eql [ -5, -5, 5, 5 ]
