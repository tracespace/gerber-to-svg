// function for getting the next block of the chunk
// returns {next: '_', read: [chars read], lines: [lines read]}
'use strict'

const getNext = function(type, chunk, start) {
  if (type !== 'gerber' && type !== 'drill') {
    throw new Error('filetype to get next block must be "drill" or "gerber"')
  }

  // parsing constants
  const limit = chunk.length - start
  const split = (type === 'gerber') ? '*' : '\n'
  const param = (type === 'gerber') ? '%' : ''

  // search flags
  let splitFound = false
  let paramStarted = false
  let paramFound = false
  let blockFound = false

  // chunk results
  const found = []
  let read = 0
  let lines = 0

  while ((!blockFound) && (read < limit)) {
    const c = chunk[start + read]

    // count newlines
    if (c === '\n') {
      lines++
    }

    // check for a param start or end
    if (c === param) {
      if (!paramStarted) {
        paramStarted = true
        found.push(c)
      }
      else {
        paramFound = true
      }
    }
    else if (c === split) {
      splitFound = true
    }
    else if ((' ' <= c) && (c <= '~')) {
      found.push(c)
    }

    read++
    blockFound = (splitFound && ((!paramStarted) || paramFound))
  }

  const block = found.join('')
  return {lines, read, block}
}

module.exports = getNext
