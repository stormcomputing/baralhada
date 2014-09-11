
#3pp libs
request = require 'supertest'
expect = require('chai').expect

#application scripts
services = require '../app/services'

describe 'the resources', ->

  repo = new services.SimpleRepository
  service = new services.Service repo

  app = require '../app/resources'
  app.delegate = service

  ctx = {}
  ctx.players = []

  it 'should POST /table', (done) ->
    request(app)
      .post '/table'
      .expect 'Content-Type', /json/
      .expect 'Content-Length', 50
      .expect 201, (error, response) ->
        ctx.table = response.body
        done()

  it 'should POST /player (1)', (done) ->
    request(app)
      .post '/player'
      .send name: 'Test Player 1'
      .expect 'Content-Type', /json/
      .expect 'Content-Length', 60
      .expect 201, (error, response) ->
        ctx.players.push response.body
        done()

  it 'should POST /player (2)', (done) ->
    request(app)
      .post '/player'
      .send name: 'Test Player 2'
      .expect 'Content-Type', /json/
      .expect 'Content-Length', 60
      .expect 201, (error, response) ->
        ctx.players.push response.body
        done()

  it 'should POST /player (3)', (done) ->
    request(app)
      .post '/player'
      .send name: 'Test Player 3'
      .expect 'Content-Type', /json/
      .expect 'Content-Length', 60
      .expect 201, (error, response) ->
        ctx.players.push response.body
        done()

  it 'should POST /table/:table_id (1) to add players', (done) ->

    join = (idx, size, cb) ->

      request(app)
        .post "/table/#{ctx.table.id}"
        .send
          join:
            table_id: ctx.table.id
            table_secret: ctx.table.secret
            player_id: ctx.players[idx].id
            player_secret: ctx.players[idx].secret
        .expect 'Content-Type', /json/
        .expect 'Content-Length', size
        .expect 200, cb

    join 0, 101, -> join 1, 153, -> join 2, 205, done

  it 'should start hands', (done) ->

    request(app)
      .post "/table/#{ctx.table.id}/hands"
      .send start: table_secret: ctx.table.secret
      .expect 'Content-Type', /json/
      .expect 'Content-Length', 219
      .expect 201, (error, response) ->
        ctx.hand = response.body
        done()

  it 'should place community cards', (done) ->

    request(app)
      .post "/hand/#{ctx.hand.id}"
      .send place: table_secret: ctx.table.secret
      .expect 'Content-Type', /json/
      .expect 'Content-Length', 244
      .expect 201, done

  it 'should deal pocket cards', (done) ->

    request(app)
      .post "/hand/#{ctx.hand.id}"
      .send deal: player_id: ctx.players[0].id, table_secret: ctx.table.secret
      .expect 'Content-Type', /json/
      .expect 'Content-Length', 438
      .expect 201, done
