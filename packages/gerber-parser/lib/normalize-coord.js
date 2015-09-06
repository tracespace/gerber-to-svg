// convert a decimal number or gerber/drill coordinate into an svg coordinate
// coordinate is 1000x the gerber unit
'use strict'

// svg coordinate scaling factor and power of ten exponent
// const COORD_E = 3

// function takes in the number string to be converted and the format object
const normalizeCoord = function(number, format) {
  // make sure we're dealing with a string
  if (number == null) {
    return NaN
  }
  let numberString = '' + number

  // pull out the sign and get the before and after segments ready
  let before = ''
  let after = ''
  let sign = '+'
  if ((numberString[0] === '-') || (numberString[0] === '+')) {
    sign = numberString[0]
    numberString = numberString.slice(1)
  }

  // check if the number has a decimal point or has been explicitely flagged
  // if it does, just split by the decimal point to get leading and trailing
  if (numberString.includes('.') || (format.zero == null)) {
    // make sure there's not more than one decimal
    const subNumbers = numberString.split('.')
    if (subNumbers.length > 2) {
      return NaN
    }
    before = subNumbers[0]
    after = subNumbers[1] || ''
  }

  // otherwise we need to use the number format to split up the string
  else {
    const numberStringLen = numberString.length

    // make sure format is valid
    if (format.places == null || format.places.length !== 2) {
      return NaN
    }

    const leading = format.places[0]
    const trailing = format.places[1]
    if (!Number.isFinite(leading) || !Number.isFinite(trailing)) {
      return NaN
    }

    // split according to trailing or leading zero suppression
    if (format.zero === 'T') {
      for (let i = 0; i < numberStringLen; i++) {
        const c = numberString[i]
        if (i < leading) {
          before += c
        }
        else {
          after += c
        }
      }

      // pad any missing zeros
      before += '0'.repeat(Math.max(0, (leading - before.length)))
    }
    else if (format.zero === 'L') {
      for (let i = 0; i < numberStringLen; i++) {
        const c = numberString[i]
        if (numberString.length - i <= trailing) {
          after += c
        }
        else {
          before += c
        }
      }

      // pad any missing zeros
      after = '0'.repeat(Math.max(0, (trailing - after.length))) + after
    }
    else {
      return NaN
    }
  }

  // finally, parse the numberString
  return Number([sign + before, after].join('.'))
}

module.exports = normalizeCoord
