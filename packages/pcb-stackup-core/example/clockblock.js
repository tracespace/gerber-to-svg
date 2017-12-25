'use strict'

const fs = require('fs')
const path = require('path')
const gerberToSvg = require('gerber-to-svg')
const runParallel = require('run-parallel')
const runWaterfall = require('run-waterfall')
const shortId = require('shortid')
const whatsThatGerber = require('whats-that-gerber')

const pcbStackupCore = require('../lib')

// collection of gerber files in a directory
const GERBER_FILES = [
  '../../../fixtures/boards/clockblock/clockblock-F_Cu.gbr',
  '../../../fixtures/boards/clockblock/clockblock-F_Mask.gbr',
  '../../../fixtures/boards/clockblock/clockblock-F_SilkS.gbr',
  '../../../fixtures/boards/clockblock/clockblock-F_Paste.gbr',
  '../../../fixtures/boards/clockblock/clockblock-B_Cu.gbr',
  '../../../fixtures/boards/clockblock/clockblock-B_Mask.gbr',
  '../../../fixtures/boards/clockblock/clockblock-B_SilkS.gbr',
  '../../../fixtures/boards/clockblock/clockblock-Edge_Cuts.gbr',
  '../../../fixtures/boards/clockblock/clockblock.drl',
  '../../../fixtures/boards/clockblock/clockblock-NPTH.drl'
].map((relativePath) => path.join(__dirname, relativePath))

// see documentation for full list of pcb-stackup-core options
const STACKUP_OPTIONS = {
  // stackup needs a unique to avoid collisions with other stackups on the page
  id: shortId.generate(),
  // use the outline layer to determine the shape of the board
  // if false, board shape will be a rectangle
  maskWithOutline: true
}

const OUTPUT_PREFIX = path.join(__dirname, 'clockblock-stackup')

// render stackup and write sides to `examples/clockblock-stackup-${side}.svg`
runWaterfall([
  renderStackup,
  writeStackupFiles
], (error, results) => {
  if (error) return console.error('Error rendering stackup:', error)

  console.log('Stackup renders written!')
})

// convert all layers in parallel, then pass the results to pcb-stackup-core
function renderStackup (done) {
  const tasks = GERBER_FILES.map((file) => (next) => renderLayer(file, next))

  runWaterfall([
    (next) => runParallel(tasks, next),
    (layers, next) => next(null, pcbStackupCore(layers, STACKUP_OPTIONS))
  ], done)
}

function renderLayer (filename, done) {
  const type = whatsThatGerber(path.basename(filename))
  const filestream = fs.createReadStream(filename)
  // see gerber-to-svg documenation for layer render options
  const options = {
    id: shortId.generate(),
    plotAsOutline: type === 'out'
  }

  const converter = gerberToSvg(filestream, options, (error) => {
    if (error) return done(error)

    // pcb-stackup-core uses the gerberToSvg converter and the
    // whats-that-gerber type to build the stackup
    done(null, {converter, type})
  })
}

function writeStackupFiles (stackup, done) {
  const tasks = ['top', 'bottom'].map((side) => (next) => {
    fs.writeFile(`${OUTPUT_PREFIX}-${side}.svg`, stackup[side].svg, next)
  })

  runParallel(tasks, done)
}
