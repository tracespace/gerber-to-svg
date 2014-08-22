# test suite for the plot method of the plotter class
Plotter = require '../src/plotter'
GerberReader = require '../src/gerber-reader'
GerberParser = require '../src/gerber-parser'
fs = require 'fs'

describe 'the plot method of the Plotter class', ->
  it 'should plot example 1 from the gerber spec', ->
    testGerber= fs.readFileSync 'test/gerber/gerber-spec-example-1.gbr', 'utf-8'
    p = new Plotter testGerber, GerberReader, GerberParser
    p.plot()
    p.group.g.should.containDeep {
      _: [
        {
          path: { d: [ 'M', 0, 0, 'L', 5, 0, 'L', 5, 5, 'L', 0, 5, 'L', 0,  0,
            'M', 6, 0, 'L', 11, 0, 'L', 11, 5, 'L', 6, 5, 'L', 6, 0 ]
          }
        }
      ]
    }

  it 'should plot example 2 from the gerber spec', ->
    testGerber= fs.readFileSync 'test/gerber/gerber-spec-example-2.gbr', 'utf-8'
    p = new Plotter testGerber, GerberReader, GerberParser
    (-> p.plot()).should.not.throw

  it 'should throw an error if a gerber file ends without an M02*', ->
    testGerber = '%FSLAX34Y34*%%MOIN*%%ADD10C,0.5*%X0Y0D03*'
    p = new Plotter testGerber, GerberReader, GerberParser
    (-> p.plot()).should.throw /end of file/
