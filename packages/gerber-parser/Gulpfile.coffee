gulp = require 'gulp'
gutil = require 'gulp-util'
mocha = require 'gulp-mocha'

gulp.task 'default', ->

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
