# test suite for the gerber-to-svg function

gerberToSvg = require '../src/gerber-to-svg'
fs = require 'fs'

exGerb = fs.readFileSync './test/gerber/gerber-spec-example-2.gbr', 'utf-8'
exDrill = fs.readFileSync './test/drill/example1.drl', 'utf-8'

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

  it 'should have all the requisite svg header stuff', ->
    result = gerberToSvg exGerb, { object: true }
    result.should.containDeep {
      svg: {
        xmlns: 'http://www.w3.org/2000/svg'
        version: '1.1'
        'xmlns:xlink': 'http://www.w3.org/1999/xlink'
      }
    }
