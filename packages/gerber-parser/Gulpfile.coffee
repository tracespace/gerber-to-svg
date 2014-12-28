gulp       = require 'gulp'
gutil      = require 'gulp-util'
mocha      = require 'gulp-mocha'
coveralls  = require 'gulp-coveralls'
coffee     = require 'gulp-coffee'
istanbul   = require 'gulp-coffee-istanbul'
browserify = require 'browserify'
coffeeify  = require 'coffeeify'
source     = require 'vinyl-source-stream'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'
streamify  = require 'gulp-streamify'
stat       = require 'node-static'

spawn = require('child_process').spawn
glob = require 'glob'

# application entry point to generate standalone library
ENTRY = './src/gerber-to-svg.coffee'
DIST = 'gerber-to-svg'
DISTDIR = './dist'
NAME = 'gerberToSvg'

# source code and destination code locations
SRC = './src/*.coffee'
TEST = './test/*_test.coffee'
LIBDIR = './lib'

# plugin options
MOCHA_OPTS = {
  reporter: 'spec'
  globals: {
    coffee: require 'coffee-script/register'
    stack: Error.stackTraceLimit = 3
  }
}

ZUUL_OPTS = [ '--concurrency', 2 ]

gulp.task 'default', ->
  gulp.src SRC
    .pipe coffee()
      .on 'error', gutil.log
    .pipe gulp.dest LIBDIR

gulp.task 'standalone', ->
  browserify ENTRY, {
      extensions: [ '.coffee' ]
      standalone: NAME
    }
    .transform 'coffeeify'
    .bundle()
      .on 'error', gutil.log
    .pipe source DIST+'.js'
    .pipe gulp.dest DISTDIR
    .pipe rename DIST+'.min.js'
    .pipe streamify uglify {
      output: {
        preamble: '/* copyright 2014 by mike cousins; shared under the terms of
        the MIT license. Source code available at
        github.com/mcous/gerber-to-svg */'
      }
      compress: { drop_console: true }
      mangle: true
    }
    .pipe gulp.dest DISTDIR

gulp.task 'build', [ 'default', 'standalone' ]

gulp.task 'watch', [ 'build' ], ->
  gulp.watch [ './src/*' ] , [ 'build' ]

# this is also ugly but it works
gulp.task 'test', (cb) ->
  gulp.src SRC
    .pipe istanbul { includeUntested: true }
    .pipe istanbul.hookRequire()
    .on 'finish', ->
      gulp.src TEST, { read: false }
        .pipe mocha MOCHA_OPTS
        .on 'error', (e) ->
          if e.name is 'SyntaxError'
            gutil.log e.stack 
          else 
            gutil.log e.message
          @emit 'end'
        .pipe istanbul.writeReports { reporters: [ 'lcov', 'text-summary' ] }
        .on 'end', cb
    # return null so that cb fires correctly
    null
        
gulp.task 'coveralls', [ 'test' ], ->
  gulp.src './coverage/lcov.info'
    .pipe coveralls()

gulp.task 'browsers', (cb) ->
  glob TEST, (err, files) ->
    if err? then cb err
    else if files?
      ZUUL_OPTS.push files...
      child = spawn "zuul", ZUUL_OPTS, { stdio: 'inherit' }
      child.on 'close', (code) ->
        gutil.log "browser tests completed"
        cb()
  null
    
gulp.task 'travis', [ 'test', 'coveralls' ], ->

gulp.task 'testwatch', ['test' ], ->
  gulp.watch ['./src/*', './test/*'], ['test', 'default']

gulp.task 'testvisual', [ 'watch' ], ->
  server = new stat.Server '.'
  require('http').createServer( (request, response) ->
    request.addListener( 'end', ->
      if request.url is '/'
        server.serveFile '/test/index.html', 200, {}, request, response
        gutil.log "served #{request.url}"
      else
        server.serve(request, response, (error, result)->
          if error then gutil.log "error serving #{request.url}"
          else gutil.log "served #{request.url}"
        )
    ).resume()
  ).listen 4242
  gutil.log "test server started at http://localhost:4242\n"
