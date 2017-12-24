// get test fixture board layers
// calls done with an array of layer objects where a layer object has:
// {
//   name: string,
//   filename: string,
//   board: string,
//   format: 'gerber' | 'drill',
//   contents: string,
//   parsed: Array<{}>,
// }
'use strict'

const fs = require('fs')
const path = require('path')
const flatten = require('lodash/flatten')
const glob = require('glob')
const runParallel = require('run-parallel')
const runWaterfall = require('run-waterfall')

const gerberParser = require('../packages/gerber-parser')

const MANIFEST_PATTERN = path.join(__dirname, 'boards/*/manifest.json')

module.exports = function getBoardLayers (done) {
  runWaterfall([
    getManifestMatches,
    getLayersFromMatches,
    (allLayers, next) => next(null, flatten(allLayers))
  ], done)
}

function getManifestMatches (done) {
  glob(MANIFEST_PATTERN, done)
}

function getLayersFromMatches (matches, done) {
  runParallel(
    matches.map((match) => (next) => matchToLayers(match, next)),
    done
  )
}

function matchToLayers (match, done) {
  runWaterfall([
    (next) => readManifest(match, next),
    manifestToLayers
  ], done)
}

function readManifest (filename, done) {
  fs.readFile(filename, 'utf8', (error, result) => {
    if (error) return done(error)

    try {
      done(null, Object.assign(JSON.parse(result), {filename}))
    } catch (error) {
      done(error)
    }
  })
}

function manifestToLayers (manifest, done) {
  runParallel(
    manifest.layers.map((ly) => (next) => augmentLayer(manifest, ly, next)),
    done
  )
}

function augmentLayer (manifest, layer, done) {
  const dirname = path.dirname(manifest.filename)
  const filename = path.join(dirname, layer.name)
  const board = path.basename(dirname)

  fs.readFile(filename, 'utf8', (error, contents) => {
    if (error) return done(error)

    const parsed = gerberParser().parseSync(contents)

    done(null, Object.assign({board, contents, parsed}, layer))
  })
}
