gulp = require 'gulp'
gutil = require 'gulp-util'
mocha = require 'gulp-mocha'
coffee = require 'gulp-coffee'

SRCDIR = './src/*.coffee'
DESTDIR = './lib'

gulp.task 'default', ->
  gulp.src SRCDIR
    .pipe coffee()
      .on 'error', gutil.log
    .pipe gulp.dest DESTDIR

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
