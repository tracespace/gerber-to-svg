// function to determine filetype from a chunk
'use strict'

const determine = function(chunk, start, LIMIT) {
  const limit = Math.min(LIMIT - start, chunk.length)
  let current = []
  let filetype = null
  let index = -1

  while((!filetype) && (++index < limit)) {
    const c = chunk[index]
    if (c === '\n') {
      if (current.length + index) {
        filetype = 'drill'
        current = []
      }
    }
    else {
      current.push(c)
      if ((c === '*') && current[0] !== ';') {
        filetype = 'gerber'
        current = []
      }
    }
  }

  return filetype
}

module.exports = determine
