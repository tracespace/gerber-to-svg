# test suite for the gerber-to-svg function

gerberToSvg = require '../src/gerber-to-svg'
fs = require 'fs'
coordFactor = require('../src/svg-coord').factor

# stream hook for testing for warnings
streamCapture = require './stream-capture'
stderr = -> streamCapture(process.stderr)

exGerb = fs.readFileSync './test/gerber/gerber-spec-example-2.gbr', 'utf-8'
exDrill = fs.readFileSync './test/drill/example1.drl', 'utf-8'
warnGerb = fs.readFileSync './test/gerber/repeated-op-code-test.gbr', 'utf-8'

describe 'gerber to svg function', ->
  it 'should default to the gerber plotter', ->
    (-> gerberToSvg exGerb).should.not.throw()
    (-> gerberToSvg exDrill).should.throw()

  it 'should be able to plot drill files if told to do so', ->
    (-> gerberToSvg exDrill, { drill: true }).should.not.throw()
    (-> gerberToSvg exGerb, { drill: true }).should.throw()

  it 'should return compressed output by default', ->
    result = gerberToSvg exGerb
    result.split('\n').length.should.eql 1

  it 'should return pretty output with an option', ->
    result = gerberToSvg exGerb, { pretty: true }
    result.split('\n').length.should.be.greaterThan 1

  it 'should return the xml string by default', ->
    result = gerberToSvg exGerb
    (typeof result).should.eql 'string'

  it 'should return the xml object if the object option is passed', ->
    result = gerberToSvg exGerb, { object: true }
    (typeof result).should.eql 'object'
    Object.keys(result)[0].should.eql 'svg'
    Array.isArray(result.svg.viewBox).should.be.true

  it 'should have all the requisite svg header stuff', ->
    result = gerberToSvg exGerb, { object: true }
    result.should.containDeep {
      svg: {
        xmlns: 'http://www.w3.org/2000/svg'
        version: '1.1'
        'xmlns:xlink': 'http://www.w3.org/1999/xlink'
      }
    }

  it 'should set the bbox to zero if the svg has no shapes', ->
    result = gerberToSvg 'M02*', { object: true }
    result.svg.viewBox.should.eql [ 0, 0, 0, 0 ]
    result.svg.width.should.match /^0\D/
    result.svg.height.should.match /^0\D/

  it 'should set the real width and height according to the vbox', ->
    result = gerberToSvg exGerb, { object: true }
    vbWidth  = result.svg.viewBox[2]
    vbHeight = result.svg.viewBox[3]
    result.svg.width.should.eql  "#{vbWidth /coordFactor}in"
    result.svg.height.should.eql "#{vbHeight/coordFactor}in"

  describe 'converting an svg object into an svg string', ->
    it 'should be able to convert an svg object into an svg string', ->
      result1 = gerberToSvg exGerb
      obj = gerberToSvg exGerb, { object: true }
      result2 = gerberToSvg obj
      # wipe out unique ids for the layers, masks, and pads so i can compare
      result1 = result1.replace /((pad-)|(gerber-)|(mask-)|(_))\d+/g, 'unique'
      result2 = result2.replace /((pad-)|(gerber-)|(mask-)|(_))\d+/g, 'unique'
      result2.should.eql result1
    it 'should throw an error if a non svg object is passed in', ->
      (-> gerberToSvg { thing: {} }).should.throw /non SVG/

  describe 'logging warnings', ->
    it 'should send warnings to console.warn by default', ->
      # hook into stderr
      hook = stderr()
      hook.captured().length.should.equal 0
      # process a file that will produce warnings
      gerberToSvg warnGerb
      # check that we got some warnigns
      hook.captured().length.should.not.equal 0
      hook.unhook()
      
    it 'should push warnings to an array if option is set', ->
      warnings = []
      # process a file that will produce warnings
      gerberToSvg warnGerb, { warnArr: warnings }
      warnings.length.should.not.equal 0
