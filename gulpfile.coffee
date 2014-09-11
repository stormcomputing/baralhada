
gulp = require 'gulp'
karma = require('karma').server
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

gulp.task 'coffeeify', ->
  gulp
    .src ['src/test/karma.coffee'], read: false
    .pipe plugins.browserify
      debug: true
      transform: ['coffeeify']
      extensions: ['.coffee']
    .pipe plugins.rename suffix: '.coffeeify', extname: '.js'
    .pipe gulp.dest 'target/test'

gulp.task 'karma', ['coffeeify'], (done) ->
  config =
    browsers: ['Chrome']
    frameworks: ['mocha']
    files: ['target/test/karma.coffeeify.js']
    client: mocha: reporter: ['html']

  karma.start config, done

gulp.task 'watch', ->
  gulp.watch 'src/**/*.coffee', ['coffeeify','mocha']

gulp.task 'default', ['coffeelint','mocha'], ->
