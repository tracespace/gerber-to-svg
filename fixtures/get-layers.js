// get test fixture gerber layers
'use strict'

const fs = require('fs')
const path = require('path')
const flatten = require('lodash/flatten')
const glob = require('glob')
const runParallel = require('run-parallel')
const runWaterfall = require('run-waterfall')

const gerberParser = require('../packages/gerber-parser')

const MANIFEST_PATTERN = path.join(__dirname, '**/manifest.json')

module.exports = function getLayers (done) {
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
  const tasks = matches.map((match) => matchToLayers.bind(null, match))

  runParallel(tasks, done)
}

function matchToLayers (match, done) {
  runWaterfall([
    readManifest.bind(null, match),
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
  const tasks = manifest.layers
    .map((layer) => augmentLayer.bind(null, manifest, layer))

  runParallel(tasks, done)
}

function augmentLayer (manifest, layer, done) {
  const filename = path.join(path.dirname(manifest.filename), layer.name)

  fs.readFile(filename, 'utf8', (error, contents) => {
    if (error) return done(error)

    done(null, Object.assign({}, layer, {
      contents,
      parsed: gerberParser().parseSync(contents)
    }))
  })
}
