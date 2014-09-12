
gulp = require 'gulp'
karma = require('karma').server
plugins = require('gulp-load-plugins')()
browserSync = require 'browser-sync'

gulp.task 'browser-sync', ->
  browserSync
    open: false
    ghostMode: false
    server: baseDir: 'target/ui'

gulp.task 'coffeelint', ->
  gulp
    .src ['src/**/*.coffee']
    .pipe plugins.coffeelint()
    .pipe plugins.coffeelint.reporter()

gulp.task 'mocha', ->
  gulp
    .src ['src/test/*.coffee'], read: false
    .pipe plugins.mocha()

gulp.task 'jade', ->
  gulp
    .src ['src/ui/*.jade']
    .pipe plugins.jade()
    .pipe gulp.dest 'target/ui'

gulp.task 'coffee', ->
  gulp
    .src ['src/**/*.coffee']
    .pipe plugins.coffee()
    .pipe gulp.dest 'target'

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

gulp.task 'watch', ['browser-sync'], ->
  reload = browserSync.reload
  gulp.watch 'src/ui/*.jade', ['jade',reload]
  gulp.watch 'src/**/*.coffee', ['coffee','coffeeify','mocha',reload]

gulp.task 'default', ['coffee','jade','coffeelint','mocha'], ->
