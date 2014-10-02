
SUITS = ['S','H','D','C']
NUMBERS = ['2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A']

uid = ->
  s4 = -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
  s4() + s4()

module.exports.Card = class Card
  constructor: (@number, @suit) ->

module.exports.Player = class Player
  constructor: (@name, @img) ->
    @id = uid()
    @secret = uid()

module.exports.Table = class Table
  constructor: ->
    @id = uid()
    @secret = uid()
    @players = {}

module.exports.Hand = class Hand
  constructor: (@table) ->
    @id = uid()
    @deck = []
    @deck.push new Card number, suit for number in NUMBERS for suit in SUITS
    @pocket_cards = {}
    @community_cards = []
