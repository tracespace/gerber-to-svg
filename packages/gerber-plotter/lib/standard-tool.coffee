# standard tool functions
# functions take an object with tool parameters
# functions return an object with the svg of the pad as an object and the
#   trace stroke properties as an object (or false if tool is untraceable)

# unique number generator to avoid id collisions
unique = require './unique-id'
# standard pad shapes
shapes = require './pad-shapes'

standardTool = (tool, p) ->
  result = {pad: [], trace: false}
  # pad center
  p.cx = 0
  p.cy = 0
  # pad id
  id = "tool-#{tool}-pad-#{unique()}"

  # figure out the tool
  if p.dia? and not p.vertices?
    # we've got a circle tool unless there's confusion
    if p.obround? or p.width? or p.height? or p.degrees?
      throw new Error "#{p} contains invalid tool parameters"

    # get the initial shape of the pad and apply the stroke properties
    shape = 'circle'
    unless p.hole? then result.trace = {
      'stroke-width': p.dia
      fill: 'none'
    }

  else if p.width? and p.height?
    # rectangle or obround tool unless bad params
    if p.dia? or p.vertices? or p.degrees?
      throw new Error "#{p} contains invalid tool parameters"

    shape = 'rect'
    unless p.hole? or p.obround then result.trace = {}

  else if p.dia? and p.vertices?
    # we've got a polygon tool unless there's confusion
    if p.obround? or p.width? or p.height?
      throw new Error "#{p} contains invalid tool parameters"

    shape = 'polygon'

  else
    throw new Error "#{p} contains invalid tool parameters"

  # get the object
  pad = shapes[shape] p

  # mask accordingly if there's a hole
  if p.hole?
    if p.hole.dia? and not p.hole.width? and not p.hole.height?
      hole = shapes.circle { cx: p.cx, cy: p.cy, dia: p.hole.dia }
      hole = hole.shape
      hole.circle.fill = '#000'

    else if p.hole.width? and p.hole.height?
      hole = shapes.rect {
        cx: p.cx, cy: p.cy, width: p.hole.width, height: p.hole.height
      }
      hole = hole.shape
      hole.rect.fill = '#000'

    else
      throw new Error "#{p} contains invalid tool hole parameters"

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
  pad.shape[shape].id = id
  result.pad.push pad.shape
  # set the bbox and id
  result.bbox = pad.bbox
  result.padId = id

  # return the results
  result

module.exports = standardTool
