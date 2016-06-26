// sort layers array into top and bottom
'use strict'

module.exports = function sortLayers(layers) {
  return layers.reduce(function(result, layer) {
    var type = layer.type
    var side = type[0]
    var subtype = type.slice(1)

    if (type === 'drl') {
      result.mech.push(layer)
    }
    else if (type === 'out') {
      result.mech.push(layer)
    }
    else {
      layer = {type: subtype, converter: layer.converter}

      if (side === 't') {
        result.top.push(layer)
      }
      else if (side === 'b') {
        result.bottom.push(layer)
      }
    }

    return result
  }, {top: [], bottom: [], mech: []})
}
