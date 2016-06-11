// stack layers function (where the magic happens)
'use strict'

var wrapLayer = require('./wrap-layer')
var viewBox = require('./view-box')

var useLayer = function(id, className, mask) {
  var colorAttr = (className) ? ('fill="currentColor" stroke="currentColor" ') : ''
  var classAttr = (className) ? ('class="' + className + '" ') : ''
  var maskAttr = (mask) ? ('mask="url(#' + mask + ')" ') : ''

  return '<use ' + classAttr + colorAttr + maskAttr + 'xlink:href="#' + id + '"/>'
}

var mechMask = function(id, box, mechIds, useOutline) {
  var mask = '<mask id="' + id + '" fill="#000" stroke="#000">'

  if (useOutline && mechIds.out) {
    mask += useLayer(mechIds.out)
  }
  else {
    mask += viewBox.rect(box, '', '#fff')
  }

  mask = Object.keys(mechIds).reduce(function(result, type) {
    var id = mechIds[type]

    if (type !== 'out') {
      result += useLayer(id)
    }

    return result
  }, mask)

  return mask + '</mask>'
}

module.exports = function stackLayers(id, side, converters, mechs, useOutlineInMask) {
  var classPrefix = id + '_'
  var idPrefix = id + '_' + side + '_'

  // decide what units we're using
  var converterTypes = Object.keys(converters)
  var mechTypes = Object.keys(mechs)
  var allConverters = {}
  var allConverterTypes = []
  var collectAllConverters = function(types, convertersByType) {
    types.forEach(function(type) {
      allConverters[type] = convertersByType[type]
      allConverterTypes.push(type)
    })
  }

  collectAllConverters(converterTypes, converters)
  collectAllConverters(mechTypes, mechs)

  var unitsCount = allConverterTypes.reduce(function(result, type) {
    var units = allConverters[type].units

    result[units] = (result[units] || 0) + 1

    return result
  }, {in: 0, mm: 0})

  var units = (allConverterTypes.length !== 0)
    ? (((unitsCount.in) > (unitsCount.mm)) ? 'in' : 'mm')
    : ''

  var switchUnitsScale = (units === 'in') ? (1 / 25.4) : 25.4

  var getScale = function(converter) {
    return (converter.units === units) ? 1 : switchUnitsScale
  }

  // gather defs and viewboxes from all converters
  var defsAndBox = allConverterTypes.reduce(function(result, type) {
    var converter = allConverters[type]
    var scale = getScale(converter)

    // only combine viewboxes if there's no outline layer, otherwise use outline
    if (!mechs.out || (mechs.out && type === 'out')) {
      result.box = viewBox.addScaled(result.box, converter.viewBox, scale)
    }

    result.defs += converter.defs

    return result
  }, {defs: '', box: viewBox.new()})

  var defs = defsAndBox.defs
  var box = defsAndBox.box

  // wrap all layers in groups and add them to defs
  var mapConvertersToIds = function(types, convertersByType) {
    return types.reduce(function(result, type) {
      var converter = convertersByType[type]
      var layerId = idPrefix + type
      var scale = getScale(converter)

      defs += wrapLayer(layerId, converter, scale)
      result[type] = layerId

      return result
    }, {})
  }

  var layerIds = mapConvertersToIds(converterTypes, converters)
  var mechIds = mapConvertersToIds(mechTypes, mechs)
  var mechMaskId = idPrefix + 'mech-mask'

  defs += mechMask(mechMaskId, box, mechIds, useOutlineInMask)

  // build the group starting with an fr4 rectangle the size of the viewbox
  var group = viewBox.rect(box, classPrefix + 'fr4', 'currentColor')

  // add copper and copper finish
  if (layerIds.cu) {
    var cfMaskId = idPrefix + 'cf-mask'

    defs += [
      '<mask id="' + cfMaskId + '" fill="#fff" stroke="#fff">',
      ((layerIds.sm) ? useLayer(layerIds.sm) : viewBox.rect(box)),
      '</mask>'
    ].join('')

    group += useLayer(layerIds.cu, classPrefix + 'cu')
    group += useLayer(layerIds.cu, classPrefix + 'cf', cfMaskId)
  }

  // add soldermask and silkscreen
  // silkscreen will not be added if no soldermask, because that's how it works in RL
  if (layerIds.sm) {
    // solder mask is... a mask, so mask it
    var smMaskId = idPrefix + 'sm-mask'

    defs += [
      '<mask id="' + smMaskId + '" fill="#000" stroke="#000">',
      viewBox.rect(box, '', '#fff'),
      useLayer(layerIds.sm),
      '</mask>'
    ].join('')

    // add the group that gets masked
    group += [
      '<g mask="url(#' + smMaskId + ')">',
      viewBox.rect(box, classPrefix + 'sm', 'currentColor'),
      ((layerIds.ss) ? useLayer(layerIds.ss, classPrefix + 'ss') : ''),
      '</g>'
    ].join('')
  }

  // add solderpaste
  if (layerIds.sp) {
    group += useLayer(layerIds.sp, classPrefix + 'sp')
  }

  // add board outline if necessary
  if (mechs.out && !useOutlineInMask) {
    group += useLayer(mechIds.out, classPrefix + 'out')
  }

  // mask the group with the mechanical mask
  group = '<g mask="url(#' + mechMaskId + ')">' + group + '</g>'

  return {
    defs: defs,
    group: group,
    box: box,
    units: units
  }
}
