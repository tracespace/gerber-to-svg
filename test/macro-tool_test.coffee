# tests for the aperture macro class

Macro = require '../src/macro-tool'
# coordinate scaling factor
factor = require('../src/svg-coord').factor
# test macro
m = null

describe 'tool macro class', ->
  it 'should identify itself', ->
    m = new Macro ['AMMACRONAME']
    m.name.should.equal 'MACRONAME'
  it 'should save the blocks for processing', ->
    m = new Macro ['AMNAME', '0 block 0', '0 block 1', '0 block 2']
    m.blocks[0].should.equal '0 block 0'
    m.blocks[1].should.equal '0 block 1'
    m.blocks[2].should.equal '0 block 2'

  describe 'run method', ->
    it 'should set modifiers that are passed in', ->
      MODIFIERS = ['1', '1.5', '0', '-0.76']
      m = new Macro ['MACRONAME']
      result = m.run '10', MODIFIERS
      m.modifiers.$1.should.equal '1'
      m.modifiers.$2.should.equal '1.5'
      m.modifiers.$3.should.equal '0'
      m.modifiers.$4.should.equal '-0.76'
    describe 'creating a tool', ->
      it 'should return an object with an array with one non-mask item', ->
        m = new Macro ['AMNAME', '1,1,8,0,0', '1,1,4,5,5']
        result = m.run 'D10'
        items = 0
        if k isnt 'mask' for k of p then items++ for p in result.pad
        items.should.equal 1
      it 'should be able to create multiple tools from the same macro', ->
        m = new Macro ['AMNAME', '1,1,$1,0,0']
        result = m.run 'D10', [ '1' ]
        result.pad.length.should.equal 1
        result.pad[0].circle.r.should.equal 0.5 * factor
        result = m.run 'D10', [ '2' ]
        result.pad.length.should.equal 1
        result.pad[0].circle.r.should.equal 1 * factor

      it 'should return a group if there were several primitives', ->
        m = new Macro ['AMNAME', '1,1,8,0,0', '1,1,4,5,5']
        result = m.run 'D10'
        result.pad[0].should.containDeep {
          g: { 
            _: [
              { circle: { cx: 0, cy: 0 } }
              { circle: { cx: 5*factor, cy: 5*factor } }
            ]
          }
        }
      it 'should return the primitive if it is the only one', ->
        m = new Macro ['AMNAME', '1,1,8,0,0']
        result = m.run 'D10'
        result.pad[0].should.containDeep { circle: { cx: 0, cy: 0 } }
      it 'should set the id and return id', ->
        m = new Macro ['AMNAME', '1,1,8,0,0']
        result = m.run 'D10'
        result.padId.should.match /D10/
        result.padId.should.eql result.pad[0].circle.id
      it 'should return the bounding box', ->
        m = new Macro ['AMNAME', '1,1,8,0,0']
        result = m.run 'D10'
        result.bbox.should.eql [ -4*factor, -4*factor, 4*factor, 4*factor ]
      it 'should return any masks in the pad array', ->
        m = new Macro ['AMNAME', '1,1,8,0,0', '1,0,2,0,0' ]
        result = m.run 'D10'
        result.pad.length.should.equal 2
        result.pad.should.containDeep [ { mask: { _: [] } }, { circle: {} } ]
      it 'should return a false flag for being traceable', ->
        m = new Macro ['AMNAME', '1,1,8,0,0', '1,0,2,0,0' ]
        result = m.run 'D10'
        result.trace.should.be.false

  describe 'run block method', ->
    beforeEach -> m = new Macro ['AMNAME']
    it 'should not modify the pad if block is a comment', ->
      m.runBlock '0 some comment'
      m.shapes.should.eql []
      m.masks.should.eql []
    it 'should set a modifier but leave the pad alone', ->
      m.runBlock '$1=(1+2)x(3+4)'
      m.modifiers.$1.should.equal 21
      m.shapes.should.eql []
      m.masks.should.eql []
    describe 'primitive blocks', ->
      it 'should split up a primitive block and pass it to @primitive', ->
        m.runBlock '1,1,10,0,0'
        m.shapes.should.containDeep [{ circle: { cx: 0, cy: 0, r: 5*factor } }]
      it 'should parse modifiers properly', ->
        m.modifiers = { $1: '1', $2: '10', $3: '4', $4: '4' }
        m.runBlock '1,$1,$2,$3-$4,$4-$3'
        m.shapes.should.containDeep [{ circle: { cx: 0, cy: 0, r: 5*factor } }]

  describe 'primitive method', ->
    beforeEach -> m = new Macro ['AMNAME']
    describe 'for circles', ->
      it 'should add a circle to the shapes and the bbox', ->
        m.primitive [1, 1, 5, 1, 2]
        m.shapes.should.containDeep [ 
          { circle: { cx: 1*factor, cy: 2*factor, r: 2.5*factor } } 
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ -1.5*factor, -0.5*factor, 3.5*factor, 4.5*factor ]
    describe 'for vector lines', ->
      it 'should add a vector line to the shapes and bbox', ->
        m.primitive [2, 1, 5, 1, 1, 15, 1, 0]
        m.shapes.should.containDeep [
          { 
            line: { 
              x1: 1*factor
              y1: 1*factor
              x2: 15*factor
              y2: 1*factor
              'stroke-width': 5*factor
            }
          }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ 1*factor, -1.5*factor, 15*factor, 3.5*factor ]
      it 'should be able to rotate the line', ->
        m.primitive [2, 1, 5, 1, 0, 10, 0, 90]
        m.shapes.should.containDeep [ { line: { transform: 'rotate(90)' } } ]
        m.bbox.should.eql [ -2.5*factor, 1*factor, 2.5*factor, 10*factor ]
    describe 'for center rects', ->
      it 'should add a center rect to the shapes and bbox', ->
        m.primitive [21, 1, 4, 5, 1, 2, 0]
        m.shapes.should.containDeep [
          { rect:{ x:-1*factor, y:-.5*factor, width:4*factor, height:5*factor }}
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ -1*factor, -.5*factor, 3*factor, 4.5*factor ]
      it 'should be able to rotate the rect', ->
        m.primitive [21, 1, 5, 10, 0, 0, 270]
        m.shapes.should.containDeep [ { rect: { transform: 'rotate(270)' } } ]
        m.bbox.should.eql [ -5*factor, -2.5*factor, 5*factor, 2.5*factor ]
    describe 'for lower left rects', ->
      it 'should add a lower left rect to the shapes and box', ->
        m.primitive [22, 1, 6, 6, -1, -1, 0]
        m.shapes.should.containDeep [
          { rect:{ x:-1*factor, y:-1*factor, width:6*factor, height:6*factor } }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ -1*factor, -1*factor, 5*factor, 5*factor ]
      it 'should be able to rotate the rect', ->
        m.primitive [22, 1, 5, 10, 0, 0, 180]
        m.shapes.should.containDeep [ { rect: { transform: 'rotate(180)' } } ]
        m.bbox.should.eql [ -5*factor, -10*factor, 0, 0 ]
    describe 'for outline polygons', ->
      it 'should add an outline polygon to the shapes and bbox', ->
        m.primitive [4, 1, 4, 1,1, 2,2, 1,3, 0,2, 1,1, 0 ]
        m.shapes.should.containDeep [
          {
            polygon: {
              points: "
                #{1*factor},#{1*factor}
                #{2*factor},#{2*factor}
                #{1*factor},#{3*factor}
                #{0*factor},#{2*factor}
                #{1*factor},#{1*factor}
              "
            }
          }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ 0, 1*factor, 2*factor, 3*factor ]
      it 'should be able to rotate the outline', ->
        m.primitive [ 4, 1, 4, 1,1, 2,2, 1,3, 0,2, 1,1, -90 ]
        m.shapes.should.containDeep [{ polygon: { transform: 'rotate(-90)' } }]
        m.bbox.should.eql [ 1*factor, -2*factor, 3*factor, 0 ]
    describe 'for regular polygons', ->
      it 'should add a regular polygon to the shapes and bbox', ->
        m.primitive [5, 1, 4, 0, 0, 5, 0]
        m.shapes.should.containDeep [
          { polygon: { points: "
                #{2.5*factor},0
                0,#{2.5*factor}
                #{-2.5*factor},0
                0,#{-2.5*factor}
              "
            }
          }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ -2.5*factor, -2.5*factor, 2.5*factor, 2.5*factor ]
      it 'should be able to rotate the polygon if the center is 0,0', ->
        m.primitive [5, 1, 4, 0, 0, 5, 45]
        d = 2.5*factor / Math.sqrt 2
        Math.abs(m.bbox[0]+d).should.be.below 0.000000001
        Math.abs(m.bbox[1]+d).should.be.below 0.000000001
        Math.abs(m.bbox[2]-d).should.be.below 0.000000001
        Math.abs(m.bbox[3]-d).should.be.below 0.000000001
      it 'should throw an error if rotation is given when center is not 0,0', ->
        (-> m.primitive [5, 1, 4, 1, 1, 5, 45]).should.throw /must be 0,0/
    describe 'for moirés', ->
      it 'should add a moiré to the shapes and bbox', ->
        m.primitive [6, 0, 0, 20, 2, 2, 3, 2, 22, 0]
        m.shapes.should.containDeep [
          { line: {
              x1: -11*factor
              y1: 0
              x2: 11*factor
              y2: 0
              'stroke-width': 2*factor 
            }
          }
        ]
        m.shapes.should.containDeep [
          { line: { 
              x1: 0
              y1: -11*factor
              x2: 0
              y2: 11*factor
              'stroke-width': 2*factor
            }
          }
        ]
        m.shapes.should.containDeep [
          { circle: { 
              cx: 0, cy: 0, r: 9*factor, fill: 'none', 'stroke-width': 2*factor 
            }
          }
          { circle: {
              cx: 0, cy: 0, r: 5*factor, fill: 'none', 'stroke-width': 2*factor 
            }
          }
          { circle: { cx: 0, cy: 0, r: 2*factor } }
        ]
        m.bbox.should.eql [ -11*factor, -11*factor, 11*factor, 11*factor ]
      it 'should rotate the crosshairs if center is 0,0', ->
        m.primitive [6, 0, 0, 20, 2, 2, 3, 2, 22, 45]
        m.shapes.should.containDeep [
          { line: { transform: 'rotate(45)' } }
          { line: { transform: 'rotate(45)' } }
        ]
      it 'should have no more than maxrings (arg 6)', ->
        m.primitive [6, 0, 0, 20, 1, 1, 2, 1, 22, 0]
        # shapes should have two rings and two lines
        m.shapes.length.should.equal 4
      it 'should throw an error if rotation given when center is not 0,0', ->
        (-> m.primitive [6, 1, 1, 20, 2, 2, 3, 2, 22, 45])
          .should.throw /must be 0,0/
    describe 'for thermals', ->
      it 'should add a thermal to the shapes, mask, and bbox', ->
        m.primitive [ 7, 0, 0, 10, 8, 2, 0 ]
        m.masks.should.containDeep [
          {
            mask: {
              _: [
                { circle: { cx: 0, cy: 0, r: 5*factor, fill: '#fff' } }
                { rect: {
                    x: -5*factor
                    y: -1*factor
                    width: 10*factor
                    height: 2*factor
                    fill:'#000' 
                  }
                }
                { rect: {
                    x: -1*factor
                    y: -5*factor
                    width: 2*factor
                    height: 10*factor
                    fill:'#000'
                  }
                }
              ]
            }
          }
        ]
        m.shapes.should.containDeep [
          { circle: { 
              cx: 0, cy: 0, r: 4.5*factor, fill:'none', 'stroke-width': 1*factor 
            }
          }
        ]
      it 'should rotate the cutout if center is 0,0', ->
        m.primitive [ 7, 0, 0, 10, 8, 2, 30 ]
        m.masks.should.containDeep [
          {
            mask: {
              _: [
                { rect: { transform: 'rotate(30)' } }
                { rect: { transform: 'rotate(30)' } }
              ]
            }
          }
        ]
      it 'should throw an error if rotation given when center is not 0,0', ->
        (-> m.primitive [ 7, 1, 1, 10, 8, 2, 1 ]).should.throw /must be 0,0/
    describe 'adding more than one shape', ->
      it 'should be able to have a few primitives involved', ->
        # add a circle
        m.primitive [ 1, 1, 10, 0, 0 ]
        # add another circle
        m.primitive [ 1, 1, 10, 2, 2 ]
        # add a rectangle
        m.primitive [ 21, 1, 5, 5, -5, 0 ]
        m.shapes.length.should.equal 3
    describe 'exposure', ->
      it 'should add a mask to only existing shape', ->
        m.primitive [ 1, 1, 10, 0, 0]
        # cut out a smaller circle
        m.primitive [ 1, 0, 5, 0, 0]
        m.masks.should.containDeep [
          {
            mask: {
              _: [
                { rect: { 
                    x:-5*factor
                    y:-5*factor
                    width:10*factor 
                    height:10*factor 
                    fill:'#fff'
                  }
                }
                { circle: { cx: 0, cy: 0, r: 2.5*factor, fill: '#000' } }
              ]
            }
          }
        ]
        # get mask id
        maskId = m.masks[0].mask.id
        # check that shape was masked
        m.shapes.should.containDeep [ { circle: { mask: "url(##{maskId})" } } ]
      it 'should group up previous shapes if theres several and mask them', ->
        # add a few circles
        m.primitive [ 1, 1, 10, 0, 0 ]
        m.primitive [ 1, 1, 9, 5, 0 ]
        # cut out a smaller circle
        m.primitive [ 1, 0, 5, 5, 0 ]
        # mask should use the bounding box
        m.masks.length.should.equal 1
        m.masks[0].mask._.should.containDeep [
          { rect: { 
              x: -5*factor
              y: -5*factor
              width: 14.5*factor
              height: 10*factor
              fill: '#fff'
            }
          }
          { circle: { cx: 5*factor, cy: 0, r: 2.5*factor, fill: '#000' } }
        ]
        maskId = m.masks[0].mask.id
        # shapes should be a single group
        m.shapes.length.should.equal 1
        m.shapes[0].g.should.containDeep {
          mask: "url(##{maskId})"
          _: [ { circle: { r: 5*factor } }, { circle:{ r: 4.5*factor } } ]
        }
      it 'should add several clear shapes in a row to the same mask', ->
        # add a rectangle
        m.primitive [ 21, 1, 10, 5, 0, 0, 0 ]
        # clear out two smaller circles
        m.primitive [ 1, 0, 3, 3, 0 ]
        m.primitive [ 1, 0, 2, -3, 0 ]
        m.shapes.length.should.equal 1
        m.masks.length.should.equal 1
        m.masks[0].mask._.length.should.equal 3
        m.masks[0].mask._.should.containDeep [
          { rect: { width: 10*factor } }
          { circle: { r:1.5*factor } }
          { circle: { r:1*factor } }
        ]

  describe 'getNumber method', ->
    m = new Macro ['MACRONAME']
    it 'should return a number if passed a string of a number', ->
      m.getNumber('2.4').should.equal 2.4
    it 'should return the modifier if passed a reference to a modifier', ->
      m.modifiers.$2 = 3.5
      m.getNumber('$2').should.equal 3.5
    it 'should return a number if passed a string with arithmetic', ->
      m.modifiers.$1 = 2.6
      m.getNumber('$1+5').should.equal 7.6

  describe 'arithmetic evaluate method', ->
    m = new Macro ['MACRONAME']
    it 'should obey order of operations', ->
      m.getNumber('1+2x3').should.equal 7
      m.getNumber('1-2x3').should.equal -5
      m.getNumber('1+1/2').should.equal 1.5
      m.getNumber('1-1/2').should.equal 0.5
    it 'should allow parentheses to overide order of operations', ->
      m.getNumber('(1+2)x3').should.equal 9
      m.getNumber('(1-2)x3').should.equal -3
      m.getNumber('(1+1)/2').should.equal 1
      m.getNumber('(1-1)/2').should.equal 0
