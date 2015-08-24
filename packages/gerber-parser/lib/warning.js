// simple warning class to be emitted when something questionable in the gerber is found
'use strict'

class Warning {
  constructor(message, line) {
    this.message = message
    this.line = line
  }
}

module.exports = Warning
