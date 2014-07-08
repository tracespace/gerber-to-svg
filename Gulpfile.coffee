gulp = require 'gulp'
gutil = require 'gulp-util'
mocha = require 'gulp-mocha'
coffee = require 'gulp-coffee'

SRCDIR = './coffee/*.coffee'
DESTDIR = './dist'

gulp.task 'default', ->
  gulp.src SRCDIR
    .pipe coffee()
      .on 'error', gutil.log
    .pipe gulp.dest DESTDIR

gulp.task 'test', ->
  gulp.src './test/*_test.coffee', { read: false }
    .pipe mocha {
      globals: {
        should: require('should')
        coffee: require('coffee-script/register')
      }
    }

gulp.task 'test:watch', ['test'], ->
  gulp.watch ['./src/*', './test/*'], ['test']
