# standard tool functions
# functions take an object with tool parameters
# functions return an object with the svg pad string and the svg stroke properties if applicable

standardTool = (tool, p) ->
  result = { pad: '', trace: false }
  # pad center
  p.cx = p.cx ? 0
  p.cy = p.cy ? 0
  # figure out the tool
  if p.dia? and not p.verticies?
    # we've got a circle tool unless there's confusion
    if p.obround? or p.width? or p.height? or p.degrees?
      throw new Error "incompatible parameters for tool #{tool}"
    # get the initial shape of the pad and apply the stroke properties
    padShape = circle p
    unless p.hole? then result.trace = {
      'stroke-linecap': 'round'
      'stroke-linejoin': 'round'
      'stroke-width': "#{p.dia}"
    }

  else if p.width? and p.height?
    # rectangle tool unless bad params
    if p.dia? or p.verticies? or p.degrees?
      throw new Error "incompatible parameters for tool #{tool}"
    padShape = ''

  else if p.dia? and p.verticies?
    # we've got a polygon tool unless there's confusion
    if p.obround? or p.width? or p.height?
      throw new Error "incompatible parameters for tool #{tool}"
    padShape = ''

  # apply the hole if necessary
  if p.hole?
    result.pad += "<mask id=\"tool#{tool}pad_hole\">#{padShape} fill=\"#fff\" />"
    if p.hole.dia?
      result.pad += circle {
        dia: p.hole.dia
        cx: p.cx
        cy: p.cy
      }
    else if p.hole.width? and p.hole.height?
      result.pad += rectangle {
        cx: p.cx
        cy: p.cy
        width: p.hole.width
        height: p.hole.height
      }
    # close the mask
    result.pad += ' fill="#000" /></mask>'

  # finsish the pad string, and add mask url if necessary
  result.pad += "#{padShape} id=\"tool#{tool}pad\""
  if p.hole? then result.pad += " mask=\"url(#tool#{tool}pad_hole)\""
  result.pad += ' />'
  result

circle = (p) ->
  "<circle cx=\"#{p.cx}\" cy=\"#{p.cy}\" r=\"#{p.dia/2}\""

rectangle = (p) ->
  r = "<rect x=\"#{p.cx - p.width/2}\"
         y=\"#{p.cy - p.height/2}\"
         width=\"#{p.width}\"
         height=\"#{p.height}\""
  if p.obround? and p.obround
    radius = 0.5 * Math.min [p.width, p.height]
    r += " rx=\"#{radius}\" ry=\"#{radius}\""
  # return r
  r

module.exports = standardTool
