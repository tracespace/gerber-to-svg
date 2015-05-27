# standard tool functions
# functions take an object with tool parameters
# functions return an object with the svg of the pad as an object and the
#   trace stroke properties as an object (or false if tool is untraceable)

# unique number generator to avoid id collisions
unique = require './unique-id'
# standard pad shapes
shapes = require './pad-shapes'

standardTool = (tool, p) ->
  result = { pad: [], trace: false }
  # pad center
  p.cx = 0
  p.cy = 0
  # pad id
  id = "tool-#{tool}-pad-#{unique()}"
  # figure out the tool
  shape = ''
  if p.dia? and not p.vertices?
    # we've got a circle tool unless there's confusion
    if p.obround? or p.width? or p.height? or p.degrees?
      throw new Error "incompatible parameters for tool #{tool}"
    # make sure diamter is in range
    if p.dia < 0
      throw new RangeError "#{tool} circle diameter out of range (#{p.dia}<0)"
    # get the initial shape of the pad and apply the stroke properties
    shape = 'circle'
    unless p.hole? then result.trace = {
      'stroke-width': p.dia
      fill: 'none'
    }

  else if p.width? and p.height?
    # rectangle or obround tool unless bad params
    if p.dia? or p.vertices? or p.degrees?
      throw new Error "incompatible parameters for tool #{tool}"
    # make sure side lengths are in range
    if p.width < 0
      throw new RangeError "#{tool} rect width out of range (#{p.width}<0)"
    if p.height < 0
      throw new RangeError "#{tool} rect height out of range (#{p.height}<0)"
    shape = 'rect'
    # allow zero-size rectangles, but warn and convert them to circles
    if (p.width is 0 or p.height is 0) and not p.obround
      console.warn "zero-size rectangle tools are not allowed;
        converting #{tool} to a zero-size circle"
      shape = 'circle'
      p.dia = 0
    unless p.hole? or p.obround then result.trace = {}

  else if p.dia? and p.vertices?
    # we've got a polygon tool unless there's confusion
    if p.obround? or p.width? or p.height?
      throw new Error "incompatible parameters for tool #{tool}"
    # make sure vertices are in range
    if p.vertices < 3 or p.vertices > 12
      throw new RangeError "#{tool} polygon points out of range
        (#{p.vertices}<3 or >12)]"
    shape = 'polygon'

  else
    throw new Error 'unidentified standard tool shape'

  # get the object
  pad = shapes[shape] p

  # mask accordingly if there's a hole
  if p.hole?
    # check parameters and get shape
    hole = null
    # if it's a circle
    if p.hole.dia? and not p.hole.width? and not p.hole.height?
      unless p.hole.dia >= 0
        throw new RangeError "#{tool} hole diameter out of range
          (#{p.hole.dia}<0)"
      hole = shapes.circle { cx: p.cx, cy: p.cy, dia: p.hole.dia }
      hole = hole.shape
      hole.circle.fill = '#000'
    else if p.hole.width? and p.hole.height?
      unless p.hole.width >= 0
        throw new RangeError "#{tool} hole width out of range
          (#{p.hole.width}<0)"
      unless p.hole.height >= 0
        throw new RangeError "#{tool} hole height out of range
          (#{p.hole.height}<0)"
      hole = shapes.rect {
        cx: p.cx, cy: p.cy, width: p.hole.width, height: p.hole.height
      }
      hole = hole.shape
      hole.rect.fill = '#000'
    else
      throw new Error "#{tool} has invalid hole parameters"

    # generate the mask
    maskId = id + '-mask'
    mask = {
      mask: {
        id: id + '-mask'
        _: [
          {
            rect: {
              x: pad.bbox[0]
              y: pad.bbox[1]
              width: pad.bbox[2] - pad.bbox[0]
              height: pad.bbox[3] - pad.bbox[1]
              fill: '#fff'
            }
          }
          hole
        ]
      }
    }

    # set the mask
    pad.shape[shape].mask = "url(##{maskId})"
    result.pad.push mask

  # set the id and push the shape to the array
  if id then pad.shape[shape].id = id
  result.pad.push pad.shape
  # set the bbox and id
  result.bbox = pad.bbox
  result.padId = id

  # return the results
  result

module.exports = standardTool
