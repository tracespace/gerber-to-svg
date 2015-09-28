// factories to generate all possible parsed by a gerber command
'use strict'

var done = function() {
  return {cmd: 'done', line: -1}
}

var set = function(key, val) {
  return {cmd: 'set', line: -1, key: key, val: val}
}

var level = function(key, val) {
  return {cmd: 'level', line: -1, key: key, val: val}
}

var tool = function(key, val) {
  return {cmd: 'tool', line: -1, key: key, val: val}
}

var op = function(key, val) {
  return {cmd: 'op', line: -1, key: key, val: val}
}

var macro = function(key, val) {
  return {cmd: 'macro', line: -1, key: key, val: val}
}

var commandMap = {
  set: set, done: done, level: level, tool: tool, op: op, macro: macro
}
module.exports = commandMap
