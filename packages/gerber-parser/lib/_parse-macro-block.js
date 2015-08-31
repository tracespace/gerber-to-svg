// function to parse a macro block into a primitive object
'use strict'

// CAUTION: assumes parser will be bound to this
const parseMacroBlock = function(block) {
  const mods = block.split(',')
  const code = mods[0]
  const exp = mods[1]

  // circle primitive
  if (code === '1') {
    return {type: 'circle', exp, dia: mods[2], cx: mods[3], cy: mods[4]}
  }

  // vector primitive
  if (code === '2' || code === '20') {
    if (code === '2') {
      this._warn('macro apeture vector primitives with code 2 are deprecated')
    }
    return {
      type: 'vect',
      exp,
      width: mods[2],
      x1: mods[3],
      y1: mods[4],
      x2: mods[5],
      y2: mods[6],
      rot: mods[7]
    }
  }

  // center rectangle
  if (code === '21') {
    return {
      type: 'rect',
      exp,
      width: mods[2],
      height: mods[3],
      cx: mods[4],
      cy: mods[5],
      rot: mods[6]
    }
  }

  if (code === '22') {
    this._warn('macro apeture lower-left rectangle primitives are deprecated')
    return {
      type: 'rectLL',
      exp,
      width: mods[2],
      height: mods[3],
      x: mods[4],
      y: mods[5],
      rot: mods[6]
    }
  }

  if (code === '4') {
    return {
      type: 'outline',
      exp,
      points: mods.slice(3, -1),
      rot: mods[mods.length - 1]
    }
  }

  if (code === '5') {
    return {
      type: 'poly',
      exp,
      vertices: mods[2],
      cx: mods[3],
      cy: mods[4],
      dia: mods[5],
      rot: mods[6]
    }
  }

  if (code === '6') {
    return {
      type: 'moire',
      exp,
      cx: mods[2],
      cy: mods[3],
      dia: mods[4],
      ringThx: mods[5],
      ringGap: mods[6],
      maxRings: mods[7],
      crossThx: mods[8],
      crossLen: mods[9],
      rot: mods[10]
    }
  }

  if (code === '7') {
    return {
      type: 'thermal',
      exp,
      cx: mods[2],
      cy: mods[3],
      outerDia: mods[4],
      innerDia: mods[5],
      gap: mods[6],
      rot: mods[7]
    }
  }
}

module.exports = parseMacroBlock
