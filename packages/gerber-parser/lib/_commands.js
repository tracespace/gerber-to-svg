// factories to generate all possible parsed by a gerber command
'use strict'

const set = function(line, key, val) {
  return {cmd: 'set', line, key, val}
}

const commandMap = {set: set}
module.exports = commandMap
