# aperture macro class
# parses an aperture macro and then returns the pad when the tool is defined

# uses the standard tool functions
standard = require './standard-tool'
# calculator parsing for macro arithmetic
calc = require './macro-calc'

# aperture macro list
macros = {}

# macro id number (incremented for unique ids)
id = 0

# macro primitive functions
# tool is the tool number
# pad is the existing pad
# params is an array of functions
circle = (pad, params) ->
  # parameters to pass into standard circle function
  cir = {}
  # tool identifier
  t = "_macro#{id++}_"
  # first parameter is exposure, and if it's off, we need to mask
  maskId = false
  if functionOrValue params[0] is '0'
    maskId = "#{t}clear"
    pad = "<g mask=\"url(##{maskId})\">#{pad}</g><mask id=\"#{maskId}\">"
    pad += "<rect width=\"100%\" height=\"100%\" fill=\"#fff\" />"
  # second parameter is diameter
  cir.dia = functionOrValue params[1]
  # third and fourth are x and y of center
  cir.cx = functionOrValue params[2]
  cir.cy = functionOrValue params[3]
  # tack the circle on
  pad += standard(t, cir).pad
  # finish mask if applicable
  if maskId
    pad = pad[0...-2] + 'fill="#000" /></mask>'
  # return
  pad

# macro primitives
primitives = {
  1: circle
  # 2: line
  # 20: line
  # 21: lowerLeftRect
  # 22: rectangle
  # 4: outline
  # 5: polygon
  # 6: moire
  # 7: thermal
}

class MacroTool
  # constructor takes in macro blocks
  constructor: (blocks) ->
    # macro modifiers
    @modifiers = {}
    # block 0 is the name of the macro
    macros[blocks[0]] = this
    # loop through the block
    for b in blocks[1..]
      # check the first character of the block
      call = { fn: null, p: [] }
      switch b[0]
        when '0'
          # ignore comments
          console.log 'ignoring aperture macro comment'
        when '$'
          # modifier definition
          console.log 'modifier definition'
        else
          # primative; split at commas to get parameters
          mods = b.split ','
          call.fn = primitives[mods[0]]
          for m in mods[1..]
            # if it's only numbers, that's easy
            if m.match /[\d.]+/ then call.p.push parseFloat m
            # else we could be dealing with a call to a variable (e.g. $4)
            else if m.match /^\$\d+$/ then call.p.push => @getMod m
      @calls.push call

  # run the macro and return the pad
  run: (tool, modifiers = []) ->
    @modifiers["$#{i+1}"] = parseFloat m for m, i in modifiers
    pad = ''

  getNumber: (s) ->
    # normal number all by itself
    if s.match /^[+-]?[\d.]+$/ then parseFloat s
    # modifier all by its lonesome
    else if s.match /^\$\d+$/ then parseFloat @modifiers[s]
    # else we got us some maths
    else @evaluate calc.parse s

  evaluate: (op) ->
    switch op.type
      when 'n' then @getNumber op.val
      when '+' then @evaluate(op.left) + @evaluate(op.right)
      when '-' then @evaluate(op.left) - @evaluate(op.right)
      when 'x' then @evaluate(op.left) * @evaluate(op.right)
      when '/' then @evaluate(op.left) / @evaluate(op.right)

module.exports = {
  MacroTool: MacroTool
  macros: macros
}
