# test suit for the NC driller
Driller = require '../src/driller'

# drill test string 1
TEST1 = '''
  M48
  ;FORMAT={2:4/ absolute / inch / keep zeros}
  FMAT,2
  INCH,TZ
  T1C0.015
  T2C0.020
  T3C0.035
  %
  G90
  G05
  M72
  T1
  X001600Y015800
  X002000Y012500
  X002550Y016000
  T2
  X001050Y011450
  T3
  X009500Y011000
  X009500Y010000
  T0
  M30
'''

# drill test string 2
# adapted from drill file for Spark Core from https://github.com/spark/core
TEST2 = '''
  %
  M48
  M72
  T01C0.0118
  T02C0.0236
  T03C0.0350
  %
  T01
  X1743Y1155
  X2143Y755
  X2693Y505
  T02
  X6011Y12928
  X4475Y12928
  T03
  X1743Y12755
  M30
'''

describe 'driller class', ->
  it 'should correctly drill the first test string', ->
    d = new Driller TEST1
    d.plot()
    id1 = '#' + d.defs[0].circle.id
    id2 = '#' + d.defs[1].circle.id
    id3 = '#' + d.defs[2].circle.id
    d.units.should.eql 'in'
    d.defs.should.containDeep [
      { circle: { r: 0.0075 } }
      { circle: { r: 0.01   } }
      { circle: { r: 0.0175 } }
    ]
    d.group.should.containDeep {
      g: {
        _: [
          { use: { 'xlink:href': id1, x: .16,  y: 1.58  } }
          { use: { 'xlink:href': id1, x: .2,   y: 1.25  } }
          { use: { 'xlink:href': id1, x: .255, y: 1.6   } }
          { use: { 'xlink:href': id2, x: .105, y: 1.145 } }
          { use: { 'xlink:href': id3, x: .95,  y: 1.1   } }
          { use: { 'xlink:href': id3, x: .95,  y: 1     } }
        ]
      }
    }

    it 'should correctly drill the second test string', ->
      d = new Driller TEST2
      d.plot()
      id1 = '#' + d.defs[0].circle.id
      id2 = '#' + d.defs[1].circle.id
      id3 = '#' + d.defs[2].circle.id
      d.units.should.eql 'in'
      d.defs.should.containDeep [
        { circle: { r: 0.0175 } }
        { circle: { r: 0.0118 } }
        { circle: { r: 0.0059 } }
      ]
      d.group.should.containDeep {
        g: {
          _: [
            { use: { 'xlink:href': id1, x: 0.1743, y: 0.1155 } }
            { use: { 'xlink:href': id1, x: 0.2143, y: 0.0755 } }
            { use: { 'xlink:href': id1, x: 0.2693, y: 0.0505 } }
            { use: { 'xlink:href': id2, x: 0.6011, y: 1.2928 } }
            { use: { 'xlink:href': id2, x: 0.4475, y: 1.2928 } }
            { use: { 'xlink:href': id3, x: 0.1743, y: 1.2755 } }
          ]
        }
      }
