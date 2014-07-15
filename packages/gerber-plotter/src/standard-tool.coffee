# standard tool functions
# functions take an object with tool parameters
# functions return an object with the svg pad string and the svg stroke properties if applicable

circle = (tool, params) ->
  result = { pad: '', trace: false }
  cx = params.cx ? 0
  cy = params.cy ? 0
  unless params.dia?
    throw new Error "tool #{tool} is missing diameter"
  unless params.dia >= 0
    throw new Error "tool #{tool} cannot have a negative diameter"
  r = params.dia/2
  circ = "<circle cx=\"#{cx}\" cy=\"#{cy}\" r=\"#{r}\""

  if params.hole?
    result.pad += "<mask id=\"tool#{tool}pad_hole\">#{circ} fill=\"#fff\" />"
    if params.hole.dia?
      result.pad += "<circle cx=\"#{cx}\" cy=\"#{cy}\" r=\"#{params.hole.dia/2}\"
                      fill=\"#000\" />"
    else if params.hole.width? and params.hole.height?
      result.pad += "<rect x=\"-#{params.hole.width/2}\"
                      y=\"-#{params.hole.height/2}\"
                      width=\"#{params.hole.width}\"
                      height=\"#{params.hole.height}\"
                      fill=\"#000\" />"
    # close the mask
    result.pad += '</mask>'
  else
    # if there's no hole, then this tool is strokable
    # i.e. can be used to create traces
    result.trace = {
      'stroke-linecap': 'round'
      'stroke-linejoin': 'round'
      'stroke-width': "#{params.dia}"
    }
  # finish the pad string and return the result
  result.pad += "#{circ} id=\"tool#{tool}pad\""
  if params.hole? then result.pad += " mask=\"url(#tool#{tool}pad_hole)\""
  result.pad += ' />'
  result


module.exports = {
  circle: circle
}
