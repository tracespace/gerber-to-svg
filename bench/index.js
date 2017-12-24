// simple benchmarks
'use strict'

const assert = require('assert')
const bench = require('nanobench')
const intoStream = require('into-stream')
const endOfStream = require('end-of-stream')

const getLayers = require('../fixtures/get-layers')
const gerberParser = require('../packages/gerber-parser')
const gerberPlotter = require('../packages/gerber-plotter')

const COUNT = 100

getLayers((error, layers) => {
  assert.ifError(error)

  layers.forEach(benchmarkLayer)
})

function benchmarkLayer (layer) {
  bench(
    `Parse ${layer.name} ${COUNT} times`,
    benchStream.bind(null, layer.contents, gerberParser, false)
  )

  bench.skip(
    `Plot ${layer.name} ${COUNT} times`,
    benchStream.bind(null, layer.parsed, gerberPlotter, true)
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
