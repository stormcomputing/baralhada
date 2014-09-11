
gulp = require 'gulp'
plugins = require('gulp-load-plugins')()

gulp.task 'coffeelint', ->
  gulp
    .src ['src/**/*.coffee']
    .pipe plugins.coffeelint()
    .pipe plugins.coffeelint.reporter()

gulp.task 'mocha', ->
  gulp
    .src ['src/test/*.coffee'], read: false
    .pipe plugins.mocha()

gulp.task 'watch', ->
  gulp.watch 'src/**/*.coffee', ['mocha']

gulp.task 'default', ['coffeelint','mocha'], ->
