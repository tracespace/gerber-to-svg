// function to parse a macro block into a primitive object
'use strict'

const map = require('lodash.map')
const clone = require('lodash.clone')
const set = require('lodash.set')

const parseExpr = require('./_parse-macro-expression')

const reEXPR = /[\$+\-\/xX]/
const reVAR_DEF = /^(\$[\d+])=(.+)/

// CAUTION: assumes parser will be bound to this
const parseMacroBlock = function(block) {
  // check first for a comment
  if (block[0] === '0') {
    return {type: 'comment'}
  }

  // variable definition
  if (reVAR_DEF.test(block)) {
    const varDefMatch = block.match(reVAR_DEF)
    const varName = varDefMatch[1]
    const varExpr = varDefMatch[2]
    const evaluate = parseExpr.bind(this)(varExpr)

    const setMods = function(mods) {
      return set(clone(mods), varName, evaluate(mods))
    }
    return {type: 'variable', set: setMods}
  }

  // map a primitive param to a number or, if an expression, a function
  const modVal = function(m) {
    if (reEXPR.test(m)){
      return parseExpr.bind(this)(m)
    }
    return Number(m)
  }

  const mods = map(block.split(','), modVal)
  const code = mods[0]
  const exp = mods[1]

  // circle primitive
  if (code === 1) {
    return {type: 'circle', exp, dia: mods[2], cx: mods[3], cy: mods[4]}
  }

  // vector primitive
  if (code === 2) {
    this._warn('macro apeture vector primitives with code 2 are deprecated')
  }

  if (code === 2 || code === 20) {
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
  if (code === 21) {
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

  if (code === 22) {
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

  if (code === 4) {
    return {
      type: 'outline',
      exp,
      points: map(mods.slice(3, -1), Number),
      rot: Number(mods[mods.length - 1])
    }
  }

  if (code === 5) {
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

  if (code === 6) {
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

  if (code === 7) {
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

  else {
    this._warn(`${code} is an unrecognized primitive for a macro apeture`)
  }
}

module.exports = parseMacroBlock
