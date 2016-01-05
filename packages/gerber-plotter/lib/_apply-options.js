// apply options to the plotter
'use strict'

var assign = require('lodash.assign')
var pick = require('lodash.pick')
var forEach  = require('lodash.foreach')

var verifyUnits = function(units) {
  return ((units === 'in') || (units === 'mm'))
}

var verifyNota = function(nota) {
  return ((nota === 'A') || (nota === 'I'))
}

var verifyMap = {
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

var pickOptions = function(value, key) {
  if (value == null) {
    return false
  }

  var verification = verifyMap[key]
  if (!verification) {
    throw new Error(key + ' is an invalid options key')
  }
  var result = verification.check(value)
  if (!result) {
    throw new Error(verification.err)
  }
  return result
}

var apply = function(opts, target, lock) {
  var verifiedOpts = pick(opts, pickOptions)

  forEach(Object.keys(verifiedOpts), function(key) {
    lock[key] = true
  })

  assign(target, verifiedOpts)
}

module.exports = apply
