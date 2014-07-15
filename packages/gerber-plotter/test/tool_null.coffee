Tool = require '../src/tool'

describe 'tool', ->

  VALIDCIRCLE = null
  beforeEach ->
    VALIDCIRCLE = {
      code: '10'
      shape: 'C'
      dia: '0.5'
    }
  describe 'parameters', ->
    it 'should take parameters as an object', ->
      t = new Tool VALIDCIRCLE
      t.code.should.equal 10
      t.shape.should.equal 'circle'
      t.dia.should.equal 0.5
    it 'should not accept invalid parameter names', ->
      invalid = VALIDCIRCLE
      invalid.foo = 'bar'
      (-> t = new Tool invalid).should.throw /invalid parameter/
    it 'should require a code greater than ten', ->
      t = new Tool VALIDCIRCLE
      t.code.should.equal 10
      invalid = VALIDCIRCLE
      invalid.code = '9'
      (-> t = new Tool invalid).should.throw /invalid code/
    it 'should require valid shape', ->
      invalid = VALIDCIRCLE
      invalid.shape = 'F'
      (-> t = new Tool invalid).should.throw /invalid shape/
    it 'can take a holeX and holeY', ->
      valid = VALIDCIRCLE
      valid.holeX = '0.5'
      valid.holeY = '0.6'
      t = new Tool valid
      t.holeX.should.equal 0.5
      t.holeY.should.equal 0.6

    describe 'for circles', ->
      it 'should parse parameters passed as strings', ->
        t = new Tool VALIDCIRCLE
        t.code.should.equal 10
        t.shape.should.equal 'circle'
        t.dia.should.equal 0.5

      it 'should require a diameter', ->
        invalid = VALIDCIRCLE
        invalid.dia = null
        (-> t = new Tool invalid).should.throw /diameter required/

      it 'cant take a width', ->
        invalid = VALIDCIRCLE
        invalid.width = 3
        (-> t = new Tool invalid).should.throw /invalid circle/
      it 'cant take height', ->
        invalid = VALIDCIRCLE
        invalid.height = 3
        (-> t = new Tool invalid).should.throw /invalid circle/
      it 'cant take rotation', ->
        invalid = VALIDCIRCLE
        invalid.rotation = 3
        (-> t = new Tool invalid).should.throw /invalid circle/
      it 'cant take points', ->
        invalid = VALIDCIRCLE
        invalid.points = 3
        (-> t = new Tool invalid).should.throw /invalid circle/

    VALIDRECT = null
    beforeEach ->
      VALIDRECT = {
        code: '10'
        shape: 'R'
        width: '0.5'
        height: '0.6'
      }
    describe 'for rectangles and obrounds', ->
      it 'should parse parameters passed as strings', ->
        t = new Tool VALIDRECT
        t.code.should.equal 10
        t.shape.should.equal 'rect'
        t.width.should.equal 0.5
        t.height.should.equal 0.6
      it 'should require a width', ->
        invalid = VALIDRECT
        invalid.width = null
        (-> t = new Tool invalid).should.throw /width required/
        invalid.shape = 'O'
        (-> t = new Tool invalid).should.throw /width required/
      it 'should require a height', ->
        invalid = VALIDRECT
        invalid.height = null
        (-> t = new Tool invalid).should.throw /height required/
        invalid.shape = 'O'
        (-> t = new Tool invalid).should.throw /height required/
      it 'cant take rotation', ->
        invalid = VALIDRECT
        invalid.rotation = 3
        (-> t = new Tool invalid).should.throw /invalid rect\/obround/
        invalid.shape = 'O'
        (-> t = new Tool invalid).should.throw /invalid rect\/obround/
      it 'cant take points', ->
        invalid = VALIDRECT
        invalid.points = 3
        (-> t = new Tool invalid).should.throw /invalid rect\/obround/
        invalid.shape = 'O'
        (-> t = new Tool invalid).should.throw /invalid rect\/obround/

    VALIDPOLY = null
    beforeEach ->
      VALIDPOLY = {
        code: '10'
        shape: 'P'
        dia: '0.5'
        points: '6'
        rotation: '-34.8'
      }
    describe 'for polygons', ->
      it 'should parse parameters passed as strings', ->
        t = new Tool VALIDPOLY
        t.code.should.equal 10
        t.shape.should.equal 'polygon'
        t.dia.should.equal 0.5
        t.points.should.equal 6
        t.rotation.should.equal -34.8
      it 'should require a diameter', ->
        invalid = VALIDPOLY
        invalid.dia = null
        (-> t = new Tool invalid).should.throw /diameter required/
      it 'should require points', ->
        invalid = VALIDPOLY
        invalid.points = null
        (-> t = new Tool invalid).should.throw /points required/
      it 'cant take a width', ->
        invalid = VALIDPOLY
        invalid.width = 3
        (-> t = new Tool invalid).should.throw /invalid polygon/
      it 'cant take height', ->
        invalid = VALIDPOLY
        invalid.height = 3
        (-> t = new Tool invalid).should.throw /invalid polygon/
