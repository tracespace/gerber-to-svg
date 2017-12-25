// simple visual test server for pcb-stackup-core
'use strict'

const fs = require('fs')
const path = require('path')
const express = require('express')
const runParallel = require('run-parallel')
const runWaterfall = require('run-waterfall')
const shortId = require('shortid')
const template = require('lodash/template')

const getBoards = require('../../fixtures/get-boards')
const gerberToSvg = require('../../packages/gerber-to-svg')
const pcbStackupCore = require('../../packages/pcb-stackup-core')

const PORT = 8002
const TEMPLATE = path.join(__dirname, 'index.template.html')

const app = express()

app.get('/', (request, response) => {
  handleTestRun((error, result) => {
    if (error) {
      console.error(error)
      return response.status(500).send({error: error.message})
    }

    response.send(result)
  })
})

app.listen(PORT, () => {
  console.log(`pcb-stackup-core server listening at http://localhost:${PORT}`)
})

function handleTestRun (done) {
  runWaterfall([
    getBoards,
    renderAllStackups,
    runTemplate
  ], done)
}

function renderAllStackups (boards, done) {
  runParallel(
    boards.map((board) => (next) => renderStackup(board, next)),
    done
  )
}

function renderStackup (board, done) {
  const options = {
    id: shortId.generate(),
    maskWithOutline: true
  }

  runParallel(
    board.layers.map((layer) => (next) => renderLayer(layer, next)),
    (error, layers) => {
      if (error) return done(error)

      try {
        const stackup = pcbStackupCore(layers, options)
        done(null, Object.assign({stackup}, board))
      } catch (error) {
        done(error)
      }
    }
  )
}

function renderLayer (layer, done) {
  const {type} = layer
  const options = {
    id: shortId.generate(),
    plotAsOutline: type === 'out'
  }

  const converter = gerberToSvg(layer.contents, options, (error) => {
    if (error) return done(error)

    done(null, {converter, type})
  })
}

function runTemplate (boards, done) {
  fs.readFile(TEMPLATE, 'utf8', (error, templateText) => {
    if (error) return done(error)

    try {
      done(null, template(templateText)({boards}))
    } catch (error) {
      done(error)
    }
  })
}
