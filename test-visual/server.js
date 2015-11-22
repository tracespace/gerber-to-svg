// visual test server
'use strict'

var fs = require('fs')
var path = require('path')
var walk = require('walk')
var hapi = require('hapi')
var inert = require('inert')
var async = require('async')
var partial = require('lodash.partial')
var template = require('lodash.template')

var gerberToSvg = require('../lib/gerber-to-svg')

var PORT = 4242
var GERBER_DIR = 'gerber'
var EXPECTED_DIR = 'expected'
var TEMPLATE = 'index.html.template'

var compiledTemplate = template(fs.readFileSync(path.join(__dirname, TEMPLATE)))
var server = new hapi.Server()

var readGerber = function(gerberFile, done) {
  fs.readFile(gerberFile, 'utf8', done)
}

var renderGerber = function(gerberFile, done) {
  gerberToSvg(fs.createReadStream(gerberFile), path.basename(gerberFile), done)
}

var getExpected = function(gerberFile, done) {
  var base = path.basename(gerberFile, '.gbr')
  var dir = path.dirname(gerberFile).replace(GERBER_DIR + '/', EXPECTED_DIR + '/')
  var expected = path.join(dir, base + '.svg')

  fs.readFile(expected, 'utf8', done)
}

var renderTestFiles = function(done) {
  var walker = walk.walk(path.join(__dirname, GERBER_DIR))
  var results = {}

  walker.on('file', function(dir, stats, next) {
    var category = path.basename(dir).split('-').join(' ')
    var file = path.join(dir, stats.name)

    // only grab gerbers
    if (path.extname(file) !== '.gbr') {
      return next()
    }

    async.parallel({
      gerber: partial(readGerber, file),
      render: partial(renderGerber, file),
      expected: partial(getExpected, file)
    }, function(error, result) {
      if (error) {
        console.error(error.message)
      }

      result.name = path.basename(stats.name, '.gbr').split('-').join(' ')

      results[category] = results[category] || []
      results[category].push(result)
      next()
    })
  })

  walker.once('end', function() {
    done(null, results)
  })
}

server.connection({
  port: PORT
})

server.register(inert, function(error) {
  if (error) {
    throw error
  }

  server.route({
    method: 'GET',
    path: '/',
    handler: function(request, reply) {
      renderTestFiles(function(error, suite) {
        if (error) {
          return reply(error)
        }
        reply(compiledTemplate({suite: suite}))
      })
    }
  })

  server.route({
    method: 'GET',
    path: '/style.css',
    handler: {
      file: path.join(__dirname, 'style.css')
    }
  })

  server.start(function() {
    console.log('visual test server running at:', server.info.uri)
  })
})
