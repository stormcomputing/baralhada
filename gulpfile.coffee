
gulp = require 'gulp'
plugins = require('gulp-load-plugins')()

gulp.task 'mocha', ->
  gulp
    .src ['src/test/*.coffee'], read: false
    .pipe plugins.mocha()

gulp.task 'watch', ->
  gulp.watch 'src/**/*.coffee', ['mocha']

gulp.task 'default', ['mocha'], ->
