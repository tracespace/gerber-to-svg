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

  describe 'primitve method', ->
    it 'should add a circle to the shapes and the bbox', ->
      m = new Macro ['AMNAME']
      m.primitive [1, 1, 5, 1, 2]
      m.shapes.should.containDeep [
        { circle: { _attr: { cx: '1', cy: '2', r: '2.5' } } }
      ]
      m.masks.should.eql []
      m.bbox.should.eql [ -1.5, -0.5, 3.5, 4.5 ]
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
    it 'should add a center rect to the shapes and bbox', ->
      m = new Macro ['AMNAME']
      m.primitive [21, 1, 4, 5, 1, 2, 0]
      m.shapes.should.containDeep [
        { rect: { _attr: { x: '-1', y: '-0.5', width: '4', height: '5' } } }
      ]
      m.masks.should.eql []
      m.bbox.should.eql [ -1, -0.5, 3, 4.5 ]
    it 'should add a lower left rect to the shapes and box', ->
      m = new Macro ['AMNAME']
      m.primitive [22, 1, 6, 6, -1, -1, 0]
      m.shapes.should.containDeep [
        { rect: { _attr: { x: '-1', y: '-1', width: '6', height: '6' } } }
      ]
      m.masks.should.eql []
      m.bbox.should.eql [ -1, -1, 5, 5 ]
    it 'should add an outline polygon to the shapes and bbox', ->
      m = new Macro ['AMNAME']
      m.primitive [4, 1, 4, 1,1, 2,2, 1,3, 0,2, 1,1, 0 ]
      m.shapes.should.containDeep [
        { polygon: { _attr: { points: '1,1 2,2 1,3 0,2 1,1' } } }
      ]
      m.masks.should.eql []
      m.bbox.should.eql [ 0, 1, 2, 3 ]
    it 'should add a regular polygon to the shapes and bbox', ->
      m = new Macro ['AMNAME']
      m.primitive [5, 1, 4, 0, 0, 5, 0]
      m.shapes.should.containDeep [
        { polygon: { _attr: { points: '2.5,0 0,2.5 -2.5,0 0,-2.5' } } }
      ]
      m.masks.should.eql []
      m.bbox.should.eql [ -2.5, -2.5, 2.5, 2.5 ]
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
