# aperture macro class
# parses an aperture macro and then returns the pad when the tool is defined
EventEmitter = require('events').EventEmitter

mapValues = require 'lodash.mapvalues'
find = require 'lodash/collection/find' # TODO: replace with module
filter = require 'lodash.filter'
omit = require 'lodash.omit'

# uses the pad shapes functions
shapes = require './pad-shapes'
# calculator parsing for macro arithmetic
calc = require './macro-calc'
# unique id generator
unique = require './unique-id'
# integer coordinate caluclator
getSvgCoord = require('./svg-coord').get
# warning object
Warning = require './warning'

class MacroTool extends EventEmitter
  # constructor takes in macro blocks
  constructor: (@blocks = [], numberFormat) ->
    # macro modifiers
    @modifiers = {}
    # array of shape objects
    @shapes = []
    # array of mask objects
    @masks = []
    # last exposure used
    @lastExposure = null
    # bounding box [xMin, yMin, xMax, yMax] of macro
    @bbox = [null, null, null, null]
    # format for coordinate and size values
    @format = {places: numberFormat}

  # run the macro and return the pad
  run: (tool, modifiers = []) ->
    # make everything is cleared out
    @lastExposure = null
    @shapes = []
    @masks = []
    @bbox = [null, null, null, null]
    @modifiers = {}
    @modifiers["$#{i+1}"] = m for m, i in modifiers

    # run the blocks
    for b in @blocks
      if b.shape?
        @primitive b
      else
        @modifiers[b.modifier] = @getNumber b.value

    # gather the shapes into a pad array
    if @shapes.length is 1
      pad = @shapes
    else if @shapes.length > 1
      pad = [{g: {_: @shapes}}]

    # generate an id for the pad
    padId = "tool-#{tool}-pad-#{unique()}"
    if pad?
      shape = Object.keys(pad[0])[0]
      pad[0][shape].id = padId

    # put all the masks at the front of the pad array
    pad.unshift m for m in @masks

    # return the pad, the bbox, and the pad id
    {
      pad: pad
      padId: padId
      bbox: @bbox
      trace: false
    }

  # identify the primitive and add shapes and masks to the macro
  primitive: (p) ->
    mask = false
    rotation = false
    shapeType = p.shape
    mask = if p.exp? then @getNumber(p.exp) is 0

    # some keys are just numbers, (i.e. not dimensions in svg coordinates)
    vertices = if p.vertices? then @getNumber p.vertices, @format
    rotation = if p.rot? then @getNumber p.rot
    maxRings = if p.maxRings? then @getNumber p.maxRings

    # other keys we need to call get the number in svg coordinates
    p = mapValues (omit p, ['shape', 'exp', 'rot', 'maxRings']), (value) =>
      if Array.isArray value
        value = @getNumber value
        (getSvgCoord v, @format for v in value)
      else
        getSvgCoord @getNumber(value), @format

    switch shapeType
      when 'circle'
        shape = shapes.circle {dia: p.dia, cx: p.cx, cy: p.cy}

      when 'vector'
        shape = shapes.vector {
          width: p.width, x1: p.x1, y1: p.y1, x2: p.x2, y2: p.y2
        }
        if rotation then shape.shape.line.transform = "rotate(#{rotation})"

      when 'rect'
        shape = shapes.rect {
          width: p.width, height: p.height, cx: p.cx, cy: p.cy
        }
        if rotation then shape.shape.rect.transform = "rotate(#{rotation})"

      when 'lowerLeftRect'
        shape = shapes.lowerLeftRect {
          width: p.width, height: p.height, x: p.x, y: p.y
        }
        if rotation then shape.shape.rect.transform = "rotate(#{rotation})"

      when 'outline'
        shape = shapes.outline {points: p.points}
        if rotation then shape.shape.polygon.transform = "rotate(#{rotation})"

      when 'polygon'
        # check to make sure we're allowed to rotate
        if rotation and (p.cx isnt 0 or p.cy isnt 0)
          @emit 'warning', new Warning '''
            a macro polygon can only be rotated if its center is at 0, 0
          '''
          rotation = 0

        shape = shapes.polygon {
          vertices: vertices, cx: p.cx, cy: p.cy, dia: p.dia, degrees: rotation
        }
        # reset rotation so we don't mess up the bbox
        rotation = 0

      when 'moire'
        shape = shapes.moire {
          cx: p.cx, cy: p.cy, outerDia: p.outerDia
          ringThx: p.ringThx, ringGap: p.ringGap, maxRings: maxRings
          crossThx: p.crossThx, crossLength: p.crossLength
        }
        if rotation
          if p.cx isnt 0 or p.cy isnt 0
            @emit 'warning', new Warning '''
              a macro moiré can only be rotated if its center is at 0, 0
            '''
            rotation = 0
          else
            lines = filter shape.shape, 'line'
            obj.line.transform = "rotate(#{rotation})" for obj in lines

      when 'thermal'
        shape = shapes.thermal {
          cx: p.cx, cy: p.cy
          outerDia: p.outerDia, innerDia: p.innerDia, gap: p.gap
        }
        if rotation
          if p.cx isnt 0 or p.cy isnt 0
            @emit 'warning', new Warning '''
              a macro thermal can only be rotated if its center is at 0, 0
            '''
            rotation = 0
          else
            thermalMask = find shape.shape, 'mask'
            rects = filter thermalMask.mask._, 'rect'
            obj.rect.transform = "rotate(#{rotation})" for obj in rects

    # now, we need to check our exposure
    if mask
      # adjust the fill of our shape to white
      shape.shape[key].fill = '#000' for key of shape.shape
      # if necessary, create a new mask
      if @lastExposure isnt 0
        @lastExposure = 0
        maskId = "macro-#{@name}-mask-#{unique()}"
        m = { mask: { id: maskId } }
        m.mask._ = [
          {
            rect: {
              x: @bbox[0]
              y: @bbox[1]
              width: @bbox[2] - @bbox[0]
              height: @bbox[3] - @bbox[1]
              fill: '#fff'
            }
          }
        ]
        # mask off existing shapes
        # check if we need to bundle
        if @shapes.length is 1
          @shapes[0][key].mask = "url(##{maskId})" for key of @shapes[0]
        else if @shapes.length > 1
          group = { mask: "url(##{maskId})", _: [] }
          group._.push s for s in @shapes
          @shapes = [ { g: group } ]
        else
          # if the shapes array is empty, then there's nothing to see here
          return

        # push the mask to the masks list
        @masks.push m
      # add our shape to the current mask
      @masks[@masks.length - 1].mask._.push shape.shape
    # if exposure was on, continue about our merry business
    else
      @addBbox shape.bbox, rotation
      @lastExposure = 1
      unless Array.isArray shape.shape then @shapes.push shape.shape
      else
        for s in shape.shape
          if s.mask? then @masks.push s else @shapes.push s

  # add a new bbox to the macro's exsisting bbox
  addBbox: (bbox, rotation = 0) ->
    unless rotation
      if @bbox[0] is null or bbox[0] < @bbox[0] then @bbox[0] = bbox[0]
      if @bbox[1] is null or bbox[1] < @bbox[1] then @bbox[1] = bbox[1]
      if @bbox[2] is null or bbox[2] > @bbox[2] then @bbox[2] = bbox[2]
      if @bbox[3] is null or bbox[3] > @bbox[3] then @bbox[3] = bbox[3]
    # else if it's rotated, we're going to have to compensate
    else
      # get ready for some trig
      s = Math.sin(rotation * Math.PI / 180)
      c = Math.cos(rotation * Math.PI / 180)
      if Math.abs(s) < 0.000000001 then s = 0
      if Math.abs(c) < 0.000000001 then c = 0
      # get the points of the rectangle
      points = [
        [bbox[0],bbox[1]]
        [bbox[2],bbox[1]]
        [bbox[2],bbox[3]]
        [bbox[0],bbox[3]]
      ]
      # rotate and update
      for p in points
        x = (p[0] * c) - (p[1] * s)
        y = (p[0] * s) + (p[1] * c)
        if @bbox[0] is null or x < @bbox[0] then @bbox[0] = x
        if @bbox[1] is null or y < @bbox[1] then @bbox[1] = y
        if @bbox[2] is null or x > @bbox[2] then @bbox[2] = x
        if @bbox[3] is null or y > @bbox[3] then @bbox[3] = y
      # clear out any -0s for better svg output and tests
      @bbox = ((if b is -0 then 0 else b) for b in @bbox)

  # parse a number in the format of a float string, a modifier, or a math string
  getNumber: (s) ->
    # if s is an array, get all the numbers in the array
    if Array.isArray s
      (@getNumber e for e in s)
    # normal number all by itself
    else if s.match /^[+-]?[\d.]+$/
      Number s
    # modifier all by its lonesome
    else if s.match /^\$\d+$/
      @modifiers[s]
    # else we got us some maths
    else
      @evaluate calc.parse s

  # evaluate a math string
  evaluate: (op) ->
    switch op.type
      when 'n' then @getNumber op.val
      when '+' then @evaluate(op.left) + @evaluate(op.right)
      when '-' then @evaluate(op.left) - @evaluate(op.right)
      when 'x' then @evaluate(op.left) * @evaluate(op.right)
      when '/' then @evaluate(op.left) / @evaluate(op.right)

module.exports = MacroTool
