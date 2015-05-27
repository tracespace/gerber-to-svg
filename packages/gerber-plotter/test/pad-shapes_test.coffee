# unit tests for shape objects
shapes = require '../src/pad-shapes'
expect = require('chai').expect

describe 'shape functions', ->
  describe 'for circles', ->
    it 'should create circle with the paramters passed in', ->
      result = shapes.circle {dia: 10, cx: 4, cy: 3}
      expect( result.shape.circle.r ).to.equal 5
      expect( result.shape.circle.cx ).to.equal 4
      expect( result.shape.circle.cy ).to.equal 3
    it 'should throw an error if parameters are missing', ->
      expect( -> shapes.circle {cx: 4, cy: 3} ).to.throw /requires diameter/
      expect( -> shapes.circle {dia: 10, cy: 3} ).to.throw /requires x center/
      expect( -> shapes.circle {dia: 10, cx: 4} ).to.throw /requires y center/
    it 'should calculate the bounding box', ->
      result = shapes.circle { dia: 8, cx: 12, cy: 6 }
      expect( result.bbox ).to.eql [ 8, 2, 16, 10 ]

  describe 'for rectangles', ->
    it 'should create a rectangle with the parameters passed in', ->
      result = shapes.rect { width: 1.2, height: 2.2, cx: 1, cy: 4 }
      expect( result.shape.rect.x ).to.equal 0.4
      expect( result.shape.rect.y ).to.equal 2.9
      expect( result.shape.rect.width ).to.equal 1.2
      expect( result.shape.rect.height ).to.equal 2.2
    it 'should be able to make an obround', ->
      res = shapes.rect { cx: 0, cy: 0, width: 3.4, height: 2.2, obround: true }
      expect( res.shape.rect.rx ).to.equal 1.1
      expect( res.shape.rect.ry ).to.equal 1.1
    it 'should throw an error for missing parameters', ->
      expect( -> shapes.rect { height: 2.2, cx: 1, cy: 4 } )
        .to.throw /requires width/
      expect( -> shapes.rect { width: 1.2, cx: 1, cy: 4 } )
        .to.throw /requires height/
      expect( -> shapes.rect { width: 1.2, height: 2.2, cy: 4 } )
        .to.throw /requires x center/
      expect( -> shapes.rect { width: 1.2, height: 2.2, cx: 1} )
        .to.throw /requires y center/
    it 'should be able to calculate the bounding box', ->
      result = shapes.rect { width: 1.2, height: 2.2, cx: 1, cy: 4 }
      expect( result.bbox ).to.eql [ 0.4, 2.9, 1.6, 5.1 ]

  describe 'for regular polygons', ->
    it 'should return the correct points with no rotation specified', ->
      result = shapes.polygon { cx: 0, cy: 0, dia: 4, vertices: 5 }
      points = ''
      step = 2 * Math.PI / 5
      for v in [0..4]
        theta = v * step
        x = 2 * Math.cos theta
        y = 2 * Math.sin theta
        if Math.abs(x) < 0.000000001 then x = 0
        if Math.abs(y) < 0.000000001 then y = 0
        points += "#{x},#{y}"
        if v isnt 4 then points += ' '
      expect( result.shape.polygon.points ).to.equal points
    it 'should return the correct points with rotation specified', ->
      re = shapes.polygon { cx: 0, cy: 0, dia: 42.6, vertices: 7, degrees: 42 }
      points = ''
      start = 42 * Math.PI / 180
      step = 2 * Math.PI / 7
      for v in [0..6]
        theta = start + v * step
        points += "#{21.3 * Math.cos theta},#{21.3 * Math.sin theta}"
        if v isnt 6 then points += ' '
      expect( re.shape.polygon.points ).to.equal points
    it 'should throw errors for missing paramters', ->
      expect( -> shapes.polygon { cx: 0, cy: 0, vertices: 5 } )
        .to.throw /requires diameter/
      expect( -> shapes.polygon { cx: 0, cy: 0, dia: 4 } )
        .to.throw /requires vertices/
      expect( -> shapes.polygon { cy: 0, dia: 4, vertices: 5 } )
        .to.throw /requires x center/
      expect( -> shapes.polygon { cx: 0, dia: 4, vertices: 5 } )
        .to.throw /requires y center/
    it 'should calculate the bounding box', ->
      result = shapes.polygon { cx: 0, cy: 0, dia: 5, vertices: 4 }
      expect( result.bbox ).to.eql [ -2.5, -2.5, 2.5, 2.5 ]
      result = shapes.polygon { cx: 0, cy: 0, dia: 6, vertices: 8 }
      expect( result.bbox ).to.eql [ -3, -3, 3, 3 ]

  describe 'for vector lines', ->
    it 'should return a vector line given the proper paramters', ->
      result = shapes.vector { x1: 0, y1: 0, x2: 2, y2: 3, width: 2 }
      expect( result.shape.line.x1 ).to.equal 0
      expect( result.shape.line.y1 ).to.equal 0
      expect( result.shape.line.x2 ).to.equal 2
      expect( result.shape.line.y2 ).to.equal 3
      expect( result.shape.line['stroke-width'] ).to.equal 2
    it 'should throw errors for missing parameters', ->
      expect( -> shapes.vector { y1: 0, x2: 2, y2: 3, width: 2 } )
        .to.throw /requires start x/
      expect( -> shapes.vector { x1: 0, x2: 2, y2: 3, width: 2 } )
        .to.throw /requires start y/
      expect( -> shapes.vector { x1: 0, y1: 0, y2: 3, width: 2 } )
        .to.throw /requires end x/
      expect( -> shapes.vector { x1: 0, y1: 0, x2: 2, width: 2 } )
        .to.throw /requires end y/
      expect( -> shapes.vector { x1: 0, y1: 0, x2: 2, y2: 3 } )
        .to.throw /requires width/
    it 'should calculate the bounding box', ->
      result = shapes.vector { x1: 0, y1: 0, x2: 5, y2: 0, width: 2 }
      expect( result.bbox ).to.eql [ 0, -1, 5, 1 ]
      result = shapes.vector { x1: 5, y1: 0, x2: 0, y2: 0, width: 2 }
      expect( result.bbox ).to.eql [ 0, -1, 5, 1 ]
      result = shapes.vector { x1: 0, y1: 0, x2: 0, y2: 5, width: 2 }
      expect( result.bbox ).to.eql [ -1, 0, 1, 5 ]
      result = shapes.vector { x1: 0, y1: 5, x2: 0, y2: 0, width: 2 }
      expect( result.bbox ).to.eql [ -1, 0, 1, 5 ]

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
      result = shapes.outline { points: [ [0,0], [1,0], [1,1], [0,0] ] }
      expect( result.shape.polygon.points ).to.eql '0,0 1,0 1,1 0,0'
    it 'should throw an error if the paramter isnt an array or is missing', ->
      expect( -> shapes.outline {} ).to.throw /requires points array/
      expect( -> shapes.outline { points: 5 } ).to.throw /requires points array/
      expect( -> shapes.outline { points: [ [5,2] ] } )
        .to.throw /requires points array/
      expect( -> shapes.outline { points: [ [5,2], 6] } )
        .to.throw /requires points array/
    it 'should throw an error if the last point doesnt match the first', ->
      expect( -> shapes.outline { points: [ [1,0], [0,1] ] } )
        .to.throw /last point must match first point/
    it 'should calculate the bounding box', ->
      result = shapes.outline { points: [ [0,0], [1,0], [1,1], [0,0] ] }
      expect( result.bbox ).to.eql [ 0, 0, 1, 1 ]

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
