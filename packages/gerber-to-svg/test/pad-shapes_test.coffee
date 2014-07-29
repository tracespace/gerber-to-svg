# unit tests for shape objects

shapes = require '../src/pad-shapes'

describe 'shape functions', ->
  describe 'for circles', ->
    it 'should create circle with the paramters passed in', ->
      result = shapes.circle {dia: 10, cx: 4, cy: 3}
      result.shape.circle._attr.r.should.equal '5'
      result.shape.circle._attr.cx.should.equal '4'
      result.shape.circle._attr.cy.should.equal '3'
    it 'should throw an error if parameters are missing', ->
      (-> shapes.circle {cx: 4, cy: 3}).should.throw /requires diameter/
      (-> shapes.circle {dia: 10, cy: 3}).should.throw /requires x center/
      (-> shapes.circle {dia: 10, cx: 4}).should.throw /requires y center/
    it 'should calculate the bounding box', ->
      result = shapes.circle { dia: 8, cx: 12, cy: 6 }
      result.bbox.should.eql [ 8, 2, 16, 10 ]

  describe 'for rectangles', ->
    it 'should create a rectangle with the parameters passed in', ->
      result = shapes.rect { width: 1.2, height: 2.2, cx: 1, cy: 4 }
      result.shape.rect._attr.x.should.equal '0.4'
      result.shape.rect._attr.y.should.equal '2.9'
      result.shape.rect._attr.width.should.equal '1.2'
      result.shape.rect._attr.height.should.equal '2.2'
    it 'should be able to make an obround', ->
      res = shapes.rect { cx: 0, cy: 0, width: 3.4, height: 2.2, obround: true }
      res.shape.rect._attr.rx.should.equal '1.1'
      res.shape.rect._attr.ry.should.equal '1.1'
    it 'should throw an error for missing parameters', ->
      (-> shapes.rect { height: 2.2, cx: 1, cy: 4 })
        .should.throw /requires width/
      (-> shapes.rect { width: 1.2, cx: 1, cy: 4 })
        .should.throw /requires height/
      (-> shapes.rect { width: 1.2, height: 2.2, cy: 4 })
        .should.throw /requires x center/
      (-> shapes.rect { width: 1.2, height: 2.2, cx: 1})
        .should.throw /requires y center/
    it 'should be able to calculate the bounding box', ->
      result = shapes.rect { width: 1.2, height: 2.2, cx: 1, cy: 4 }
      result.bbox.should.eql [ 0.4, 2.9, 1.6, 5.1 ]

  describe 'for regular polygons', ->
    it 'should return the correct points with no rotation specified', ->
      result = shapes.polygon { cx: 0, cy: 0, dia: 4, verticies: 5 }
      points = ''
      step = 2*Math.PI/5
      for v in [0..4]
        theta = v*step
        x = 2*Math.cos theta
        y = 2*Math.sin theta
        if Math.abs(x) < 0.000000001 then x = 0
        if Math.abs(y) < 0.000000001 then y = 0
        points += "#{x},#{y}"
        if v isnt 4 then points += ' '
      result.shape.polygon._attr.points.should.equal points
    it 'should return the correct points with rotation specified', ->
      re = shapes.polygon { cx: 0, cy: 0, dia: 42.6, verticies: 7, degrees: 42 }
      points = ''
      start = 42 * Math.PI / 180
      step = 2*Math.PI/7
      for v in [0..6]
        theta = start+v*step
        points += "#{21.3*Math.cos theta},#{21.3*Math.sin theta}"
        if v isnt 6 then points += ' '
      re.shape.polygon._attr.points.should.equal points
    it 'should throw errors for missing paramters', ->
      (-> shapes.polygon { cx: 0, cy: 0, verticies: 5 })
        .should.throw /requires diameter/
      (-> shapes.polygon { cx: 0, cy: 0, dia: 4})
        .should.throw /requires verticies/
      (-> shapes.polygon { cy: 0, dia: 4, verticies: 5 })
        .should.throw /requires x center/
      (-> shapes.polygon { cx: 0, dia: 4, verticies: 5 })
        .should.throw /requires y center/
    it 'should calculate the bounding box', ->
      result = shapes.polygon {cx: 0, cy: 0, dia: 5, verticies: 4}
      result.bbox.should.eql [ -2.5, -2.5, 2.5, 2.5 ]
      result = shapes.polygon {cx: 0, cy: 0, dia: 6, verticies: 8}
      result.bbox.should.eql [ -3, -3, 3, 3 ]

  describe 'for vector lines', ->
    it 'should return a vector line given the proper paramters', ->
      result = shapes.vector { x1: 0, y1: 0, x2: 2, y2: 3, width: 2 }
      result.shape.line._attr.x1.should.equal '0'
      result.shape.line._attr.y1.should.equal '0'
      result.shape.line._attr.x2.should.equal '2'
      result.shape.line._attr.y2.should.equal '3'
      result.shape.line._attr['stroke-width'].should.equal '2'
    it 'should throw errors for missing parameters', ->
      (-> shapes.vector { y1: 0, x2: 2, y2: 3, width: 2 })
        .should.throw /requires start x/
      (-> shapes.vector { x1: 0, x2: 2, y2: 3, width: 2 })
        .should.throw /requires start y/
      (-> shapes.vector { x1: 0, y1: 0, y2: 3, width: 2 })
        .should.throw /requires end x/
      (-> shapes.vector { x1: 0, y1: 0, x2: 2, width: 2 })
        .should.throw /requires end y/
      (-> shapes.vector { x1: 0, y1: 0, x2: 2, y2: 3 })
        .should.throw /requires width/
    it 'should calculate the bounding box', ->
      result = shapes.vector { x1: 0, y1: 0, x2: 5, y2: 0, width: 2 }
      result.bbox.should.eql [ 0, -1, 5, 1 ]
      result = shapes.vector { x1: 5, y1: 0, x2: 0, y2: 0, width: 2 }
      result.bbox.should.eql [ 0, -1, 5, 1 ]
      result = shapes.vector { x1: 0, y1: 0, x2: 0, y2: 5, width: 2 }
      result.bbox.should.eql [ -1, 0, 1, 5 ]
      result = shapes.vector { x1: 0, y1: 5, x2: 0, y2: 0, width: 2 }
      result.bbox.should.eql [ -1, 0, 1, 5 ]

  describe 'for lower left rectangles', ->
    it 'should return a rectangle given the proper parameters', ->
      result = shapes.lowerLeftRect { x: 1, y: 3, width: 10, height: 5 }
      result.shape.rect._attr.x.should.equal '1'
      result.shape.rect._attr.y.should.equal '3'
      result.shape.rect._attr.width.should.equal '10'
      result.shape.rect._attr.height.should.equal '5'
    it 'should throw errors for missing parameters', ->
      (-> shapes.lowerLeftRect { y: 3, width: 10, height: 5 })
        .should.throw /requires x/
      (-> shapes.lowerLeftRect { x: 1, width: 10, height: 5 })
        .should.throw /requires y/
      (-> shapes.lowerLeftRect { x: 1, y: 3, height: 5 })
        .should.throw /requires width/
      (-> shapes.lowerLeftRect { x: 1, y: 3, width: 10 })
        .should.throw /requires height/
    it 'should calculate the bounding box', ->
      result = shapes.lowerLeftRect { x: 1, y: 3, width: 10, height: 5 }
      result.bbox.should.eql [ 1, 3, 11, 8 ]

  describe 'for outline polygons', ->
    it 'should return a polygon given proper parameters', ->
      result = shapes.outline { points: [ [0,0], [1,0], [1,1], [0,0] ] }
      result.shape.polygon._attr.points.should.eql '0,0 1,0 1,1 0,0'
    it 'should throw an error if the paramter isnt an array or is missing', ->
      (-> shapes.outline {}).should.throw /requires points array/
      (-> shapes.outline { points: 5 }).should.throw /requires points array/
      (-> shapes.outline { points: [ [5,2] ] })
        .should.throw /requires points array/
      (-> shapes.outline { points: [ [5,2], 6] })
        .should.throw /requires points array/
    it 'should throw an error if the last point doesnt match the first', ->
      (-> shapes.outline { points: [ [1,0], [0,1] ] })
        .should.throw /last point must match first point/
    it 'should calculate the bounding box', ->
      result = shapes.outline { points: [ [0,0], [1,0], [1,1], [0,0] ] }
      result.bbox.should.eql [ 0, 0, 1, 1 ]

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
      result.shape.should.containDeep [
        {
          line: {
            _attr: { x1: '-6', y1: '0', x2: '6', y2: '0', 'stroke-width': '0.5'}
          }
        }
        {
          line: {
            _attr: { x1: '0', y1: '-6', x2: '0', y2: '6', 'stroke-width': '0.5'}
          }
        }
        {
          circle: {
            _attr: {
              cx: '0', cy: '0', r: '7', 'stroke-width': '2', fill: 'none'
            }
          }
        }
        {
          circle: {
            _attr: {
              cx: '0', cy: '0', r: '3', 'stroke-width': '2', fill: 'none'
            }
          }
        }
      ]
    it 'should throw errors for missing parameters', ->
      (-> shapes.moire {
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).should.throw /requires x center/
      (-> shapes.moire {
        cx: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).should.throw /requires y center/
      (-> shapes.moire {
        cx: 0
        cy: 0
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).should.throw /requires outer diameter/
      (-> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringGap: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).should.throw /requires ring thickness/
      (-> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        maxRings: 2
        crossLength: 12
        crossThx: 0.5
      }).should.throw /requires ring gap/
      (-> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        crossLength: 12
        crossThx: 0.5
      }).should.throw /requires max rings/
      (-> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossThx: 0.5
      }).should.throw /requires crosshair length/
      (-> shapes.moire {
        cx: 0
        cy: 0
        outerDia: 10
        ringThx: 2
        ringGap: 2
        maxRings: 2
        crossLength: 12
      }).should.throw /requires crosshair thickness/
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
      result.bbox.should.eql [ -6, -6, 6, 6 ]
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
      result.bbox.should.eql [ -5, -5, 5, 5 ]

  describe 'for thermals', ->
    it 'should return a thermal given proper parameters', ->
      result = shapes.thermal {cx: 0, cy: 0, outerDia: 10, innerDia: 8, gap: 3}
      for obj in result.shape
        for key, val of obj
          if key is 'mask'
            for o in val
              for k, v of o
                if k is '_attr' then maskId = v.id
      result.shape.should.containDeep [
        {
          mask: [ {
              circle: { _attr: { cx: '0', cy: '0', r: '5', fill: '#fff' } }
            }
            {
              rect: {
                _attr: {x:'-5', y:'-1.5', width:'10', height:'3', fill:'#000'}
              }
            }
            {
              rect: {
                _attr: {x:'-1.5', y:'-5', width:'3', height:'10', fill:'#000'}
              }
            }
          ]
        }
        {
          circle: {
            _attr: {
              cx: '0'
              cy: '0'
              r: '4.5'
              fill: 'none'
              'stroke-width': '1'
              mask: 'url(#' + maskId + ')'
            }
          }
        }
      ]
    it 'should throw errors if parameters are missing', ->
      (-> shapes.thermal { cy: 0, outerDia: 10, innerDia: 8, gap: 3 })
        .should.throw /requires x center/
      (-> shapes.thermal { cx: 0, outerDia: 10, innerDia: 8, gap: 3 })
        .should.throw /requires y center/
      (-> shapes.thermal { cx: 0, cy: 0, innerDia: 8, gap: 3 })
        .should.throw /requires outer diameter/
      (-> shapes.thermal { cx: 0, cy: 0, outerDia: 10, gap: 3 })
        .should.throw /requires inner diameter/
      (-> shapes.thermal { cx: 0, cy: 0, outerDia: 10, innerDia: 8 })
        .should.throw /requires gap/
    it 'should calculate the bounding box', ->
      r = shapes.thermal { cx: 0, cy: 0, outerDia: 10, innerDia: 8, gap: 3 }
      r.bbox.should.eql [ -5, -5, 5, 5 ]
