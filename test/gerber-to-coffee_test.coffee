gerberToSvg = require '../src/gerber-to-svg'

SVGMATCH = /^<svg.*\/>$/mg

describe 'GerberToSvg', ->
  describe 'convert', ->
    it 'should return SVG document by default', ->
      result = gerberToSvg.convert ""
      result.should.match SVGMATCH
