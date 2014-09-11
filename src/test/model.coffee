
model = require '../app/model'

expect = require('chai').expect

describe 'the model', ->

  UID_PATTERN = /[\d\w]{8}/

  it 'should have the following public types: Card Player Table Hand', ->
    expect(model.Card).to.exist
    expect(model.Hand).to.exist
    expect(model.Table).to.exist
    expect(model.Player).to.exist

  it 'should cards with number and suit', ->
    card = new model.Card 'X', 'X'
    expect(card.suit).to.equal 'X'
    expect(card.number).to.equal 'X'

  it 'should create players with id and secret', ->
    player = new model.Player
    expect(player.id).to.match UID_PATTERN
    expect(player.secret).to.match UID_PATTERN

  it 'should create tables with id and secret', ->
    table = new model.Table
    expect(table.id).to.match UID_PATTERN
    expect(table.secret).to.match UID_PATTERN

  describe 'the hands', ->

    table = new model.Table
    hand = new model.Hand  table

    it 'requires a parent table', ->
      expect(hand.table).to.equal table
    it 'has a standard deck', ->
      expect(hand.deck).to.length 52
    it 'has a unique id', ->
      expect(hand.id).to.match UID_PATTERN
