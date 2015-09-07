# simple warning class to be emitted when something questionable in the gerber
# file is happened upon
#
# called with a message and the gerber file line number
class Warning
  constructor: (@message, @line) ->

module.exports = Warning
