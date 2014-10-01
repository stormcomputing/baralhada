
expect = require('chai').expect

model = require '../app/model'
services = require '../app/services'

repo = new services.SimpleRepository
service = new services.Service repo

withTableAndPlayers = (callback) ->
  service.newTable (table) ->
    service.newPlayer name: 'Player 1', (player1) ->
      service.newPlayer name: 'Player 2', (player2) ->
        setTimeout callback, 1, table, player1, player2

withNewHand = (callback) ->
  withTableAndPlayers (table1, player1, player2) ->
    service.joinTable table1.id, table1.secret, player1.id, player1.secret, (table2) ->
      service.joinTable table1.id, table1.secret, player2.id, player2.secret, (table3) ->
        service.newHand table1.id, table1.secret, (hand) ->
          setTimeout callback, 1, table3, hand, player1, player2

describe 'the services', ->

  it 'should create new tables', (done) ->
    service.newTable (table) ->
      expect(table).to.exist
      done()

  it 'should create players with player name', (done) ->
    service.newPlayer name: 'Player Name', (player) ->
      expect(player).to.exist
      done()

  it 'should allow players to join tables using its ids and private keys', (done) ->
    withTableAndPlayers (table1, player) ->
      service.joinTable table1.id, table1.secret, player.id, player.secret, (table2) ->
        expect(table1.id).to.equal table2.id
        expect(table2.players).to.have.property player.id
        done()

  it 'should start hands', (done) ->
    withNewHand (table, hand) ->
      expect(hand.table_id).to.equal table.id
      keys1 = (k for k,v of table.players)
      keys2 = (p.id for p in hand.table_players)
      expect(keys1).to.deep.equal keys2
      done()

  it 'should shuffle the deck', (done) ->
    withNewHand (table, hand) ->
      cards = new model.Hand(new model.Table).deck
      repo.getHand hand.id, (private_hand) ->
        expect(private_hand.deck).not.to.deep.equals(cards)
        expect(private_hand.deck).to.deep.have.members(cards)
        done()

  it 'should place community cards', (done) ->
    withNewHand (table, hand) ->
      service.placeCard hand.id, table.secret, (hand) ->
        expect(hand.community_cards).to.length 1
        service.placeCard hand.id, table.secret, (hand) ->
          expect(hand.community_cards).to.length 2
          done()

  it 'should deal pocket cards', (done) ->
    withNewHand (table, hand, player) ->
      service.dealCard hand.id, table.secret, player.id, (hand) ->
        expect(hand.pocket_cards[player.id]).to.length 1
        service.dealCard hand.id, table.secret, player.id, (hand) ->
          expect(hand.pocket_cards[player.id]).to.length 2
          expect(hand.pocket_cards[player.id][0]).to.have.property 'cipher'
          expect(hand.pocket_cards[player.id][1]).to.have.property 'cipher'
          done()

  it 'should reveal pocket cards', (done) ->
    withNewHand (table, hand, player) ->
      service.dealCard hand.id, table.secret, player.id, (hand) ->
        expect(hand.pocket_cards[player.id]).to.length 1
        service.dealCard hand.id, table.secret, player.id, (hand) ->
          expect(hand.pocket_cards[player.id]).to.length 2
          expect(hand.pocket_cards[player.id][0]).to.have.property 'cipher'
          expect(hand.pocket_cards[player.id][1]).to.have.property 'cipher'
          service.revealCards hand.id, table.secret, player.id, player.secret, (hand) ->
            expect(hand.pocket_cards[player.id][0]).to.have.property 'suit'
            expect(hand.pocket_cards[player.id][0]).to.have.property 'number'
            expect(hand.pocket_cards[player.id][1]).to.have.property 'suit'
            expect(hand.pocket_cards[player.id][1]).to.have.property 'number'
            done()
