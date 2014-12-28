# test suite for the gerber-to-svg function
gerberToSvg = require '../src/gerber-to-svg'
expect = require('chai').expect
fs = require 'fs'
coordFactor = require('../src/svg-coord').factor

# stream hook for testing for warnings
warnings = require './warn-capture'

exGerb = fs.readFileSync './test/gerber/gerber-spec-example-2.gbr', 'utf-8'
exDrill = fs.readFileSync './test/drill/example1.drl', 'utf-8'
warnGerb = fs.readFileSync './test/gerber/repeated-op-code-test.gbr', 'utf-8'

describe 'gerber to svg function', ->
  it 'should default to the gerber plotter', ->
    expect( -> gerberToSvg exGerb ).to.not.throw()
    expect( -> gerberToSvg exDrill ).to.throw()

  it 'should be able to plot drill files if told to do so', ->
    expect( -> gerberToSvg exDrill, { drill: true } ).to.not.throw()
    expect( -> gerberToSvg exGerb, { drill: true } ).to.throw()

  it 'should return compressed output by default', ->
    result = gerberToSvg exGerb
    expect( result.split('\n').length ).to.eql 1

  it 'should return pretty output with an option', ->
    result = gerberToSvg exGerb, { pretty: true }
    expect( result.split('\n').length ).to.be.greaterThan 1

  it 'should return the xml string by default', ->
    result = gerberToSvg exGerb
    expect( typeof result ).to.eql 'string'

  it 'should return the xml object if the object option is passed', ->
    result = gerberToSvg exGerb, { object: true }
    expect( typeof result ).to.eql 'object'
    expect( Object.keys(result)[0] ).to.eql 'svg'
    expect( Array.isArray result.svg.viewBox ).to.be.true

  it 'should have all the requisite svg header stuff', ->
    result = gerberToSvg exGerb, { object: true }
    expect( result ).to.containDeep {
      svg: {
        xmlns: 'http://www.w3.org/2000/svg'
        version: '1.1'
        'xmlns:xlink': 'http://www.w3.org/1999/xlink'
      }
    }

  it 'should set the bbox to zero if the svg has no shapes', ->
    result = gerberToSvg 'M02*', { object: true }
    expect( result.svg.viewBox ).to.eql [ 0, 0, 0, 0 ]
    expect( result.svg.width ).to.match /^0\D/
    expect( result.svg.height ).to.match /^0\D/

  it 'should set the real width and height according to the vbox', ->
    result = gerberToSvg exGerb, { object: true }
    vbWidth  = result.svg.viewBox[2]
    vbHeight = result.svg.viewBox[3]
    expect( result.svg.width ).to.eql  "#{vbWidth /coordFactor}in"
    expect( result.svg.height ).to.eql "#{vbHeight/coordFactor}in"

  describe 'converting an svg object into an svg string', ->
    it 'should be able to convert an svg object into an svg string', ->
      result1 = gerberToSvg exGerb
      obj = gerberToSvg exGerb, { object: true }
      result2 = gerberToSvg obj
      # wipe out unique ids for the layers, masks, and pads so i can compare
      result1 = result1.replace /((pad-)|(gerber-)|(mask-)|(_))\d+/g, 'unique'
      result2 = result2.replace /((pad-)|(gerber-)|(mask-)|(_))\d+/g, 'unique'
      expect( result2 ).to.eql result1
    it 'should throw an error if a non svg object is passed in', ->
      expect( -> gerberToSvg { thing: {} } ).to.throw /non SVG/

  describe 'logging warnings', ->
    it 'should send warnings to console.warn by default', ->
      # hook into stderr
      warnings.hook()
      # process a file that will produce warnings
      gerberToSvg warnGerb
      # check that we got some warnigns
      expect( warnings.unhook().length ).to.not.equal 0
      
    it 'should push warnings to an array if option is set', ->
      warnings = []
      # process a file that will produce warnings
      gerberToSvg warnGerb, { warnArr: warnings }
      expect( warnings.length ).to.not.equal 0
