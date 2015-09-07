// verify the parser options and return a valid options object
// throws if invalid
'use strict'

const assign = require('lodash.assign')
const pick = require('lodash.pick')

const verifyPlaces = function(p) {
  const isAnArray = Array.isArray(p)
  const correctLength = (p.length === 2)
  const finite = (Number.isFinite(p[0]) && Number.isFinite(p[1]))
  return (isAnArray && correctLength && finite)
}

const verifyZero = function(z) {
  return ((z === 'T') || (z === 'L'))
}

const verifyFiletype = function(f) {
  return ((f === 'gerber') || (f === 'drill'))
}

const verifyMap = {
  places: {check: verifyPlaces, err: 'places must be an array of two numbers 0-7'},
  zero: {check: verifyZero, err: "zero suppression must be 'L' or 'T'"},
  filetype: {check: verifyFiletype, err: "filetype must be 'drill' or 'gerber'"}
}

const pickOptions = function(value, key) {
  const verification = verifyMap[key]
  const result = verification.check(value)
  if (!result) {
    throw new Error(verification.err)
  }
  return result
}

const applyOptions = function(opts, target) {
  assign(target, pick(opts, pickOptions))
}

module.exports = applyOptions
