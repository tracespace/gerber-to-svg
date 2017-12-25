// simple visual test server for gerber-to-svg
'use strict'

const fs = require('fs')
const path = require('path')
const express = require('express')
const template = require('lodash/template')
const runParallel = require('run-parallel')
const runWaterfall = require('run-waterfall')

const getGerbers = require('../../fixtures/get-gerbers')
const gerberToSvg = require('../../packages/gerber-to-svg')

const PORT = 8001
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
  console.log(`gerber-to-svg server listening at http://localhost:${PORT}`)
})

function handleTestRun (done) {
  runWaterfall([
    getGerbers,
    readAllTestFiles,
    runTemplate
  ], done)
}

function readAllTestFiles (gerbers, done) {
  runParallel(
    gerbers.map((gerber) => (next) => renderGerber(gerber, next)),
    done
  )
}

function renderGerber (gerber, done) {
  const renderOptions = {id: gerber.name, optimizePaths: true}

  gerberToSvg(gerber.contents, renderOptions, (error, render) => {
    if (error) return done(error)

    done(null, Object.assign({render}, gerber))
  })
}

function runTemplate (tests, done) {
  fs.readFile(TEMPLATE, 'utf8', (error, templateText) => {
    if (error) return done(error)

    try {
      done(null, template(templateText)({suite: testsToSuite(tests)}))
    } catch (error) {
      done(error)
    }
  })
}

function testsToSuite (tests) {
  return tests.reduce((result, test) => {
    const {category} = test

    if (result.categories.indexOf(category) < 0) {
      result.categories.push(category)
      result.categoriesByName[category] = [test]
    } else {
      result.categoriesByName[category].push(test)
    }

    return result
  }, {categories: [], categoriesByName: {}})
}
