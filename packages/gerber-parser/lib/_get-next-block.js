// function for getting the next block of the chunk
// returns {next: '_', read: [chars read], lines: [lines read]}
'use strict'

const getNext = function(type, chunk, start) {
  const limit = chunk.length - start
  const found = []
  const split = '*'
  let read = 0
  let lines = 0
  let block = ''

  while ((!block) && (read < limit)) {
    const c = chunk[start + read]
    if (c === '\n') {
      lines++
    }

    if (c === split) {
      block = found.join('')
    }
    else {
      found.push(c)
    }

    read++
  }

  return {lines, read, block}
}

module.exports = getNext
