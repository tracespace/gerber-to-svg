// apply options to the plotter
'use strict'

const assign = require('lodash.assign')
const pick = require('lodash.pick')

const verifyUnits = function(units) {
  return ((units === 'in') || (units === 'mm'))
}

const verifyNota = function(nota) {
  return ((nota === 'A') || (nota === 'I'))
}

const verifyMap = {
  units: {
    check: verifyUnits,
    err: "units must be 'mm' or 'in'"
  },
  backupUnits: {
    check: verifyUnits,
    err: "backup units must be 'mm' or 'in'"
  },
  nota: {
    check: verifyNota,
    err: "notation must be 'A' or 'I'"
  },
  backupNota: {
    check: verifyNota,
    err: "backup notation must be 'A' or 'I'"
  }
}

const pickOptions = function(value, key) {
  const verification = verifyMap[key]
  if (!verification) {
    throw new Error(`${key} is an invalid options key`)
  }
  const result = verification.check(value)
  if (!result) {
    throw new Error(verification.err)
  }
  return result
}

const apply = function(opts, target, lock) {
  const verifiedOpts = pick(opts, pickOptions)
  for (const k of Object.keys(verifiedOpts)) {
    lock[k] = true
  }
  assign(target, verifiedOpts)
}

module.exports = apply
