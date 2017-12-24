// get test fixture gerbers with expected renders
// calls done with an array of gerber object where a layer object has:
// {
//   name: string,
//   filename: string,
//   category: string,
//   contents: string,
//   expectedSvg: string,
// }
'use strict'

const fs = require('fs')
const path = require('path')
const glob = require('glob')
const runParallel = require('run-parallel')
const runWaterfall = require('run-waterfall')

const GERBER_PATTERN = path.join(__dirname, `gerbers/*/*.@(gbr|drl)`)

module.exports = function getGerbers (done) {
  runWaterfall([
    (next) => glob(GERBER_PATTERN, next),
    matchesToLayers
  ], done)
}

function matchesToLayers (matches, done) {
  runParallel(
    matches.map((match) => (next) => singleMatchToLayer(match, next)),
    done
  )
}

function singleMatchToLayer (filename, done) {
  const name = path.basename(filename).split('.')[0]
  const dirname = path.dirname(filename)
  const category = path.basename(dirname)
  const svgFilename = path.join(dirname, `${name}.svg`)

  runParallel([
    (next) => fs.readFile(filename, 'utf8', next),
    (next) => fs.readFile(svgFilename, 'utf8', next)
  ], (error, results) => {
    if (error) return done(error)

    const [contents, expectedSvg] = results

    done(null, {name, filename, category, contents, expectedSvg})
  })
}
