# shape functions for standard apertures and aperture macros
# returns an array of shape objects and the bounding box of the shape

circle = (p) ->
  unless p.dia? then throw new SyntaxError 'circle function requires diameter'
  unless p.cx? then throw new SyntaxError 'circle function requires x center'
  unless p.cy? then throw new SyntaxError 'circle function requires y center'

  r = p.dia/2
  {
    shape: {
      circle: {
        _attr: { cx: "#{p.cx}", cy: "#{p.cy}", r: "#{r}" }
      }
    }
    bbox: [ p.cx - r, p.cy - r, p.cx + r, p.cy + r ]
  }

rect = (p) ->
  unless p.width? then throw new SyntaxError 'rectangle requires width'
  unless p.height? then throw new SyntaxError 'rectangle requires height'
  unless p.cx? then throw new SyntaxError 'rectangle function requires x center'
  unless p.cy? then throw new SyntaxError 'rectangle function requires y center'

  x = p.cx - p.width/2
  y = p.cy - p.height/2
  rectangle = {
    shape: {
      rect: {
        _attr: {
          x:      "#{x}"
          y:      "#{y}"
          width:  "#{p.width}"
          height: "#{p.height}"
        }
      }
    }
    bbox: [ x, y, x + p.width, y + p.height ]
  }

  if p.obround
    radius = 0.5 * Math.min p.width, p.height
    rectangle.shape.rect._attr.rx = "#{radius}"
    rectangle.shape.rect._attr.ry = "#{radius}"
  # return pad object
  rectangle

# regular polygon
polygon = (p) ->
  unless p.dia? then throw new SyntaxError 'polygon requires diameter'
  unless p.verticies? then throw new SyntaxError 'polygon requires verticies'
  unless p.cx? then throw new SyntaxError 'polygon function requires x center'
  unless p.cy? then throw new SyntaxError 'polygon function requires y center'

  start = if p.degrees? then p.degrees * Math.PI/180 else 0
  step = 2*Math.PI / p.verticies
  r = p.dia / 2
  points = ''
  xMin = null
  yMin = null
  xMax = null
  yMax = null
  # loop over the verticies and add them to the points string
  for i in [0...p.verticies]
    theta = start + i*step
    x = p.cx + r*Math.cos theta
    y = p.cy + r*Math.sin theta
    if x < xMin or xMin is null then xMin = x
    if x > xMax or xMax is null then xMax = x
    if y < yMin or yMin is null then yMin = y
    if y > yMax or yMax is null then yMax = y
    points += " #{x},#{y}"
  # return polygon object
  {
    shape: { polygon: { _attr: { points: points[1..] } } }
    bbox: [ xMin, yMin, xMax, yMax ]
  }

vector = (p) ->
  unless p.x1? then throw new SyntaxError 'vector function requires start x'
  unless p.y1? then throw new SyntaxError 'vector function requires start y'
  unless p.x2? then throw new SyntaxError 'vector function requires end x'
  unless p.y2? then throw new SyntaxError 'vector function requires end y'
  unless p.width? then throw new SyntaxError 'vector function requires width'

  # get angle of the line for the bounding box
  theta = Math.abs Math.atan (p.y2 - p.y1)/(p.x2 - p.x1)
  xDelta = p.width / 2 * Math.sin theta
  yDelta = p.width / 2 * Math.cos theta
  # fix some edge cases
  if xDelta < 0.0000001 then xDelta = 0
  if yDelta < 0.0000001 then yDelta = 0
  # return the object
  {
    shape: {
      line: {
        _attr: {
          x1: "#{p.x1}"
          x2: "#{p.x2}"
          y1: "#{p.y1}"
          y2: "#{p.y2}"
          'stroke-width': "#{p.width}"
        }
      }
    }
    bbox: [
      (Math.min p.x1, p.x2) - xDelta
      (Math.min p.y1, p.y2) - yDelta
      (Math.max p.x1, p.x2) + xDelta
      (Math.max p.y1, p.y2) + yDelta
    ]
  }

# export
module.exports = {
  circle: circle
  rect: rect
  polygon: polygon
  vector: vector
}
