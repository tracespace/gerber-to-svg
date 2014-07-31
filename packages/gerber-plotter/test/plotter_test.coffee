# test suite for plotter class

Plotter = require '../src/plotter'

describe 'Plotter class', ->
  describe 'parameter method', ->
    p = null
    beforeEach () -> p = new Plotter()
    describe 'with aperture macros', ->
      it 'should add aperture macros to the macro list', ->
        p.parameter [ '%', 'AMUNIQUENAME', '1,1,1.5,0,0', '%' ]
        p.macros.UNIQUENAME.name.should.eql 'UNIQUENAME'
      it 'should throw an error if the command block has more than the AM', ->
        p.parameter [ '%', 'AMUNIQUENAME', '1,1,1.5,0,0', 'MOIN', '%' ]
        (-> p.macros.UNIQUENAME.run('D10')).should.throw /unrecognized tool/
    describe 'with aperture definitions', ->
      it 'should add the pad shapes to the defs list', ->
        p.defs.length.should.equal 0
        p.parameter [ '%', 'ADD10C,1.1', '%' ]
        p.defs[0].should.containDeep { circle: {} }
      it 'should set the tools flash object to a use object', ->
        p.parameter [ '%', 'ADD10C,1.1', '%' ]
        p.tools.D10.flash.should.containDeep { use: { _attr: { } } }
      it 'should set the tools stroke object to the stroke properties', ->
        p.parameter [ '%', 'ADD10C,1.1', '%' ]
        p.tools.D10.stroke.should.containDeep {
          'stroke-width': '1.1'
          'stroke-linecap': 'round'
          'stroke-linejoin': 'round'
        }
      it 'should throw an error if duplicate tools are added', ->
        (-> p.parameter [ '%', 'ADD10C,1.1', 'ADD10R,1.1X1.1', '%' ])
          .should.throw /duplicate tool/

      describe 'using standard apertures', ->
        it 'should add standard circles to the tools list', ->
          (p.tools.D10?).should.be.false
          p.parameter [ '%', 'ADD10C,1.2', '%' ]
          (p.tools.D10?).should.be.true
          p.defs.should.containDeep [ { circle: { _attr: { r: '0.6' } } } ]
          (p.tools.D11?).should.be.false
          p.parameter [ '%', 'ADD11C,1.4X0.5', '%' ]
          (p.tools.D11?).should.be.true
          p.defs.should.containDeep [
            { mask: [ { circle: { _attr: { r: '0.25' } } } ] }
            { circle: { _attr: { r: '0.7' } } }
          ]
          (p.tools.D12?).should.be.false
          p.parameter [ '%', 'ADD12C,1.6X0.5X0.5', '%' ]
          (p.tools.D12?).should.be.true
          p.defs.should.containDeep [
            { mask: [ { rect: {} }, { rect: {} } ] }
            { circle: { _attr: { r: '0.8' } } }
          ]
        it 'should add standard rectangles to the tools list', ->
          (p.tools.D10?).should.be.false
          (p.tools.D11?).should.be.false
          (p.tools.D12?).should.be.false
          p.parameter [
            '%'
            'ADD10R,1X1'
            'ADD11R,1.1X1.1X0.5'
            'ADD12R,1.2X1.2X0.5X0.5'
            '%'
          ]
          (p.tools.D10?).should.be.true
          (p.tools.D11?).should.be.true
          (p.tools.D12?).should.be.true
          p.defs.should.containDeep [
            { rect: { _attr: { width: '1' } } }
            { mask: [ { circle: { _attr: { r: '0.25' } } } ] }
            { rect: { _attr: { width: '1.1' } } }
            { mask: [ { rect: {} }, { rect: {} } ] }
            { rect: { _attr: { width: '1.2' } } }
          ]

        it 'should add standard obrounds to the tools list', ->
          (p.tools.D10?).should.be.false
          (p.tools.D11?).should.be.false
          (p.tools.D12?).should.be.false
          p.parameter [
            '%'
            'ADD10O,1X1'
            'ADD11O,1.2X1.2X0.5'
            'ADD12O,1.4X1.4X0.5X0.5'
            '%'
          ]
          (p.tools.D10?).should.be.true
          (p.tools.D11?).should.be.true
          (p.tools.D12?).should.be.true
          p.defs.should.containDeep [
            { rect: { _attr: { width: '1', rx: '0.5' } } }
            { mask: [ { circle: { _attr: { r: '0.25' } } } ] }
            { rect: { _attr: { width: '1.2', rx: '0.6' } } }
            { mask: [ { rect: {} }, { rect: {} } ] }
            { rect: { _attr: { width: '1.4', rx:'0.7' } } }
          ]
        it 'should add standard polygons to the tools list', ->
          (p.tools.D10?).should.be.false
          (p.tools.D11?).should.be.false
          (p.tools.D12?).should.be.false
          (p.tools.D13?).should.be.false
          p.parameter [
            '%'
            'ADD10P,5X3'
            'ADD11P,5X4X45'
            'ADD12P,5X4X0X0.6'
            'ADD13P,5X4X0X0.6X0.6'
            '%'
          ]
          (p.tools.D10?).should.be.true
          (p.tools.D11?).should.be.true
          (p.tools.D12?).should.be.true
          (p.tools.D13?).should.be.true
          p.defs.should.containDeep [
            { polygon: {} }
            { polygon: {} }
            { mask: [ { circle: { _attr: { r: '0.3' } } } ] }
            { polygon: {} }
            { mask: [ { rect: {} }, { rect: {} } ] }
            { polygon: {} }
          ]

      describe 'using aperture macros', ->
        it 'should run the aperture macro', ->
          p.parameter [ '%', 'AMCIRC', '1,1,$1,0,0', '%' ]
          p.parameter [ '%', 'ADD10CIRC,1.6', '%' ]
          (p.tools.D10?).should.be.true
          p.defs.should.containDeep [ { circle: { _attr: { r: '0.8' } } } ]
