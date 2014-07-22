# standard tool functions
# functions take an object with tool parameters
# functions return an object with the svg of the pad as an object and the
#   trace stroke properties as an object (or false if tool is untraceable)


circle = (p) ->
  { circle: { _attr: { cx: "#{p.cx}", cy: "#{p.cy}", r: "#{p.dia/2}" } } }

rectangle = (p) ->
  r = {
    rect: {
      _attr: {
        x:      "#{p.cx - p.width/2}"
        y:      "#{p.cy - p.height/2}"
        width:  "#{p.width}"
        height: "#{p.height}"
      }
    }
  }

  if p.obround
    radius = 0.5 * Math.min p.width, p.height
    r.rect._attr.rx = "#{radius}"
    r.rect._attr.ry = "#{radius}"
  # return r
  r

# regular polygon
polygon = (p) ->
  start = if p.degrees? then p.degrees * Math.PI/180 else 0
  step = 2*Math.PI / p.verticies
  r = p.dia / 2
  points = ''
  # loop over the verticies and add them to the points string
  for i in [0...p.verticies]
    theta = start + i*step
    points += " #{p.cx+r*Math.cos theta},#{p.cy+r*Math.sin theta}"
  # return polygon object
  { polygon: { _attr: { points: points[1..] } } }


# map standard shapes to functions
shapeMap = {
  circle: circle
  rect: rectangle
  polygon: polygon
}

standardTool = (p, tool) ->
  result = { pad: {}, trace: false }
  # pad center
  p.cx = p.cx ? 0
  p.cy = p.cy ? 0
  # pad id
  id = if tool then "tool-#{tool}-pad" else false
  # figure out the tool
  shape = ''
  if p.dia? and not p.verticies?
    # we've got a circle tool unless there's confusion
    if p.obround? or p.width? or p.height? or p.degrees?
      throw new Error "incompatible parameters for tool #{tool}"
    # make sure diamter is in range
    if p.dia < 0
      throw new RangeError "#{tool} circle diameter out of range (#{p.dia}<0)"
    # get the initial shape of the pad and apply the stroke properties
    shape = 'circle'
    unless p.hole? then result.trace = {
      'stroke-linecap': 'round'
      'stroke-linejoin': 'round'
      'stroke-width': "#{p.dia}"
    }

  else if p.width? and p.height?
    # rectangle or obround tool unless bad params
    if p.dia? or p.verticies? or p.degrees?
      throw new Error "incompatible parameters for tool #{tool}"
    # make sure side lengths are in range
    if p.width <= 0
      throw new RangeError "#{tool} rect width out of range (#{p.width}<=0)"
    if p.height <= 0
      throw new RangeError "#{tool} rect height out of range (#{p.height}<=0)"
    shape = 'rect'
    unless p.hole? or p.obround then result.trace = { 'stroke-width': '0' }

  else if p.dia? and p.verticies?
    # we've got a polygon tool unless there's confusion
    if p.obround? or p.width? or p.height?
      throw new Error "incompatible parameters for tool #{tool}"
    # make sure verticies are in range
    if p.verticies < 3 or p.verticies > 12
      throw new RangeError "#{tool} polygon points out of range (#{p.verticies}<3 or >12)]"
    shape = 'polygon'

  else
    throw new Error 'unidentified standard tool shape'

  # get the object
  result.pad = shapeMap[shape] p
  # set the id
  if id then result.pad[shape]._attr.id = id
  # return the results
  result

  # apply the hole if necessary
  # if p.hole?
  #   result.pad += "<mask id=\"#{tool}-pad_hole\">#{padShape} fill=\"#fff\" />"
  #   if p.hole.dia? and not p.hole.width? and not p.hole.height?
  #     unless p.hole.dia >= 0
  #       throw new RangeError '#{tool} hole diameter out of range (#{p.hole.dia}<0)'
  #     result.pad += circle { dia: p.hole.dia, cx: p.cx, cy: p.cy }
  #   else if p.hole.width? and p.hole.height?
  #     unless p.hole.width >= 0
  #       throw new RangeError '#{tool} hole width out of range (#{p.hole.width}<0)'
  #     unless p.hole.height >= 0
  #       throw new RangeError '#{tool} hole height out of range (#{p.hole.height}<0)'
  #     result.pad += rectangle {
  #       cx: p.cx
  #       cy: p.cy
  #       width: p.hole.width
  #       height: p.hole.height
  #     }
  #   else
  #     throw new Error "#{tool} has invalid hole parameters"
  #   # close the mask
  #   result.pad += ' fill="#000" /></mask>'
  #
  # # finsish the pad string, and add mask url if necessary
  # result.pad += "#{padShape} id=\"tool#{tool}pad\""
  # if p.hole? then result.pad += " mask=\"url(#tool#{tool}pad_hole)\""
  # result.pad += ' />'
  #result

module.exports = standardTool
