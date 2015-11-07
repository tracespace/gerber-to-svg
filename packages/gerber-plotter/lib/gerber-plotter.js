// gerber plotter
'use strict'

var TransformStream = require('readable-stream').Transform
var has = require('lodash.has')
var mapValues = require('lodash.mapValues')

var PathGraph = require('./path-graph')
var applyOptions = require('./_apply-options')
var warning = require('./_warning')
var padShape = require('./_pad-shape')
var operate = require('./_operate')
var boundingBox = require('./_box')

var isFormatKey = function(key) {
  return (
    key === 'units' ||
    key === 'backupUnits' ||
    key === 'nota' ||
    key === 'backupNota')
}

var _finishPath = function() {
  if (this._path.length) {
    var path = this._path.traverse()
    this._path = new PathGraph()

    if (!this._region && (this._tool.trace.length === 1)) {
      this.push({type: 'stroke', width: this._tool.trace[0], path: path})
    }
    else {
      this.push({type: 'fill', path: path})
    }
  }
}

var _transform = function(chunk, encoding, done) {
  var cmd = chunk.cmd
  var line = chunk.line
  var key = chunk.key
  var val = chunk.val

  if (this._done) {
    this.emit(
      'warning',
      warning('ignoring extra command recieved after done command', line))

    return done()
  }

  // check for an operation
  if (cmd === 'op') {
    if (this.nota === 'I') {
      val = mapValues(val, function(value, key) {
        if (key === 'x') {
          return (this._pos[0] + value)
        }
        if (key === 'y') {
          return (this._pos[1] + value)
        }

        return value
      }, this)
    }

    var result = operate(
      key,
      val,
      this._pos,
      this._tool,
      this._mode,
      this._arc,
      this._region,
      this._path,
      this._epsilon,
      this)

    this._pos = result.pos
    this._box = boundingBox.add(this._box, result.box)
  }

  else if (cmd === 'set') {
    // if region change, finish the path
    if (key === 'region') {
      this._finishPath()
      this._region = val
    }

    // else we might need to set the format
    else if (isFormatKey(key) && !this._formatLock[key]) {
      this.format[key] = val
      if (key === 'units' || key === 'nota') {
        this._formatLock[key] = true
      }
    }

    // else if we're dealing with a tool change, finish the path and change
    else if (key === 'tool') {
      if (this._region) {
        this.emit('warning', warning('cannot change tool while region mode is on', line))
      }
      else if (!has(this._tools, val)) {
        this.emit('warning', warning('tool ' + val + ' is not defined', line))
      }
      else {
        this._finishPath()
        this._tool = this._tools[val]
      }
    }

    // else set interpolation or arc mode
    else {
      this['_' + key] = val
    }
  }

  // else tool commands
  else if (cmd === 'tool') {
    if (this._tools[key]) {
      this.emit(
        'warning',
        warning('tool ' + key + ' is already defined; ignoring new definition', line))

      return done()
    }

    var shapeAndBox = padShape(val, this._macros)
    var tool = {
      code: key,
      trace: [],
      pad: shapeAndBox.shape,
      flashed: false,
      box: shapeAndBox.box
    }

    if (val.shape === 'circle' || val.shape === 'rect') {
      if (val.hole.length === 0) {
        tool.trace = val.val
      }
    }

    this._finishPath()
    this._tools[key] = tool
    this._tool = tool
  }

  // else macro command
  else if (cmd === 'macro') {
    // save the macro
    this._macros[key] = val
  }

  // else layer command
  else if (cmd === 'layer') {
    this._finishPath()
  }

  // else done command
  else if (cmd === 'done') {
    this._done = true
  }

  return done()
}

var plotter = function(options) {
  var stream = new TransformStream({
    readableObjectMode: true,
    writableObjectMode: true
  })

  stream._transform = _transform
  stream._finishPath = _finishPath

  stream.format = {
    units: null,
    backupUnits: 'in',
    nota: null,
    backupNota: 'A'
  }

  stream._formatLock = {
    units: false,
    backupUnits: false,
    nota: false,
    backupNota: false
  }

  stream._done = false
  stream._tool = null
  stream._tools = {}
  stream._macros = {}
  stream._pos = [0, 0]
  stream._box = boundingBox.new()
  stream._mode = null
  stream._arc = null
  stream._region = false
  stream._path = new PathGraph()
  stream._epsilon = null

  applyOptions(options, stream.format, stream._formatLock)
  return stream
}

module.exports = plotter

// # is a transform stream
// TransformStream = require('stream').Transform
// # warning object
// Warning = require './warning'
// # unique id generator
// unique = require './unique-id'
// # aperture macro class
// Macro = require './macro-tool'
// # standard tool functions
// tool = require './standard-tool'
// # coordinate scale factor
// coordFactor = require('./svg-coord').factor
//
// # constants
// HALF_PI = Math.PI / 2
// THREEHALF_PI = 3 * HALF_PI
// TWO_PI = 2 * Math.PI
// # assumed format
// ASSUMED_UNITS = 'in'
//
// # bounding box helper function
// addBbox = (bbox, target) ->
//   if bbox.xMin < target.xMin then target.xMin = bbox.xMin
//   if bbox.yMin < target.yMin then target.yMin = bbox.yMin
//   if bbox.xMax > target.xMax then target.xMax = bbox.xMax
//   if bbox.yMax > target.yMax then target.yMax = bbox.yMax
//
// class Plotter extends TransformStream
//   constructor: (opts = {}) ->
//     @units = opts.units
//     @notation = opts.notation
//
//     # defined tools and macros
//     @tools = {}
//     @macros = {}
//
//     # layer properties
//     @stepRepeat = {x: 1, y: 1, i: 0, j: 0}
//
//     # plotter state variables
//     @x = 0
//     @y = 0
//     @firstOperation = true
//
//     # current image
//     @polarity = 'D'
//     @defs = []
//     @current = []
//     @layerBbox = {
//       xMin: Infinity
//       yMin: Infinity
//       xMax: -Infinity
//       yMax: -Infinity
//     }
//
//     # step and repeat, initially set to no repeat
//     @stepRepeat = { x: 1, y: 1, i: 0, j: 0 }
//     @srOverClear = false
//     @srOverCurrent = []
//
//     # current trace and group
//     @path = []
//     @group = {g: {_: []}}
//
//     # overall image
//     @bbox = {
//       xMin: Infinity
//       yMin: Infinity
//       xMax: -Infinity
//       yMax: -Infinity
//     }
//
//     # object mode transform
//     super {objectMode: true}
//
//   # main transform method; called on incoming parser objects
//   _transform: (chunk, encoding, done) ->
//     # check for different commands
//     if chunk.set?
//       @handleSet chunk.set, chunk.line, done
//     else if chunk.new?
//       @handleNew chunk.new, chunk.line, done
//     else if chunk.tool?
//       @handleTool chunk.tool, chunk.line, done
//     else if chunk.macro?
//       @handleMacro chunk.macro, chunk.line, done
//     else if chunk.op?
//       @handleOperation chunk.op, chunk.line, done
//     else
//       done()
//
//   # this is called when the incoming stream ends
//   _flush: (done) ->
//     # finish the plot
//     @finish()
//
//     # get image dimensions
//     unless @group.g._.length
//       @bbox = {xMin: 0, yMin: 0, xMax: 0, yMax: 0}
//     else
//       children = [
//         {defs: {_: @defs}}
//         @group
//       ]
//
//     width = @bbox.xMax - @bbox.xMin
//     height = @bbox.yMax - @bbox.yMin
//
//     # create an xml object
//     xml = {
//       svg: {
//         xmlns: 'http://www.w3.org/2000/svg'
//         version: '1.1'
//         'xmlns:xlink': 'http://www.w3.org/1999/xlink'
//         width: "#{width / coordFactor}#{@units}"
//         height: "#{height / coordFactor}#{@units}"
//         viewBox: [@bbox.xMin, @bbox.yMin, width, height]
//         'stroke-linecap': 'round'
//         'stroke-linejoin': 'round'
//         'stroke-width': 0
//         stroke: '#000'
//         _: children ? []
//       }
//     }
//
//     # push it and we're done
//     @push xml
//
//     done()
//
//   # handle a set command to set the plotter's state as required
//   handleSet: (set, line, done) ->
//     for state, val of set
//       # if setting current tool, make sure it exists and region mode is off
//       if state is 'currentTool'
//         unless @tools[val]?
//           @emit 'warning', new Warning("tool #{val} is undefined", line)
//         if @region
//           return done new Error """
//             line #{line} - cannot change tool while region mode is on
//           """
//
//         # if all is good, change the tool
//         @changeTool val
//
//       # units and notation should not be overridden if already defined
//       else if state is 'units' or state is 'backupUnits' or state is 'notation'
//         @[state] ?= val
//       # everything else just sets the property
//       else
//         # finish any in progress path if we're changing region mode
//         if state is 'region' then @finishPath()
//
//         @[state] = val
//
//     done()
//
//   # handle new layer commands
//   handleNew: (newLayer, line, done) ->
//     # finish the current layer before
//     @finishLayer()
//
//     # handle a new layer accordingly
//     if newLayer.sr?
//       @finishSR()
//       @stepRepeat = newLayer.sr
//     else if newLayer.layer?
//       @polarity = newLayer.layer
//     else
//       throw new Error "#{newLayer} is a poorly formatted or unknown new command"
//
//     done()
//
//   # add a tool to the tool list
//   handleTool: (toolCommand, line, done) ->
//     code = Object.keys(toolCommand)[0]
//     params = toolCommand[code]
//
//     if @tools[code]?
//       return done new Error "line #{line} - tool #{code} was previously defined"
//
//     if params.macro?
//       macro = @macros[params.macro]
//       handleMacroRunWarning = (w) =>
//         w.message = """
//           warning from macro #{params.macro} run at line #{line} - #{w.message}
//         """
//         @emit 'warning', w
//
//       macro.on 'warning', handleMacroRunWarning
//       t = macro.run code, params.mods
//       macro.removeListener 'warning', handleMacroRunWarning
//
//     else
//       t = tool code, params
//
//     # set the object in the tools collection
//     @tools[code] = {
//       code: code
//       trace: t.trace
//       pad: t.pad
//       flash: (x, y) -> {use: {x: x, y: y, 'xlink:href': "##{t.padId}"}}
//       flashed: false
//       bbox: (x = 0, y = 0) -> {
//         xMin: x + t.bbox[0]
//         yMin: y + t.bbox[1]
//         xMax: x + t.bbox[2]
//         yMax: y + t.bbox[3]
//       }
//     }
//
//     # set the current tool to the one just defined and finish
//     @changeTool code
//     done()
//
//   # handle a new macro command
//   handleMacro: (macroCommand, line, done) ->
//     name = Object.keys(macroCommand)[0]
//     blocks = macroCommand[name]
//     macro = new Macro blocks
//     @macros[name] = macro
//     done()
//
//   # chenge the current tool
//   changeTool: (code) ->
//     # end the current path before changing the tool
//     @finishPath()
//
//     @currentTool = @tools[code]
//
//   prepareForFirstOperation: (line) ->
//     @firstOperation = false
//
//     unless @units?
//       msg = "line #{line} - "
//       if @backupUnits?
//         @units = @backupUnits
//         msg += "units set to #{@units} by deprecated G70/1"
//       else
//         @units = ASSUMED_UNITS
//         msg += "no units set before first move; assuming #{ASSUMED_UNITS}"
//
//       @emit 'warning', new Warning msg
//
//     unless @notation?
//       @notation = 'A'
//       msg = "line #{line} - no coordinate notation set before first move;
//         assuming absolute"
//
//       @emit 'warning', new Warning msg
//
//   handleOperation: (operation, line, done) ->
//     # do a check for units and notation (ensures format is properly set)
//     if @firstOperation then @prepareForFirstOperation line
//
//     # move the plotter position
//     sX = @x
//     sY = @y
//     if @notation is 'I'
//       operation.x = (operation.x ? 0) + @x
//       operation.y = (operation.y ? 0) + @y
//     @x = operation.x ? @x
//     @y = operation.y ? @y
//
//     # handle modal operation codes, despite the fact that the are deprecated
//     if operation.do is 'last'
//       @emit 'warning', new Warning "line #{line} - modal operation codes are
//         deprecated and not guarenteed to render properly"
//       operation.do = @lastOperation
//     else
//       @lastOperation = operation.do
//
//     if operation.do is 'flash'
//       # # check that region mode isn't on
//       if @region
//         return done new Error "line #{line} - cannot flash while in region mode"
//
//       # end any in progress path
//       @finishPath()
//
//       # add the pad to the definitions if necessary
//       unless @currentTool.flashed
//         @defs.push shape for shape in @currentTool.pad
//         @currentTool.flashed = true
//
//       # flash the layer and update the current layer's bounding box
//       @current.push @currentTool.flash @x, @y
//       addBbox @currentTool.bbox(@x, @y), @layerBbox
//
//     else if operation.do is 'int'
//       # make sure the current tool is strokable if we're not in region mode
//       if not @region and not @currentTool.trace
//         return done new Error """
//           line #{line} - #{@currentTool.code} is not a strokable tool
//         """
//
//       # ensure we have an interpolation mode
//       unless @mode?
//         @mode = 'i'
//         @emit 'warning', new Warning "line #{line} - interpolation mode was not
//           set before first stroke; assuming linear"
//
//       # start the path if needed
//       unless @path.length then @path.push 'M', sX, sY
//
//       # draw a line or arc
//       if @mode is 'i'
//         @drawLine sX, sY, line
//
//       else
//         # error if the tool is rectangular and region mode is off
//         if not @region and not @currentTool.trace['stroke-width']?
//           return done new Error "line #{line} - cannot stroke an arc with
//             non-circular tool #{@currentTool.code}"
//
//         # ensure we have a quadrant mode
//         unless @quad?
//           return done new Error "line #{line} - quadrant mode was not set
//             before first arc draw"
//
//         # otherwise we're good to draw an arc
//         @drawArc sX, sY, operation.i, operation.j, line
//
//     # else operation is a move
//     else if @path.length
//       @path.push 'M', @x, @y
//
//     done()
//
//   finishLayer: ->
//     # finish any in progress path
//     @finishPath()
//
//     # only do something if there's stuff in the current layer
//     unless @current.length then return
//
//     # check for a step repeat
//     if @stepRepeat.x > 1 or @stepRepeat.y > 1
//       # wrap current up in a group with an sr id
//       srId = "gerber-sr_#{unique()}"
//       @current = [ { g: { id: srId, _: @current } } ]
//
//       # warn if polarity is clear and steps overlap the bbox
//       if @srOverClear or
//       @stepRepeat.i < @layerBbox.xMax - @layerBbox.xMin or
//       @stepRepeat.j < @layerBbox.yMax - @layerBbox.yMin
//         obj = {}; obj[@polarity] = srId
//         @srOverCurrent.push obj
//         if @polarity is 'C'
//           @srOverClear = true
//           @defs.push @current[0]
//
//       for x in [ 0...@stepRepeat.x ]
//         for y in [ 0...@stepRepeat.y ]
//           unless x is 0 and y is 0
//             u = { use: { 'xlink:href': "##{srId}" } }
//             u.use.x = x * @stepRepeat.i if x isnt 0
//             u.use.y = y * @stepRepeat.j if y isnt 0
//             @current.push u
//
//       # adjust the bbox
//       @layerBbox.xMax += (@stepRepeat.x - 1) * @stepRepeat.i
//       @layerBbox.yMax += (@stepRepeat.y - 1) * @stepRepeat.j
//
//     # add the layerBbox to the doc bbox
//     addBbox @layerBbox, @bbox
//     @layerBbox = {
//       xMin: Infinity, yMin: Infinity, xMax: -Infinity, yMax: -Infinity
//     }
//
//     # if dark polarity
//     if @polarity is 'D'
//       # is there an existing group that's been cleared, then we need to wrap
//       # insert the group at the beginning of current
//       if @group.g.mask? then @current.unshift @group
//
//       # set the group
//       if not @group.g.mask? and @group.g._.length
//         @group.g._.push c for c in @current
//       else
//         @group = { g: { _: @current } }
//
//     # else clear polarity
//     else if @polarity is 'C' and not @srOverClear
//       # make a mask
//       id = "gerber-mask_#{unique()}"
//       # shift in the bbox rect to keep everything
//       w = @bbox.xMax - @bbox.xMin
//       h = @bbox.yMax - @bbox.yMin
//       @current.unshift {
//         rect: {x: @bbox.xMin, y: @bbox.yMin, width: w, height: h, fill: '#fff'}
//       }
//
//       # push the masks to the definitions
//       @defs.push { mask: { id: id, color: '#000', _: @current}}
//       # add the mask to the group
//       @group.g.mask = "url(##{id})"
//
//     # empty out current
//     @current = []
//
//   # finish step repeat method
//   # really only does anything if clear layers overlap
//   finishSR: ->
//     if @srOverClear and @srOverCurrent
//       maskId = "gerber-sr-mask_#{unique()}"
//       m = { mask: { color: '#000', id: maskId, _: [] } }
//       m.mask._.push {
//         rect: {
//           fill: '#fff'
//           x: @bbox.xMin
//           y: @bbox.yMin
//           width: @bbox.xMax - @bbox.xMin
//           height: @bbox.yMax - @bbox.yMin
//         }
//       }
//
//       # loop through the repeats
//       for x in [ 0...@stepRepeat.x * @stepRepeat.i ] by @stepRepeat.i
//         for y in [ 0...@stepRepeat.y * @stepRepeat.j ] by @stepRepeat.j
//           for layer in @srOverCurrent
//             u = { use: {} }
//             u.use.x = x if x isnt 0
//             u.use.y = y if y isnt 0
//             u.use['xlink:href'] = '#' + (layer.C ? layer.D)
//             if layer.D? then u.use.fill = '#fff'
//             m.mask._.push u
//
//       # clear the flag and current array
//       @srOverClear = false
//       @srOverCurrent = []
//
//       # push the mask to the defs
//       @defs.push m
//
//       # mask the current group
//       @group.g.mask = "url(##{maskId})"
//
//   finish: ->
//     @finishLayer()
//     @finishSR()
//     # set default fill and stroke to current color in the group
//     @group.g.fill = 'currentColor'; @group.g.stroke = 'currentColor'
//     # flip vertically
//     @group.g.transform = "translate(0,#{@bbox.yMin + @bbox.yMax}) scale(1,-1)"
//
//
// module.exports = Plotter
