VALIDPARAMS = [
  'code'
  'shape'
  'dia'
  'width'
  'height'
  'points'
  'rotation'
  'holeX'
  'holeY'
]

INVALIDCIRCLEPARAMS = [
  'width'
  'height'
  'points'
  'rotation'
]

INVALIDRECTPARAMS = [
  'dia'
  'points'
  'rotation'
]

INVALIDPOLYPARAMS = [
  'width'
  'height'
]

class Tool
  constructor: (params) ->
    for key, value of params
      if key in VALIDPARAMS then @["#{key}"] = value
      else throw new TypeError "#{key} is an invalid parameter for a tool"

    if @code? then @code = parseInt @code, 10
    else throw new RangeError 'code required for tools'
    if @code < 10 then throw new RangeError "#{@code} is an invalid code for a tool"

    switch @shape
      when 'C'
        unless @dia? then throw new RangeError 'diameter required for circle tools'
        for p in INVALIDCIRCLEPARAMS
          if @["#{p}"]? then throw new TypeError "#{p} is an invalid circle parameter"
        @shape = 'circle'
        @dia = parseFloat @dia

      when 'R', 'O'
        unless @width? then throw new RangeError 'width required for rect/obround tools'
        unless @height? then throw new RangeError 'height required for rect/obround tools'
        for p in INVALIDRECTPARAMS
          if @["#{p}"]? then throw new TypeError "#{p} is an invalid rect/obround parameter"
        if @shape is 'O' then @obround = true
        @shape = 'rect'
        @width = parseFloat @width
        @height = parseFloat @height

      when 'P'
        unless @dia? then throw new RangeError 'diameter required for polygon tools'
        unless @points? then throw new RangeError 'points required for polygon tools'
        for p in INVALIDPOLYPARAMS
          if @["#{p}"]? then throw new TypeError "#{p} is an invalid polygon parameter"
        @shape = 'polygon'
        @dia = parseFloat @dia
        @points = parseInt @points, 10
        if @rotation? then @rotation = parseFloat @rotation

      else throw new RangeError "#{@shape} is an invalid shape for a tool"

    if @holeX?
      @holeX = parseFloat @holeX
      if @holeY? then @holeY = parseFloat @holeY

module.exports = Tool
