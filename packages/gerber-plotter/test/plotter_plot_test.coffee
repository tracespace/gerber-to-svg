# test suite for the plot method of the plotter class
Plotter = require '../src/plotter-old'
fs = require 'fs'

describe 'the plot method of the Plotter class', ->
  it 'should plot example 1 from the gerber spec', ->
    testGerber= fs.readFileSync 'test/gerber/gerber-spec-example-1.gbr', 'utf-8'
    p = new Plotter testGerber
    p.plot()
    p.group.g.should.containDeep {
      _: [
        { path: { d: 'M0 0L5 0L5 5L0 5L0 0' } }
        { path: { d: 'M6 0L11 0L11 5L6 5L6 0' } }
      ]
    }

  it 'should plot example 2 from the gerber spec', ->
    testGerber= fs.readFileSync 'test/gerber/gerber-spec-example-2.gbr', 'utf-8'
    p = new Plotter testGerber
    (-> p.plot()).should.not.throw

  it 'should throw an error if the file ends without an M02*', ->
    testGerber = '%FSLAX34Y34*%%MOIN*%%ADD10C,0.5*%X0Y0D03*'
    p = new Plotter testGerber
    (-> p.plot()).should.throw /end of file/
