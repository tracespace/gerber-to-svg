// simple benchmarks
'use strict'

const assert = require('assert')
const bench = require('nanobench')
const endOfStream = require('end-of-stream')
const flatMap = require('lodash/flatMap')
const intoStream = require('into-stream')

const getBoards = require('../fixtures/get-boards')
const gerberParser = require('../packages/gerber-parser')
const gerberPlotter = require('../packages/gerber-plotter')

const COUNT = 100

getBoards((error, boards) => {
  assert.ifError(error)

  flatMap(boards, (b) => b.layers).forEach(benchmarkLayer)
})

function benchmarkLayer (layer) {
  bench(
    `Parse ${layer.name} ${COUNT} times`,
    (b) => benchStream(layer.contents, gerberParser, false, b)
  )

  bench(
    `Plot ${layer.name} ${COUNT} times`,
    (b) => benchStream(layer.parsed, gerberPlotter, true, b)
  )
}

function benchStream (source, makeStream, objectMode, b) {
  b.start()
  run(COUNT)

  function run (count) {
    if (count <= 0) return b.end()

    runStream(source, makeStream, objectMode, (error) => {
      if (error) return b.error(error)
      run(count - 1)
    })
  }
}

function runStream (source, makeStream, objectMode, done) {
  const targetStream = makeStream()
  const sourceStream = (objectMode)
    ? intoStream.obj(source)
    : intoStream(source)

  endOfStream(sourceStream.pipe(targetStream).resume(), done)
}
