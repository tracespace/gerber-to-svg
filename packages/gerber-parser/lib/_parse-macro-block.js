// function to parse a macro block into a primitive object
'use strict'

const map = require('lodash.map')

// CAUTION: assumes parser will be bound to this
const parseMacroBlock = function(block) {
  const mods = block.split(',')
  const code = mods[0]
  const exp = Number(mods[1])

  // circle primitive
  if (code === '1') {
    return {type: 'circle', exp, dia: Number(mods[2]), cx: Number(mods[3]), cy: Number(mods[4])}
  }

  // vector primitive
  if (code === '2' || code === '20') {
    if (code === '2') {
      this._warn('macro apeture vector primitives with code 2 are deprecated')
    }
    return {
      type: 'vect',
      exp,
      width: Number(mods[2]),
      x1: Number(mods[3]),
      y1: Number(mods[4]),
      x2: Number(mods[5]),
      y2: Number(mods[6]),
      rot: Number(mods[7])
    }
  }

  // center rectangle
  if (code === '21') {
    return {
      type: 'rect',
      exp,
      width: Number(mods[2]),
      height: Number(mods[3]),
      cx: Number(mods[4]),
      cy: Number(mods[5]),
      rot: Number(mods[6])
    }
  }

  if (code === '22') {
    this._warn('macro apeture lower-left rectangle primitives are deprecated')
    return {
      type: 'rectLL',
      exp,
      width: Number(mods[2]),
      height: Number(mods[3]),
      x: Number(mods[4]),
      y: Number(mods[5]),
      rot: Number(mods[6])
    }
  }

  if (code === '4') {
    return {
      type: 'outline',
      exp,
      points: map(mods.slice(3, -1), Number),
      rot: Number(mods[mods.length - 1])
    }
  }

  if (code === '5') {
    return {
      type: 'poly',
      exp,
      vertices: Number(mods[2]),
      cx: Number(mods[3]),
      cy: Number(mods[4]),
      dia: Number(mods[5]),
      rot: Number(mods[6])
    }
  }

  if (code === '6') {
    return {
      type: 'moire',
      exp,
      cx: Number(mods[2]),
      cy: Number(mods[3]),
      dia: Number(mods[4]),
      ringThx: Number(mods[5]),
      ringGap: Number(mods[6]),
      maxRings: Number(mods[7]),
      crossThx: Number(mods[8]),
      crossLen: Number(mods[9]),
      rot: Number(mods[10])
    }
  }

  if (code === '7') {
    return {
      type: 'thermal',
      exp,
      cx: Number(mods[2]),
      cy: Number(mods[3]),
      outerDia: Number(mods[4]),
      innerDia: Number(mods[5]),
      gap: Number(mods[6]),
      rot: Number(mods[7])
    }
  }

  else {
    this._warn(`${code} is an unrecognized primitive for a macro apeture`)
  }
}

module.exports = parseMacroBlock
