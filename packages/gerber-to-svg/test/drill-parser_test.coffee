# test suit for the NC drill file parser
Parser = require '../src/drill-parser'

describe 'NC drill file parser', ->
  p = null
  beforeEach -> p = new Parser

  it 'should know when the header starts and ends', ->
    p.header.should.be.false
    p.parseCommand 'M48'
    p.header.should.be.true
    p.parseCommand 'M95'
    p.header.should.be.false
    p.header = true
    p.parseCommand '%'
    p.header.should.be.false

  describe 'parsing header commands', ->
    beforeEach -> p.header = true

    it 'should return a set units command with INCH and METRIC', ->
      p.parseCommand('INCH').should.containDeep { set: { units: 'in' } }
      p.parseCommand('METRIC').should.containDeep { set: { units: 'mm' } }
    it 'should use 3.3 format for metric and 2.4 for inches', ->
      p.parseCommand 'INCH'
      p.format.places.should.eql [ 2, 4 ]
      p.parseCommand 'METRIC'
      p.format.places.should.eql [ 3, 3 ]
    it 'should return a define tool command for tool definitions', ->
      p.parseCommand 'T1C0.015'
        .should.containDeep { tool: { code: 'T1', shape: { dia: 0.015 } } }
      p.parseCommand 'T13C0.142'
        .should.containDeep { tool: { code: 'T13', shape: { dia: 0.142 } } }
#
# # test headers for units
# TEST_IN = 'M48\nFMAT,2\nINCH,TZ\n%'
# TEST_MM = 'M48\nFMAT,2\nMETRIC,TZ\n%'
# # test headers for zero suppression
# # excellon format specifies which zeros to keep, so switch to match gerber
# TEST_SUPPRESS_LEAD = 'M48\nFMAT,2\nINCH,TZ\n%'
# TEST_SUPPRESS_TRAIL = 'M48\nFMAT,2\nINCH,LZ\n%'
# # test header with tools
# TEST_TOOLS = 'M48\nFMAT,2\nINCH,TZ\nT1C0.015\nT2C0.020\nT3C0.035\nT4C0.098\n%'
# describe 'NC drill file parser', ->
#   describe 'parsing the header commands', ->
#     it 'should return the units', ->
#       pInches = new Parser TEST_IN
#       pInches.units.should.eql 'in'
#       pMetric = new Parser TEST_MM
#       pMetric.units.should.eql 'mm'
#     it 'should use 3.3 for metric and 2.4 for inches', ->
#       pInches = new Parser TEST_IN
#       pInches.format.places.should.eql [2, 4]
#       pMetric = new Parser TEST_MM
#       pMetric.format.places.should.eql [3, 3]
#     it 'should get leading or trailing zero suppression', ->
#       pSuppressLead = new Parser TEST_SUPPRESS_LEAD
#       pSuppressLead.format.zero.should.eql 'l'
#       pSuppressTrail = new Parser TEST_SUPPRESS_TRAIL
#       pSuppressTrail.format.zero.should.eql 't'
#     it 'should generate a list of tools', ->
#       pTool = new Parser
