# aperture macro class
# parses an aperture macro and then returns the pad when the tool is defined

# uses the standard tool functions
standard = require '../src/standard-tool'

# aperture macro list
macros = {}

# macro id number (incremented for unique mask ids)
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
  if params[0]() is 0
    maskId = "#{t}clear"
    pad = "<g mask=\"url(##{maskId})\">#{pad}</g><mask id=\"#{maskId}\">"
    pad += "<rect width=\"100%\" height=\"100%\" fill=\"#fff\" />"
  # second parameter is diameter
  cir.dia = params[1]()
  # third and fourth are x and y of center
  cir.cx = params[2]()
  cir.cy = params[3]()
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
    # macro calls and modifiers
    @calls = []
    @modifiers = {}
    # block 0 is the name of the macro
    macros[blocks[0]] = this
    # loop through the block
    for b in blocks[1..]
      # check the first character of the block
      switch b[0]
        when '0'
          # ignore comments
          console.log 'ignoring aperture macro comment'
        when '$'
          # modifier definition
          console.log 'modifier definition'
        else
          # primitive



module.exports = {
  MacroTool: MacroTool
  macros: macros
  primitives: primitives
}
