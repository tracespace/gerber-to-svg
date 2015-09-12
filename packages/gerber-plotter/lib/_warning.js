// simple warning
'use strict'

const warning = function(message, line) {
  return {message, line}
}

module.exports = warning
