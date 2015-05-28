# test suite for the plot method of the plotter class
Plotter = require '../src/plotter'
expect = require('chai').expect
GerberReader = require '../src/gerber-reader'
GerberParser = require '../src/gerber-parser'
fs = require 'fs'

# svg coord factor
factor = require('../src/svg-coord').factor

describe.skip 'the plot method of the Plotter class', ->

  it 'should plot example 1 from the gerber spec', ->
    testGerb = fs.readFileSync 'test/gerber/gerber-spec-example-1.gbr', 'utf-8'
    p = new Plotter(new GerberReader(testGerb), new GerberParser())
    p.plot()
    expect( p.group.g._ ).to.have.length 1
    expect( p.group.g._[0].path.d ).to.eql [
      'M', 0 * factor,  0 * factor
      'L', 5 * factor,  0 * factor
      'L', 5 * factor,  5 * factor
      'L', 0 * factor,  5 * factor
      'L', 0 * factor,  0 * factor
      'M', 6 * factor,  0 * factor
      'L', 11 * factor, 0 * factor
      'L', 11 * factor, 5 * factor
      'L', 6 * factor,  5 * factor
      'L', 6 * factor,  0 * factor
    ]

  it 'should plot example 2 from the gerber spec', ->
    testGerb = fs.readFileSync 'test/gerber/gerber-spec-example-2.gbr', 'utf-8'
    p = new Plotter(new GerberReader(testGerb), new GerberParser())
    expect( -> p.plot() ).to.not.throw

  it 'should throw an error if a gerber file ends without an M02*', ->
    testGerb = '%FSLAX34Y34*%%MOIN*%%ADD10C,0.5*%X0Y0D03*'
    p = new Plotter(new GerberReader(testGerb), new GerberParser())
    expect( -> p.plot() ).to.throw /end of file/
