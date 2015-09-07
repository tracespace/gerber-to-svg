// parse drill function
// takes a parser transform stream and a block string
'use strict'

// const map = require('lodash.map')

const commands = require('./_commands')
const normalize = require('./normalize-coord')
const parseCoord = require('./parse-coord')

const reKI_HINT = /;FORMAT={(.):(.)\/ (absolute|.+)? \/ (metric|inch) \/.+(trailing|leading|decimal|keep)/

const reUNITS = /(INCH|METRIC)(?:,([TL])Z)?/
const reTOOL_DEF = /T0*(\d+)C([\d.]+)/
const reTOOL_SET = /T0*(\d+)(?!C)/
const reCOORD = /((?:[XY][+-]?[\d.]+){1,2})/

const setUnits = function(parser, units) {
  const format = (units === 'in') ? [2, 4] : [3, 3]
  if (parser.format.places.length === 0) {
    parser.format.places = format
  }
  return parser._push(commands.set('units', units))
}

const parse = function(parser, block) {
  // ignore comments
  if (block[0] === ';') {

    // check for kicad format hints
    if (reKI_HINT.test(block)) {
      const kicadMatch = block.match(reKI_HINT)
      const leading = Number(kicadMatch[1])
      const trailing = Number(kicadMatch[2])
      const absolute = kicadMatch[3]
      const units = kicadMatch[4]
      const suppression = kicadMatch[5]

      // set format if we got numbers
      if (!Number.isNaN(leading) && !Number.isNaN(trailing)) {
        parser.format.places = [leading, trailing]
      }

      // send backup notation
      if (absolute === 'absolute') {
        parser._push(commands.set('backupNota', 'A'))
      }
      else {
        parser._push(commands.set('backupNota', 'I'))
      }

      // send units
      if (units === 'metric') {
        parser._push(commands.set('backupUnits', 'mm'))
      }
      else {
        parser._push(commands.set('backupUnits', 'in'))
      }

      // set zero suppression
      if (suppression === 'leading' || suppression === 'keep') {
        parser.format.zero = 'L'
      }
      else if (suppression === 'trailing') {
        parser.format.zero = 'T'
      }
      else {
        parser.format.zero = 'D'
      }
    }

    return
  }

  if (reTOOL_DEF.test(block)) {
    const toolMatch = block.match(reTOOL_DEF)
    const toolCode = toolMatch[1]
    const toolDia = normalize(toolMatch[2])
    const tool = {shape: 'circle', val: [toolDia], hole: []}

    return parser._push(commands.tool(toolCode, tool))
  }

  // tool set
  if (reTOOL_SET.test(block)) {
    const tool = block.match(reTOOL_SET)[1]

    // allow tool set to fall through because it can happen on the
    // same line as a coordinate operation
    parser._push(commands.set('tool', tool))
  }

  // operations
  if (reCOORD.test(block)) {
    // ensure format is set properly
    if (!parser.format.zero) {
      parser.format.zero = 'T'
      parser._warn('zero suppression missing; assuming trailing suppression')
    }

    if (!parser.format.places.length) {
      parser.format.places = [2, 4]
      parser._warn('places format missing; assuming [2, 4]')
    }

    const coordMatch = block.match(reCOORD)
    const coord = parseCoord(coordMatch[1], parser.format)
    return parser._push(commands.op('flash', coord))
  }

  if ((block === 'M00') || (block === 'M30')) {
    return parser._push(commands.done())
  }

  if (block === 'M71') {
    return setUnits(parser, 'mm')
  }

  if (block === 'M72') {
    return setUnits(parser, 'in')
  }

  if (block === 'G90') {
    return parser._push(commands.set('nota', 'A'))
  }

  if (block === 'G91') {
    return parser._push(commands.set('nota', 'I'))
  }

  if (reUNITS.test(block)) {
    const unitsMatch = block.match(reUNITS)
    const units = unitsMatch[1]
    const suppression = unitsMatch[2]

    if (units === 'METRIC') {
      setUnits(parser, 'mm')
    }
    else {
      setUnits(parser, 'in')
    }

    if (suppression === 'T') {
      parser.format.zero = parser.format.zero || 'L'
    }
    else if (suppression === 'L') {
      parser.format.zero = parser.format.zero || 'T'
    }

    return
  }

  return
}

module.exports = parse
