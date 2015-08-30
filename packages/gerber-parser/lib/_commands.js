// factories to generate all possible parsed by a gerber command
'use strict'

const done = function() {
  return {cmd: 'done', line: -1}
}

const set = function(key, val) {
  return {cmd: 'set', line: -1, key, val}
}

const level = function(key, val) {
  return {cmd: 'level', line: -1, key, val}
}

const tool = function(key, val) {
  return {cmd: 'tool', line: -1, key, val}
}

const op = function(key, val) {
  return {cmd: 'op', line: -1, key, val}
}

const commandMap = {set: set, done: done, level: level, tool: tool, op: op}
module.exports = commandMap
