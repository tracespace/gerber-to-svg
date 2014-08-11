gulp       = require 'gulp'
gutil      = require 'gulp-util'
mocha      = require 'gulp-mocha'
coffee     = require 'gulp-coffee'
browserify = require 'browserify'
coffeeify  = require 'coffeeify'
source     = require 'vinyl-source-stream'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'
streamify  = require 'gulp-streamify'
stat       = require 'node-static'

# application entry point to generate standalone library
ENTRY = './src/gerber-to-svg.coffee'
DIST = 'gerber-to-svg'
DISTDIR = './dist'
NAME = 'gerberToSvg'

# source code and destination code locations
SRCDIR = './src/*.coffee'
LIBDIR = './lib'

gulp.task 'default', [ 'standalone' ], ->
  gulp.src SRCDIR
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

gulp.task 'test', ->
  gulp.src './test/*_test.coffee', { read: false }
    .pipe mocha {
      reporter: 'spec'
      globals: {
        should: require('should')
        coffee: require('coffee-script/register')
        stack: Error.stackTraceLimit = 3
      }
    }

gulp.task 'testwatch', ['test', 'default'], ->
  gulp.watch ['./src/*', './test/*'], ['test', 'default']

gulp.task 'testvisual', [ 'default' ], ->
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
