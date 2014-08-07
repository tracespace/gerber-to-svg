# test suite for plotter class

Plotter = require '../src/plotter'

describe 'Plotter class', ->
  describe 'parameter method', ->
    p = null
    beforeEach () -> p = new Plotter()
    describe 'with format specification', ->
      it 'should set the zero ommision mode', ->
        p.parameter [ '%', 'FSLAX34Y34', '%' ]
        p.format.zero.should.eql 'L'
        p = new Plotter()
        p.parameter [ '%', 'FSTAX34Y34', '%' ]
        p.format.zero.should.eql 'T'
      it 'should set the absolute / incremental notation mode', ->
        p.parameter [ '%', 'FSLAX34Y34', '%' ]
        p.format.notation.should.eql 'A'
        p = new Plotter()
        p.parameter [ '%', 'FSLIX34Y34', '%' ]
        p.format.notation.should.eql 'I'
      it 'should set the coordinate format', ->
        p.parameter [ '%', 'FSLAX34Y34', '%' ]
        p.format.places.should.eql [ 3, 4 ]
        p = new Plotter()
        p.parameter [ '%', 'FSLAX55Y55', '%' ]
        p.format.places.should.eql [ 5, 5 ]
      it 'should throw if information is missing or invalid', ->
        (-> p.parameter [ '%', 'FSAX34Y34', '%' ]).should.throw /invalid format/
        p = new Plotter()
        (-> p.parameter [ '%', 'FSLX34Y34', '%' ]).should.throw /invalid format/
        p = new Plotter()
        (-> p.parameter [ '%', 'FSLAX34', '%' ]).should.throw /invalid format/
        p = new Plotter()
        (-> p.parameter [ '%', 'FSLAY34', '%' ]).should.throw /invalid format/
      it 'should throw if x and y format is invalid', ->
        (-> p.parameter [ '%', 'FSLAX34Y56', '%']).should.throw /invalid format/
        p = new Plotter()
        (-> p.parameter [ '%', 'FSLAX88Y88', '%']).should.throw /invalid format/
      it 'can only be called once', ->
        p.parameter [ '%', 'FSLAX34Y34', '%' ]
        (-> p.parameter [ '%', 'FSLAX34Y34', '%' ]).should.throw /redefined/

    describe 'with setting the units', ->
      it 'should set the units to inches if given an MOIN parameter', ->
        p.parameter [ '%', 'MOIN', '%' ]
        p.units.should.eql 'in'
      it 'should set the units to millimeters if given an MOMM parameter', ->
        p.parameter [ '%', 'MOMM', '%' ]
        p.units.should.eql 'mm'
      it 'should throw an error if the units are redifined', ->
        p.parameter [ '%', 'MOMM', '%' ]
        (-> p.parameter [ '%', 'MOIN', '%' ]).should.throw /redifine units/
      it 'should throw an error if the units are wrong', ->
        (-> p.parameter [ '%', 'MOKM', '%' ]).should.throw /unrecognized units/

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
        result = p.tools.D10.flash 0, 0
        result.should.containDeep { use: { _attr: { } } }
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
          p.parameter [ '%', 'AMRECT1', '21,1,1,1,0,0,0', '%' ]
          p.parameter [ '%', 'ADD11RECT1', '%' ]
          (p.tools.D11?).should.be.true
          p.defs.should.containDeep [ { rect: { _attr: { width: '1' } } } ]

    describe 'changing layer polarity', ->
      it 'shouldnt do anything if the polarity doesnt change', ->
        p.layer.level.should.equal 0
        p.layer.type.should.eql 'g'
        p.parameter [ '%', 'LPD', '%' ]
        p.layer.level.should.equal 0
        p.layer.type.should.eql 'g'
      it 'should change to a mask if polarity switches to clear', ->
        p.parameter [ '%', 'LPC', '%' ]
        p.defs[0].mask[0]._attr.id.should.match /layer-1/
        p.group.g[0]._attr.mask.should.match /url\(#.*-layer-1\)/
        p.layer.current.should.equal p.defs[0]
        p.layer.type.should.eql 'mask'
        p.layer.current.mask.should.containDeep [
          { _attr: { color: '#000' } }
          { rect: { _attr: { fill: '#fff' } } }
        ]
      it 'should change back to wrapped group if polarity switches to dark', ->
        p.parameter [ '%', 'LPC', '%' ]
        p.parameter [ '%', 'LPD', '%' ]
        p.defs[0].mask[0]._attr.id.should.match /layer-1/
        p.group.should.containDeep {
          g: [ { _attr: {} }, { g: [ { _attr: {} } ] } ]
        }
        p.layer.current.should.equal p.group
        p.layer.level.should.equal 2
        p.layer.type.should.eql 'g'
      it 'should undefine the current position', ->
        p.parameter [ '%', 'LPD', '%' ]
        p.position.should.eql { x: null, y: null }
      it 'should throw an error for bad polarity', ->
        (-> p.parameter [ '%', 'LPXXX', '%' ] )
          .should.throw /unrecognized level polarity/

    describe 'step and repeat', ->
      it 'shouldnt do anything with SRX1Y1', ->
        p.parameter [ '%', 'FSLAX23Y23', 'MOIN', 'ADD10C,1', '%' ]
        # default SR of no steps
        p.parameter [ '%', 'SRX1Y1I0.0J0.0', '%' ]
        p.operate 'D10'
        # add a 1" round pad at 1,1
        p.operate 'X1000Y1000D03'
        # end file
        p.operate 'M02'
        p.finish()
        # result
        p.group.g.should.containDeep [
          { _attr: {} }
          { use: {} }
        ]
        p.group.g[0]._attr.should.match /layer-0/
      describe 'no clear levels', ->
        it 'with only 1 SR should wrap the current layer and repeat it', ->
          p.parameter [ '%', 'FSLAX23Y23', 'MOIN', 'ADD10C,1', '%' ]
          # step 3 times in the y at 2" and 2 times in the x at 3"
          p.parameter [ '%', 'SRX2Y3I3.0J2.0', '%' ]
          p.operate 'D10'
          # add a 1" round pad at 1,1
          p.operate 'X1000Y1000D03'
          # end file
          p.operate 'M02'
          p.finish()
          # result
          p.group.g.should.containDeep [
            { _attr: {} }
            { g: [ { _attr: {} }, { use: {} } ] }
            { use: { _attr: { x: '0', y: '2' } } }
            { use: { _attr: { x: '0', y: '4' } } }
            { use: { _attr: { x: '3', y: '0' } } }
            { use: { _attr: { x: '3', y: '2' } } }
            { use: { _attr: { x: '3', y: '4' } } }
          ]
          p.group.g[0]._attr.id.should.match /layer-0/
          p.group.g[1].g[0]._attr.id.should.match /sr-block-0/
          p.group.g[2].use._attr['xlink:href'].should.match /sr-block-0/
          p.group.g[3].use._attr['xlink:href'].should.match /sr-block-0/
          p.group.g[4].use._attr['xlink:href'].should.match /sr-block-0/
          p.group.g[5].use._attr['xlink:href'].should.match /sr-block-0/
          p.group.g[6].use._attr['xlink:href'].should.match /sr-block-0/
        it 'with multiple SRs it should keep the blocks separate', ->

      #describe 'with overlaping clear levels', ->
        # this gets tricky, see http://codepen.io/mcous/pen/IqGlf
  describe 'operate method', ->
    p = null
    beforeEach () -> p = new Plotter()

    it 'should handle comments gracefully', ->
      (-> p.operate 'G04 this is a comment').should.not.throw
    it 'should ignore deprecated commands', ->
      (-> p.operate 'G54').should.not.throw
      (-> p.operate 'G55').should.not.throw
      (-> p.operate 'G70').should.not.throw
      (-> p.operate 'G71').should.not.throw
      (-> p.operate 'G90').should.not.throw
      (-> p.operate 'G91').should.not.throw
      (-> p.operate 'M00').should.not.throw
      (-> p.operate 'M01').should.not.throw
    # it 'should throw for invalid commands', ->
    #   (-> p.operate 'G56').should.throw /invalid operation/
    #   (-> p.operate 'asdfgh').should.throw /invalid operation/
    #   (-> p.operate 'G01asdfgh').should.throw /invalid operation/
    it 'should declare the file done at M02', ->
      p.operate 'M02'
      p.done.should.be.true
    it 'should set the interpolation mode to linear with a G1 or G01', ->
      p.operate 'G1'
      p.mode.should.eql 'i'
      p.mode = null
      p.operate 'G01'
      p.mode.should.eql 'i'
    it 'should set the mode to clockwise with a G2 or G02', ->
      p.operate 'G2'
      p.mode.should.eql 'cw'
      p.mode = null
      p.operate 'G02'
      p.mode.should.eql 'cw'
    it 'should set the mode to counter clockwise with a G3 or G03', ->
      p.operate 'G3'
      p.mode.should.eql 'ccw'
      p.mode = null
      p.operate 'G03'
      p.mode.should.eql 'ccw'
    it 'should turn region mode on or off with a G36 or G37', ->
      p.trace.region.should.be.false
      p.operate 'G36'
      p.trace.region.should.be.true
      p.operate 'G37'
      p.trace.region.should.be.false
      p.mode?.should.be.false
    it 'should set arc mode G74 and G75', ->
      p.quad?.should.be.false
      p.operate 'G74'
      p.quad.should.eql 's'
      p.operate 'G75'
      p.quad.should.eql 'm'

    # tool changes
    describe 'with tool changes', ->
      it 'should change the tool if it exists', ->
        p.parameter [ '%', 'ADD10C,10', '%' ]
        p.operate 'D10'
        p.currentTool.should.eql 'D10'
      it 'should change the tool even with deprecated commands', ->
        p.parameter [ '%', 'ADD10C,10', '%' ]
        p.operate 'G54D10'
        p.currentTool.should.eql 'D10'
      it 'should throw an error if the tool doesnt exist', ->
        (-> p.operate  'D10').should.throw /does not exist/
      it 'should throw an error if region mode is on', ->
        p.parameter [ '%', 'ADD10C,10', '%' ]
        p.operate 'G36'
        (-> p.operate 'D10').should.throw /cannot change tool/

    describe 'with interpolation blocks', ->
      it 'a D2/D02 should move the current point', ->
        p.parameter [ '%', 'FSLAX34Y34', 'MOIN', '%' ]
        p.operate 'X1000Y1000D02'
        p.position.should.containEql { x: 0.1, y: 0.1 }
        p.operate 'X2000Y2000D2'
        p.position.should.containEql { x: 0.2, y: 0.2 }
      describe 'flashing a pad', ->
        it 'a D3/D03 should add a pad to the current layer', ->
          p.parameter [ '%', 'FSLAX34Y34', 'MOIN', 'ADD10C,1', '%' ]
          p.operate 'D10'
          p.operate 'X100Y100D03'
          p.layer.current.g.should.containDeep [
            { use: { _attr: { x: '0.01', y: '0.01' } } }
          ]
        it 'should add the pad to the board bounding box', ->
          p.parameter [ '%', 'FSLAX33Y33', 'MOIN', 'ADD10C,1', '%' ]
          p.operate 'D10'
          p.operate 'X-100Y2000D03'
          p.bbox.should.eql { xMin: -0.6, yMin: 1.5, xMax: 0.4, yMax: 2.5 }
          p.operate 'X-1000Y200D03'
          p.bbox.should.eql { xMin: -1.5, yMin: -0.3, xMax: 0.4, yMax: 2.5 }
    describe 'in region mode', ->

  describe 'coordinate method', ->
    p = null
    beforeEach () -> p = new Plotter()

    it 'should throw an error if the format is undefined', ->
      (-> p.coordinate 'X23420Y1234').should.throw /format undefined/

    it 'should handle leading zero suppression', ->
      p.format.set = true
      p.format.zero = 'L'
      p.format.notation = 'A'
      p.format.places = [ 3, 4 ]
      result = p.coordinate 'X123Y32342'
      result.should.containEql { x: 0.0123, y: 3.2342 }
    it 'should handle trailing zero suppression', ->
      p.format.set = true
      p.format.zero = 'T'
      p.format.notation = 'A'
      p.format.places = [ 3, 4 ]
      result = p.coordinate 'X12Y32342'
      result.should.containEql { x: 120, y: 323.42 }
    it 'should handle absolute notatation', ->
      p.position.x = 1
      p.position.y = 2
      p.format.set = true
      p.format.zero = 'L'
      p.format.notation = 'A'
      p.format.places = [ 3, 4 ]
      result = p.coordinate 'X22000Y11000'
      result.should.containEql { x: 2.2, y: 1.1 }
    it 'should handle relative notation', ->
      p.position.x = 1
      p.position.y = 2
      p.format.set = true
      p.format.zero = 'L'
      p.format.notation = 'I'
      p.format.places = [ 3, 4 ]
      result = p.coordinate 'X22000Y11000'
      result.should.containEql { x: 3.2, y: 3.1 }
    it 'should return the current position for an empty string', ->
      p.position.x = 1
      p.position.y = 2
      p.format.set = true
      p.format.zero = 'L'
      p.format.notation = 'A'
      p.format.places = [ 3, 4 ]
      result = p.coordinate ''
      result.should.containEql { x: 1, y: 2 }
    it 'should replace missing coords with the current value for that coord', ->
      p.position.x = 1
      p.position.y = 2
      p.format.set = true
      p.format.zero = 'L'
      p.format.notation = 'A'
      p.format.places = [ 3, 4 ]
      result = p.coordinate 'X1000'
      result.should.containEql { x: 0.1, y: 2 }
      result = p.coordinate 'Y1000'
      result.should.containEql { x: 1, y: 0.1 }

  describe 'finish path method', ->
    p = null
    beforeEach () ->
      p = new Plotter()
      p.parameter [ '%', 'FSLAX34Y34', 'MOIN', 'ADD10C,1', '%' ]
      p.operate 'D10'
      p.trace.path = 'M0 0L1 1L1 2L0 0Z'

    it 'should take the existing path string and turn it into a path object', ->
      p.finishTrace()
      p.layer.current.g.should.containDeep [
        { path: { _attr: { d: 'M0 0L1 1L1 2L0 0Z' }}}
      ]
    it 'should apply the stroke properties if region mode is off', ->
      p.finishTrace()
      p.layer.current.g.should.containDeep [
        { path: { _attr: {
              'stroke-linecap': 'round'
              'stroke-linejoin': 'round'
              'stroke-width': '1'
            }
          }
        }
      ]
    it 'should apply region properties if region mode is on', ->
      p.trace.region = true
      p.finishTrace()
      p.layer.current.g.should.containDeep [
        { path: { _attr: { 'stroke-width': '0', fill: 'currentColor' } } }
      ]

  describe 'creating paths', ->
    p = null
    beforeEach () ->
      p = new Plotter()
      p.parameter [ '%', 'FSLAX34Y34', 'MOIN', 'ADD10C,1', '%' ]
      p.operate 'D10'

    it 'should start a new path with a moveto on the first D01', ->
      p.operate 'G01X10000Y10000D01'
      p.trace.path.should.containEql 'M0 0'

    describe 'adding line segments', ->
      it 'should add a line with a G01', ->
        p.operate 'G01X10000Y10000D01'
        p.trace.path.should.containEql 'M0 0L1 1'

      describe 'adjusting the bbox', ->
        it 'should use the end points and tool size in trace mode', ->
          p.operate 'G01X10000Y10000D01'
          p.bbox.should.eql { xMin: -0.5, yMin: -0.5, xMax: 1.5, yMax: 1.5 }

    describe 'single quadrant arc mode', ->
      beforeEach () -> p.operate 'G74'
      it 'should add a CW arc with a G02', ->
        p.operate 'G02X10000Y10000I10000D01'
        p.trace.path.should.containEql 'A1 1 0 0 0 1 1'
      it 'should add a CCW arc with a G03', ->
        p.operate 'G03X10000Y10000I10000D01'
        p.trace.path.should.containEql 'A1 1 0 0 1 1 1'

    describe 'multi quadrant arc mode', ->
      beforeEach () -> p.operate 'G75'
      it 'should add a CW arc with a G02', ->
        p.operate 'G02X10000Y10000J10000D01'
        p.trace.path.should.containEql 'A1 1 0 1 0 1 1'
      it 'should add a CCW arc with a G03', ->
        p.operate 'G03X10000Y10000I10000D01'
        p.trace.path.should.containEql 'A1 1 0 1 1 1 1'
      it 'should add full circle (2 paths) if start and end are the same', ->
        p.operate 'G02I10000D01'
        p.trace.path.should.containEql 'A1 1 0 0 0 2 0A1 1 0 0 0 0 0'
