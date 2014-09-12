
express = require 'express'
Firebase = require 'firebase'

withFirebase = (appName, auth, path, doWithFirebase) ->
  ref = new Firebase "https://#{appName}.firebaseio.com#{path}"
  ref.auth auth
  doWithFirebase ref

withPrivate = (path, func) ->
  withFirebase 'baralhada-private', 'ChHi4CdeI0azOeS0W9AYaaCeqQLgcF3eTgr1I6D9', path, func

withPublic = (path, func) ->
  withFirebase 'baralhada-public', '6n14Glx450JLiOyJ0K2ZtfPWfJoCltEJTFDoQq3Y', path, func

class FirebaseRepository

  set: (collection, obj, callback) ->

    withPrivate "/#{collection}/#{obj.id}", (ref) ->
      ref.set obj, ->
        ref.unauth()
        callback? obj

  get: (collection, id, callback) ->

    withPrivate "/#{collection}/#{id}", (ref) ->
      ref.once 'value', (snapshot) ->
        obj = snapshot.val()
        ref.unauth()
        callback obj

  setHand: (hand, callback) -> @set 'hands', hand, callback
  setTable: (table, callback) -> @set 'tables', table, callback
  setPlayer: (player, callback) -> @set 'players', player, callback
  getHand: (hand_id, callback) -> @get 'hands', hand_id, callback
  getTable: (table_id, callback) -> @get 'tables', table_id, callback
  getPlayer: (player_id, callback) -> @get 'players', player_id, callback

FirebaseDispatcher = (obj) ->
  withPublic "/#{obj.table_id}", (ref) ->
    ref.set obj, -> ref.unauth()

services = require './services'
service = new services.Service new FirebaseRepository, FirebaseDispatcher

resources = require './resources'
resources.delegate = service
resources.use express.static "#{__dirname}/../../target/ui"
resources.listen 3000, -> console.log 'Listening on port 3000'
