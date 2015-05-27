# aperture macro class
# parses an aperture macro and then returns the pad when the tool is defined

# uses the pad shapes functions
shapes = require './pad-shapes'
# calculator parsing for macro arithmetic
calc = require './macro-calc'
# unique id generator
unique = require './unique-id'
# integer coordinate caluclator
getSvgCoord = require('./svg-coord').get

class MacroTool
  # constructor takes in macro blocks
  constructor: (blocks, numberFormat) ->
    # macro modifiers
    @modifiers = {}
    # block 0 is going to be AMmacroname
    @name = blocks[0][2..]
    # save the rest of the blocks
    @blocks = blocks[1..]
    # array of shape objects
    @shapes = []
    # array of mask objects
    @masks = []
    # last exposure used
    @lastExposure = null
    # bounding box [xMin, yMin, xMax, yMax] of macro
    @bbox = [ null, null, null, null ]
    # format for coordinate and size values
    @format = { places: numberFormat }

  # run the macro and return the pad
  run: (tool, modifiers = []) ->
    # make everything is cleared out
    @lastExposure = null
    @shapes = []
    @masks = []
    @bbox = [ null, null, null, null ]
    @modifiers = {}
    @modifiers["$#{i+1}"] = m for m, i in modifiers
    # run the blocks
    @runBlock b for b in @blocks
    # generate an id for the pad
    padId = "tool-#{tool}-pad-#{unique()}"
    pad = []
    # get all the masks together first
    pad.push m for m in @masks
    # bundle the shapes if necessary
    if @shapes.length > 1
      group = { id: padId, _: [] }
      group._.push s for s in @shapes
      pad = [ { g: group } ]
    else if @shapes.length is 1
      shape = Object.keys(@shapes[0])[0]
      @shapes[0][shape].id = padId
      pad.push @shapes[0]
    # return the pad, the bbox, and the pad id
    {
      pad: pad
      padId: padId
      bbox: @bbox
      trace: false
    }

  # run a block and return the modified pad string
  runBlock: (block) ->
    # check the first character of the block
    switch block[0]
      # if we got ourselves a modifier, we should set it
      when '$'
        mod = block.match(/^\$\d+(?=\=)/)?[0]
        val = block[(1 + mod.length)..]
        @modifiers[mod] = @getNumber val
      # or it's a primitive
      when '1', '2', '20', '21', '22', '4', '5', '6', '7'
        # split string at commas for arguments
        args = block.split ','
        # get the actual numbers and pass to the primitive method
        args[i] = @getNumber a for a,i in args
        @primitive args
      else
        # throw an error because I don't know what's going on
        # unless it's a comment; in that case carry on
        unless block[0] is '0'
          throw new Error "'#{block}' unrecognized tool macro block"

  # identify the primitive and add shapes and masks to the macro
  primitive: (args) ->
    mask = false
    rotation = false
    shape = null
    switch args[0]
      # circle primitive
      when 1
        shape = shapes.circle {
          dia: getSvgCoord args[2], @format
          cx:  getSvgCoord args[3], @format
          cy:  getSvgCoord args[4], @format
        }
        if args[1] is 0 then mask = true else @addBbox shape.bbox
      # vector line primitive
      when 2, 20
        shape = shapes.vector {
          width: getSvgCoord args[2], @format
          x1:    getSvgCoord args[3], @format
          y1:    getSvgCoord args[4], @format
          x2:    getSvgCoord args[5], @format
          y2:    getSvgCoord args[6], @format
        }
        # rotate if necessary
        if args[7] then shape.shape.line.transform = "rotate(#{args[7]})"
        # add the bounding box with rotation
        if args[1] is 0 then mask = true else @addBbox shape.bbox, args[7]
      when 21
        shape = shapes.rect {
          cx:     getSvgCoord args[4], @format
          cy:     getSvgCoord args[5], @format
          width:  getSvgCoord args[2], @format
          height: getSvgCoord args[3], @format
        }
        # rotate if necessary
        if args[6] then shape.shape.rect.transform = "rotate(#{args[6]})"
        if args[1] is 0 then mask = true else @addBbox shape.bbox, args[6]
      when 22
        shape = shapes.lowerLeftRect {
          x:      getSvgCoord args[4], @format
          y:      getSvgCoord args[5], @format
          width:  getSvgCoord args[2], @format
          height: getSvgCoord args[3], @format
        }
        # rotate if necessary
        if args[6] then shape.shape.rect.transform = "rotate(#{args[6]})"
        if args[1] is 0 then mask = true else @addBbox shape.bbox, args[6]
      when 4
        points = []
        for i in [ 3..(3 + 2 * args[2]) ] by 2
          points.push [
            getSvgCoord(args[i], @format), getSvgCoord(args[i + 1], @format)
          ]
        shape = shapes.outline { points: points }
        # rotate if necessary
        if rot = args[args.length - 1]
          shape.shape.polygon.transform = "rotate(#{rot})"
        if args[1] is 0 then mask = true
        else @addBbox shape.bbox, args[args.length - 1]
      when 5
        # rotation only allowed if center is on the origin
        if args[6] isnt 0 and (args[3] isnt 0 or args[4] isnt 0)
          throw new RangeError 'polygon center must be 0,0 if rotated in macro'
        shape = shapes.polygon {
          cx:  getSvgCoord args[3], @format
          cy:  getSvgCoord args[4], @format
          dia: getSvgCoord args[5], @format
          vertices: args[2]
          degrees: args[6]
        }
        if args[1] is 0 then mask = true else @addBbox shape.bbox
      # moire
      when 6
        # rotation only allowed if center is on the origin
        if args[9] isnt 0 and (args[1] isnt 0 or args[2] isnt 0)
          throw new RangeError 'moiré center must be 0,0 if rotated in macro'
        shape = shapes.moire {
          cx:          getSvgCoord args[1], @format
          cy:          getSvgCoord args[2], @format
          outerDia:    getSvgCoord args[3], @format
          ringThx:     getSvgCoord args[4], @format
          ringGap:     getSvgCoord args[5], @format
          maxRings:    args[6]
          crossThx:    getSvgCoord args[7], @format
          crossLength: getSvgCoord args[8], @format
        }
        # rotate the crosshairs
        if args[9] then for s in shape.shape
          if s.line? then s.line.transform = "rotate(#{args[9]})"
        @addBbox shape.bbox, args[9]
      # thermal
      when 7
        # rotation only allowed if center is on the origin
        if args[9] isnt 0 and (args[1] isnt 0 or args[2] isnt 0)
          throw new RangeError 'thermal center must be 0,0 if rotated in macro'
        shape = shapes.thermal {
          cx:       getSvgCoord args[1], @format
          cy:       getSvgCoord args[2], @format
          outerDia: getSvgCoord args[3], @format
          innerDia: getSvgCoord args[4], @format
          gap:      getSvgCoord args[5], @format
        }
        # rotate and adjust bounding box
        if args[6] then for s in shape.shape
          if s.mask? then for m in s.mask._
            if m.rect? then m.rect.transform = "rotate(#{args[6]})"
        @addBbox shape.bbox, args[6]
      else
        throw new Error "#{args[0]} is not a valid primitive code"

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
        # push the mask to the masks list
        @masks.push m
      # add our shape to the current mask
      @masks[@masks.length - 1].mask._.push shape.shape
    # if exposure was on, continue about our merry business
    else
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
    # normal number all by itself
    if s.match /^[+-]?[\d.]+$/ then Number s
    # modifier all by its lonesome
    else if s.match /^\$\d+$/ then Number @modifiers[s]
    # else we got us some maths
    else @evaluate calc.parse s

  # evaluate a math string
  evaluate: (op) ->
    switch op.type
      when 'n' then @getNumber op.val
      when '+' then @evaluate(op.left) + @evaluate(op.right)
      when '-' then @evaluate(op.left) - @evaluate(op.right)
      when 'x' then @evaluate(op.left) * @evaluate(op.right)
      when '/' then @evaluate(op.left) / @evaluate(op.right)

module.exports = MacroTool
