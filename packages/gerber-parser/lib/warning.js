// simple warning class to be emitted when something questionable in the gerber
// file is happened upon
//
// called with a message and the gerber file line number
var Warning = class Warning {
  constructor(message, line) {
    this.message = message
    this.line = line
  }
}

module.exports = Warning
