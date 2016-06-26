// helper for stack layers that scales, wraps, gathers the defs of layers
'use strict'

var viewbox = require('viewbox')

var wrapLayer = require('./wrap-layer')

var getScale = function(units, layerUnits) {
  var scale = units === 'in'
    ? 1 / 25.4
    : 25.4

  var result = units === layerUnits
    ? 1
    : scale

  return result
}

module.exports = function(element, idPrefix, layers, mechLayers) {
  var defs = []
  var layerIds = []
  var mechIds = []
  var units = ''
  var unitsCount = {in: 0, mm: 0}
  var allLayers = layers.concat(mechLayers)
  var outline

  var drillCount = 0
  var getUniqueId = function(type) {
    var idSuffix = (type !== 'drl')
      ? ''
      : ++drillCount

    return idPrefix + type + idSuffix
  }

  allLayers.forEach(function(layer) {
    if (!layer.externalId) {
      defs = defs.concat(defs, layer.converter.defs)
    }

    if (layer.type === 'out') {
      outline = layer
    }

    if (layer.converter.units === 'mm') {
      unitsCount.mm++
    }
    else {
      unitsCount.in++
    }
  })

  if (unitsCount.in + unitsCount.mm) {
    units = (unitsCount.in > unitsCount.mm) ? 'in' : 'mm'
  }

  var viewboxLayers = (outline) ? [outline] : allLayers
  var box = viewboxLayers.reduce(function(result, layer) {
    var nextBox = layer.converter.viewBox

    nextBox = viewbox.scale(nextBox, getScale(units, layer.converter.units))

    return viewbox.add(result, nextBox)
  }, viewbox.create())

  var wrapConverterLayer = function(collection) {
    return function(layer) {
      var id = layer.externalId
      var converter = layer.converter

      if (!id) {
        id = getUniqueId(layer.type)
        defs.push(wrapLayer(element, id, converter, getScale(units, converter.units)))
      }

      collection.push({type: layer.type, id: id})
    }
  }

  layers.forEach(wrapConverterLayer(layerIds))
  mechLayers.forEach(wrapConverterLayer(mechIds))

  return {
    defs: defs,
    box: box,
    units: units,
    layerIds: layerIds,
    mechIds: mechIds
  }
}
