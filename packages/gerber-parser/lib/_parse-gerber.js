// parse gerber function
// takes a string, transform stream, and a done callback
'use strict'

const map = require('lodash.map')

const commands = require('./_commands')
const normalize = require('./_normalize-coord')
const parseCoord = require('./_parse-coord')

// g-code set matchers
const reMODE = /^G0*([123])/
const reREGION = /^G3([67])/
const reARC = /^G7([45])/
const reBKP_UNITS = /^G7([01])/
const reCOMMENT = /^G0*4/

// tool changes
const reTOOL = /^(?:G54)?D0*([1-9]\d+)/

// operations
const reCOORD = /((?:[XYIJ][+-]?\d+){1,4})/
const reOP = /D0*([123])$/

// parameter code matchers
const reUNITS = /^%MO(IN|MM)/
// format spec regexp courtesy @summivox
const reFORMAT = /^%FS([LT]?)([AI]?)X([0-7])([0-7])Y\3\4/
const rePOLARITY = /^%LP([CD])/
const reSTEP_REP = /^%SR(?:X(\d+)Y(\d+)I([\d.]+)J([\d.]+))?/
const reTOOL_DEF = /^%ADD(\d{2,})([A-Za-z_]\w*)(?:,((?:X?[\d.]+)*))?/

const parseToolDef = function(parser, block) {
  const format = {places: parser.format.places}
  const toolMatch = block.match(reTOOL_DEF)
  const tool = toolMatch[1]
  const shapeMatch = toolMatch[2]
  const toolArgs = (toolMatch[3]) ? toolMatch[3].split('X') : []

  // get the shape
  let shape
  let maxArgs
  if (shapeMatch === 'C') {
    shape = 'circle'
    maxArgs = 3
  }
  else if (shapeMatch === 'R') {
    shape = 'rect'
    maxArgs = 4
  }
  else if (shapeMatch === 'O') {
    shape = 'obround'
    maxArgs = 4
  }
  else if (shapeMatch === 'P') {
    shape = 'poly'
    maxArgs = 5
  }
  else {
    shape = shapeMatch
    maxArgs = 0
  }

  let val
  if (shape === 'circle') {
    val = normalize(toolArgs[0], format)
  }
  else if (shape === 'rect' || shape === 'obround') {
    val = [normalize(toolArgs[0], format), normalize(toolArgs[1], format)]
  }
  else if (shape === 'poly') {
    val = [normalize(toolArgs[0], format), Number(toolArgs[1])]
    if (toolArgs[2]) {
      val.push(Number(toolArgs[2]))
    }
  }
  else {
    val = map(toolArgs, Number)
  }

  let hole = 0
  if (toolArgs[maxArgs - 1]) {
    hole = [
      normalize(toolArgs[maxArgs - 2], format),
      normalize(toolArgs[maxArgs - 1], format)
    ]
  }
  else if (toolArgs[maxArgs - 2]) {
    hole = normalize(toolArgs[maxArgs - 2], format)
  }
  const toolDef = {shape, val, hole}
  parser._push(commands.tool(tool, toolDef))
}

const parse = function(parser, block) {
  if (reCOMMENT.test(block)) {
    return
  }

  else if (block === 'M02') {
    parser._push(commands.done())
  }

  else if (reREGION.test(block)) {
    const regionMatch = block.match(reREGION)[1]
    const region = (regionMatch === '6') ? true : false
    parser._push(commands.set('region', region))
  }

  else if (reARC.test(block)) {
    const arcMatch = block.match(reARC)[1]
    const arc = (arcMatch === '4') ? 's' : 'm'
    parser._push(commands.set('arc', arc))
  }

  else if (reUNITS.test(block)) {
    const unitsMatch = block.match(reUNITS)[1]
    const units = (unitsMatch === 'IN') ? 'in' : 'mm'
    parser._push(commands.set('units', units))
  }

  else if (reBKP_UNITS.test(block)) {
    const bkpUnitsMatch = block.match(reBKP_UNITS)[1]
    const backupUnits = (bkpUnitsMatch === '0') ? 'in' : 'mm'
    parser._push(commands.set('backupUnits', backupUnits))
  }

  else if (reFORMAT.test(block)) {
    const formatMatch = block.match(reFORMAT)
    const zero = formatMatch[1]
    const nota = formatMatch[2]
    const leading = Number(formatMatch[3])
    const trailing = Number(formatMatch[4])
    const format = parser.format

    format.zero = format.zero || zero
    if (!format.places.length) {
      format.places = [leading, trailing]
    }

    // warn if zero suppression missing or set to trailing
    if (!format.zero) {
      format.zero = 'L'
      parser._warn('zero suppression missing from format; assuming leading')
    }
    else if (format.zero === 'T') {
      parser._warn('trailing zero suppression has been deprecated')
    }

    const epsilon = 1500 * Math.pow(10, -parser.format.places[1])
    parser._push(commands.set('nota', nota))
    parser._push(commands.set('epsilon', epsilon))
  }

  else if (rePOLARITY.test(block)) {
    const polarity = block.match(rePOLARITY)[1]
    parser._push(commands.level('polarity', polarity))
  }

  else if (reSTEP_REP.test(block)) {
    const stepRepeatMatch = block.match(reSTEP_REP)
    const x = stepRepeatMatch[1] || 1
    const y = stepRepeatMatch[2] || 1
    const i = stepRepeatMatch[3] || 0
    const j = stepRepeatMatch[4] || 0
    const sr = {
      x: Number(x),
      y: Number(y),
      i: Number(i) * 1000,
      j: Number(j) * 1000
    }
    parser._push(commands.level('stepRep', sr))
  }

  else if (reTOOL.test(block)) {
    const tool = block.match(reTOOL)[1]
    parser._push(commands.set('tool', tool))
  }

  else if (reTOOL_DEF.test(block)) {
    parseToolDef(parser, block)
  }

  // finally, loop for mode commands and operations
  // they may appear in the same block
  else {
    const coordMatch = block.match(reCOORD)
    const opMatch = block.match(reOP)

    if (reMODE.test(block)) {
      let mode
      const modeMatch = block.match(reMODE)[1]
      if (modeMatch === '1') {
        mode = 'i'
      }
      else if (modeMatch === '2') {
        mode = 'cw'
      }
      else {
        mode = 'ccw'
      }

      parser._push(commands.set('mode', mode))
    }

    if (opMatch || coordMatch) {
      const opCode = (opMatch) ? opMatch[1] : ''
      const coordString = (coordMatch) ? coordMatch[1] : ''
      const coord = parseCoord(coordString, parser.format)

      let op = 'last'
      if (opCode === '1') {
        op = 'int'
      }
      else if (opCode === '2') {
        op = 'move'
      }
      else if (opCode === '3') {
        op = 'flash'
      }

      parser._push(commands.op(op, coord))
    }
  }
}

module.exports = parse
