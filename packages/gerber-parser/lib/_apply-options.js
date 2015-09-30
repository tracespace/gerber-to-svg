// verify the parser options and return a valid options object
// throws if invalid
'use strict'

var assign = require('lodash.assign')
var pick = require('lodash.pick')
var numIsFinite = require('lodash.isfinite')

var verifyPlaces = function(p) {
  var isAnArray = Array.isArray(p)
  var correctLength = (p.length === 2)
  var finite = (numIsFinite(p[0]) && numIsFinite(p[1]))
  return (isAnArray && correctLength && finite)
}

var verifyZero = function(z) {
  return ((z === 'T') || (z === 'L'))
}

var verifyFiletype = function(f) {
  return ((f === 'gerber') || (f === 'drill'))
}

var verifyMap = {
  places: {check: verifyPlaces, err: 'places must be an array of two numbers 0-7'},
  zero: {check: verifyZero, err: "zero suppression must be 'L' or 'T'"},
  filetype: {check: verifyFiletype, err: "filetype must be 'drill' or 'gerber'"}
}

var pickOptions = function(value, key) {
  var verification = verifyMap[key]
  var result = verification.check(value)
  if (!result) {
    throw new Error(verification.err)
  }
  return result
}

var applyOptions = function(opts, target) {
  assign(target, pick(opts, pickOptions))
}

module.exports = applyOptions
