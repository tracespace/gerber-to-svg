// clone a PlotterToSvg to a plain object with just enough information to render
'use strict'

var pick = require('lodash.pick')

module.exports = function cloneConverter(converter) {
  return pick(converter, [
    'defs',
    'layer',
    'viewBox',
    'width',
    'height',
    'units'
  ])
}
