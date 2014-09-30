
sjcl = require 'sjcl'
model = require './model'

u =
  random: (max) -> Math.floor Math.random() * (max + 1)
  shuffle:  (set) ->
    shuffled = []
    for index in [0..set.length-1]
      rand = @random index
      shuffled[index] = shuffled[rand] if rand != index
      shuffled[rand] = set[index]
    return shuffled
  encrypt: (object, password) ->
    json = JSON.stringify object
    encrypt = sjcl.encrypt password, json
    JSON.parse encrypt

module.exports.PlayerView = class PlayerView
  constructor: (player) ->
    @id = player.id
    @name = player.name

module.exports.TableView = class TableView
  constructor: (table) ->
    @id = table.id
    @secret = table.secret
    @players = {}
    @players[k] = new PlayerView p for k,p of table.players

module.exports.HandView = class HandView
  constructor: (hand) ->
    @id = hand.id
    @table_id = hand.table.id
    @table_players = (new PlayerView p for k,p of hand.table.players)
    @community_cards = hand.community_cards or []
    @pocket_cards = {}
    for player_id, cards of hand.pocket_cards
      reveal = hand.reveals?.indexOf(player_id) >= 0
      player_secret = hand.table.players[player_id].secret
      @pocket_cards[player_id] = []
      for c in cards
        @pocket_cards[player_id].push if reveal then c else u.encrypt c, player_secret

module.exports.Service = class Service

  constructor: (@repository, @dispatcher) ->

  newTable: (callback) ->

    table = new model.Table

    @repository.setTable table, callback

  newPlayer: (name, img, callback) ->

    player = new model.Player name, img

    @repository.setPlayer player, callback

  withTable: (table_id, table_secret, callback) ->
    @repository.getTable table_id, (table) ->
      throw new Error("table not found (table_id: #{table_id})") if not table
      throw new Error("invalid table_secret") unless table.secret == table_secret
      callback table

  withPlayer: (player_id, player_secret, callback) ->
    @repository.getPlayer player_id, (player) ->
      throw new Error("player not found (player_id: #{player_id})") if not player
      throw new Error("invalid player_secret") unless player.secret == player_secret
      callback player

  withHand: (hand_id, table_secret, callback) ->
    @repository.getHand hand_id, (hand) =>
      throw new Error("hand not found (hand_id: #{hand_id})") if not hand
      @withTable hand.table.id, table_secret, (table) ->
        callback hand

  joinTable: (table_id, table_secret, player_id, player_secret, callback) ->
    @withPlayer player_id, player_secret, (player) =>
      @withTable table_id, table_secret, (table) =>
        table.players ?= {}
        table.players[player.id] = player
        callback new TableView table
        @repository.setTable table

  updateHand: (hand, callback) ->
    hand_view = new HandView hand
    callback? hand_view
    @dispatcher? hand_view
    @repository.setHand hand

  newHand: (table_id, table_secret, callback) ->
    @withTable table_id, table_secret, (table) =>
      hand = new model.Hand table
      hand.deck = u.shuffle hand.deck
      @updateHand hand, callback

  dealCard: (hand_id, table_secret, player_id, callback) ->
    @withHand hand_id, table_secret, (hand) =>
      @repository.getPlayer player_id, (player) =>
        card = hand.deck.pop()
        hand.pocket_cards ?= {}
        hand.pocket_cards[player.id] ?= []
        hand.pocket_cards[player.id].push card
        @updateHand hand, callback

  revealCards: (hand_id, table_secret, player_id, player_secret, callback) ->
    @withHand hand_id, table_secret, (hand) =>
      @withPlayer player_id, player_secret, (player) =>
        hand.reveals ?= []
        hand.reveals.push player.id
        @updateHand hand, callback

  placeCard: (hand_id, table_secret, callback) ->
    @withHand hand_id, table_secret, (hand) =>
      card = hand.deck.pop()
      hand.community_cards ?= []
      hand.community_cards.push card
      @updateHand hand, callback

module.exports.SimpleRepository = class SimpleRepository
  constructor: -> @storage = {}
  set: (obj, callback) ->
    @storage[obj.id] = obj
    callback? obj

  get: (id, callback) -> callback @storage[id]
  setHand: (hand, callback) -> @set hand, callback
  setTable: (table, callback) -> @set table, callback
  setPlayer: (player, callback) -> @set player, callback
  getHand: (hand_id, callback) -> @get hand_id, callback
  getTable: (table_id, callback) -> @get table_id, callback
  getPlayer: (player_id, callback) -> @get player_id, callback
