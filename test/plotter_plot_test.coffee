# test suite for the plot method of the plotter class
Plotter = require '../src/plotter'
fs = require 'fs'

describe 'the plot method of the Plotter class', ->
  it 'should plot example 1 from the gerber spec', ->
    testGerber= fs.readFileSync 'test/gerber/gerber-spec-example-1.gbr', 'utf-8'
    p = new Plotter testGerber
    result = p.plot()
    result.should.containDeep {
      svg: {
        width: '11.01mm'
        height:'5.01mm'
        viewBox:'-0.005 -0.005 11.01 5.01'
        _: [
          {
            g: {
              _: [
                { path: { d: 'M0 0L5 0L5 5L0 5L0 0' } }
                { path: { d: 'M6 0L11 0L11 5L6 5L6 0' } }
              ]
            }
          }
        ]
      }
    }

  it 'should plot example 2 from the gerber spec', ->
    testGerber= fs.readFileSync 'test/gerber/gerber-spec-example-2.gbr', 'utf-8'
    p = new Plotter testGerber
    (-> p.plot()).should.not.throw
