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
circle = (params) ->
  # parameters to pass into standard circle function
  cir = {}
  # first parameter is exposure
  # if exposure is off, we're masking, and we'll need to take on a fill
  mask = params[0] is '0'
  # second parameter is diameter
  cir.dia = functionOrValue params[1]
  # third and fourth are x and y of center
  cir.cx = functionOrValue params[2]
  cir.cy = functionOrValue params[3]
  # tack the circle on
  result += standard(t, cir).pad
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
    # block 0 is going to be AMmacroname
    @name = blocks[0][2..]
    # save the rest of the blocks
    @blocks = blocks[1..]
    # for b in blocks[1..]
    #   # check the first character of the block
    #   call = { fn: null, p: [] }
    #   switch b[0]
    #     when '0'
    #       # ignore comments
    #       console.log 'ignoring aperture macro comment'
    #     when '$'
    #       # modifier definition
    #       console.log 'modifier definition'
    #     else
    #       # primative; split at commas to get parameters
    #       mods = b.split ','
    #       call.fn = primitives[mods[0]]
    #       for m in mods[1..]
    #         # if it's only numbers, that's easy
    #         if m.match /[\d.]+/ then call.p.push parseFloat m
    #         # else we could be dealing with a call to a variable (e.g. $4)
    #         else if m.match /^\$\d+$/ then call.p.push => @getMod m
    #   @calls.push call

  # run the macro and return the pad
  run: (tool, modifiers = []) ->
    @modifiers["$#{i+1}"] = m for m, i in modifiers
    pad = ''

  # run a block and return the modified pad string
  runBlock: (block, pad) ->
    # check the first character of the block
    switch block[0]
      # if it's a comment (starts with 0), we can ignore
      when '0'
        pad
      # if we got ourselves a modifier, we should set it
      when '$'
        mod = block.match(/^\$\d+(?=\=)/)?[0]
        val = block[1+mod.length..]
        @modifiers[mod] = @getNumber val
        pad
      # or it's a primitive
      when '1', '2', '20', '21', '22', '4', '5', '6', '7'


      else
        # throw an error because I don't know what's going on
        throw new SyntaxError "'#{block}' unrecognized tool macro block"


      # or it's a primitive that's always exposure on

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

module.exports = MacroTool
