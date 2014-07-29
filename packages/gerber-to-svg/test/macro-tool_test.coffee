# tests for the aperture macro class

Macro = require '../src/macro-tool'

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

  describe 'run block method', ->
    it 'should not modify the pad if block is a comment', ->
      m = new Macro ['AMNAME']
      m.runBlock '0 some comment'
      m.shapes.should.eql []
      m.masks.should.eql []
    it 'should set a modifier but leave the pad alone', ->
      m = new Macro ['AMNAME']
      m.runBlock '$1=(1+2)x(3+4)'
      m.modifiers.$1.should.equal 21
      m.shapes.should.eql []
      m.masks.should.eql []

  describe 'primitive method', ->
    describe 'for circles', ->
      it 'should add a circle to the shapes and the bbox', ->
        m = new Macro ['AMNAME']
        m.primitive [1, 1, 5, 1, 2]
        m.shapes.should.containDeep [
          { circle: { _attr: { cx: '1', cy: '2', r: '2.5' } } }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ -1.5, -0.5, 3.5, 4.5 ]
    describe 'for vector lines', ->
      it 'should add a vector line to the shapes and bbox', ->
        m = new Macro ['AMNAME']
        m.primitive [2, 1, 5, 1, 1, 15, 1, 0]
        m.shapes.should.containDeep [
          {
            line: {
              _attr: { x1: '1', y1: '1', x2: '15', y2: '1', 'stroke-width': '5' }
            }
          }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ 1, -1.5, 15, 3.5 ]
      it 'should be able to rotate the line', ->
        m = new Macro ['AMNAME']
        m.primitive [2, 1, 5, 1, 0, 10, 0, 90]
        m.shapes.should.containDeep [
          { line: { _attr: { transform: 'rotate(90)' } } }
        ]
        m.bbox.should.eql [ -2.5, 1, 2.5, 10 ]
    describe 'for center rects', ->
      it 'should add a center rect to the shapes and bbox', ->
        m = new Macro ['AMNAME']
        m.primitive [21, 1, 4, 5, 1, 2, 0]
        m.shapes.should.containDeep [
          { rect: { _attr: { x: '-1', y: '-0.5', width: '4', height: '5' } } }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ -1, -0.5, 3, 4.5 ]
      it 'should be able to rotate the rect', ->
        m = new Macro ['AMNAME']
        m.primitive [21, 1, 5, 10, 0, 0, 270]
        m.shapes.should.containDeep [
          { rect: { _attr: { transform: 'rotate(270)' } } }
        ]
        m.bbox.should.eql [ -5, -2.5, 5, 2.5 ]
    describe 'for lower left rects', ->
      it 'should add a lower left rect to the shapes and box', ->
        m = new Macro ['AMNAME']
        m.primitive [22, 1, 6, 6, -1, -1, 0]
        m.shapes.should.containDeep [
          { rect: { _attr: { x: '-1', y: '-1', width: '6', height: '6' } } }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ -1, -1, 5, 5 ]
      it 'should be able to rotate the rect', ->
        m = new Macro ['AMNAME']
        m.primitive [22, 1, 5, 10, 0, 0, 180]
        m.shapes.should.containDeep [
          { rect: { _attr: { transform: 'rotate(180)' } } }
        ]
        m.bbox.should.eql [ -5, -10, 0, 0 ]
    describe 'for outline polygons', ->
      it 'should add an outline polygon to the shapes and bbox', ->
        m = new Macro ['AMNAME']
        m.primitive [4, 1, 4, 1,1, 2,2, 1,3, 0,2, 1,1, 0 ]
        m.shapes.should.containDeep [
          { polygon: { _attr: { points: '1,1 2,2 1,3 0,2 1,1' } } }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ 0, 1, 2, 3 ]
      it 'should be able to rotate the outline', ->
        m = new Macro ['AMNAME']
        m.primitive [ 4, 1, 4, 1,1, 2,2, 1,3, 0,2, 1,1, -90 ]
        m.shapes.should.containDeep [
          { polygon: { _attr: { transform: 'rotate(-90)' } } }
        ]
        m.bbox.should.eql [ 1, -2, 3, 0 ]
    describe 'for regular polygons', ->
      it 'should add a regular polygon to the shapes and bbox', ->
        m = new Macro ['AMNAME']
        m.primitive [5, 1, 4, 0, 0, 5, 0]
        m.shapes.should.containDeep [
          { polygon: { _attr: { points: '2.5,0 0,2.5 -2.5,0 0,-2.5' } } }
        ]
        m.masks.should.eql []
        m.bbox.should.eql [ -2.5, -2.5, 2.5, 2.5 ]
      it 'should be able to rotate the polygon if the center is 0,0', ->
        m = new Macro ['AMNAME']
        m.primitive [5, 1, 4, 0, 0, 5, 45]
        d = 2.5 / Math.sqrt 2
        Math.abs(m.bbox[0]+d).should.be.below 0.000000001
        Math.abs(m.bbox[1]+d).should.be.below 0.000000001
        Math.abs(m.bbox[2]-d).should.be.below 0.000000001
        Math.abs(m.bbox[3]-d).should.be.below 0.000000001
      it 'should throw an error if rotation is given when center is not 0,0', ->
        m = new Macro ['AMNAME']
        (-> m.primitive [5, 1, 4, 1, 1, 5, 45]).should.throw /must be 0,0/
    describe 'for moirés', ->
      it 'should add a moiré to the shapes and bbox', ->
        m = new Macro ['AMNAME']
        m.primitive [6, 0, 0, 20, 2, 2, 3, 2, 22, 0]
        m.shapes.should.containEql {
          line: { _attr: {
                x1: '-11', y1: '0', x2: '11', y2: '0', 'stroke-width': '2'
              }
            }
          }
        m.shapes.should.containEql {
          line: { _attr: {
                x1: '0', y1: '-11', x2: '0', y2: '11', 'stroke-width': '2'
              }
            }
          }
        m.shapes.should.containDeep [
          { circle: { _attr: {
                cx: '0', cy: '0', r: '9', fill: 'none', 'stroke-width': '2'
              }
            }
          }
          { circle: { _attr: {
                cx: '0', cy: '0', r: '5', fill: 'none', 'stroke-width': '2'
              }
            }
          }
          { circle: { _attr: { cx: '0', cy: '0', r: '1', 'stroke-width': '0' } } }
        ]
        m.bbox.should.eql [ -11, -11, 11, 11 ]
      it 'should rotate the crosshairs if center is 0,0', ->
        m = new Macro ['AMNAME']
        m.primitive [6, 0, 0, 20, 2, 2, 3, 2, 22, 45]
        m.shapes.should.containDeep [
          { line: { _attr: { transform: 'rotate(45)' } } }
          { line: { _attr: { transform: 'rotate(45)' } } }
        ]
      it 'should throw an error if rotation given when center is not 0,0', ->
        m = new Macro ['AMNAME']
        (-> m.primitive [6, 1, 1, 20, 2, 2, 3, 2, 22, 45])
          .should.throw /must be 0,0/
    describe 'for thermals', ->
      it 'should add a thermal to the shapes, mask, and bbox', ->
        m = new Macro ['AMNAME']
        m.primitive [ 7, 0, 0, 10, 8, 2, 0 ]
        m.masks.should.containDeep [{
          mask: [
            { circle: { _attr: { cx: '0', cy: '0', r: '5', fill: '#fff' } } }
            { rect: { _attr: {
                  x: '-5', y: '-1', width: '10', height: '2', fill: '#000'
                }
              }
            }
            { rect: { _attr: {
                  x: '-1', y: '-5', width: '2', height: '10', fill: '#000'
                }
              }
            }
          ]
        }]
        m.shapes.should.containDeep [{
          circle: {
            _attr: {
              cx: '0', cy: '0', r: '4.5', fill: 'none', 'stroke-width': '1'
            }
          }
        }]
      it 'should rotate the cutout if center is 0,0', ->
        m = new Macro ['AMNAME']
        m.primitive [ 7, 0, 0, 10, 8, 2, 30 ]
        m.masks.should.containDeep [
          {
            mask: [
              { rect: { _attr: { transform: 'rotate(30)' } } }
              { rect: { _attr: { transform: 'rotate(30)' } } }
            ]
          }
        ]
      it 'should throw an error if rotation given when center is not 0,0', ->
        m = new Macro ['AMNAME']
        (-> m.primitive [ 7, 1, 1, 10, 8, 2, 1 ]).should.throw /must be 0,0/
    describe 'adding more than one shape', ->
      it 'should be able to have a few primitives involved', ->
        m = new Macro ['AMNAME']
        # add a circle
        m.primitive [ 1, 1, 10, 0, 0 ]
        # add another circle
        m.primitive [ 1, 1, 10, 2, 2 ]
        # add a rectangle
        m.primitive [ 21, 1, 5, 5, -5, 0 ]
        m.shapes.length.should.equal 3
    describe 'exposure', ->
      it 'should add a mask to only existing shape', ->
        m = new Macro ['AMNAME']
        m.primitive [ 1, 1, 10, 0, 0]
        # cut out a smaller circle
        m.primitive [ 1, 0, 5, 0, 0]
        m.masks.should.containDeep [
          { mask: [ { rect: { _attr: {
                    x: '-5', y: '-5', width: '10', height: '10', fill: '#fff'
                  }
                }
              }
              { circle: { _attr: { cx: '0', cy: '0', r: '2.5', fill: '#000' }}}
            ]
          }
        ]
        # get mask id
        for obj in m.masks[0].mask
          for k, v of obj
            if k is '_attr' then maskId = v.id
        # check that shape was masked
        m.shapes.should.containDeep [
          { circle: { _attr: { mask: "url(##{maskId})" } } }
        ]
      it 'should group up previous shapes if theres several and mask them', ->
        # add a few circles
        m = new Macro ['AMNAME']
        m.primitive [ 1, 1, 10, 0, 0 ]
        m.primitive [ 1, 1, 9, 5, 0 ]
        # cut out a smaller circle
        m.primitive [ 1, 0, 5, 5, 0 ]
        # mask should use the bounding box
        m.masks.length.should.equal 1
        m.masks[0].mask.should.containDeep [
          { rect: { _attr:
              { x: '-5', y: '-5', width: '14.5', height: '10', fill: '#fff' }
            }
          }
          { circle: { _attr: { cx: '5', cy: '0', r: '2.5', fill: '#000' } } }
        ]
        for obj in m.masks[0].mask
          for k, v of obj
            if k is '_attr' then maskId = v.id
        # shapes should be a single group
        m.shapes.length.should.equal 1
        m.shapes[0].g.should.containDeep [
          { _attr: { mask: "url(##{maskId})" } }
          { circle: { _attr: { r: '5' } } }
          { circle: { _attr: { r: '4.5'} } }
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
