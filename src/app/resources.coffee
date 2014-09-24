
express = require 'express'
services = require './services'
bodyParser = require 'body-parser'

module.exports = app = express()
app.use bodyParser.json()

app.post '/table', (request,response) ->

  app.delegate.newTable (table_view) ->
    response
      .status 201
      .send table_view

app.post '/table/:table_id', (request,response) ->

  {table_id, table_secret, player_id, player_secret} = request.body.join

  app.delegate.joinTable table_id, table_secret, player_id, player_secret, (table_view) ->
    response.send table_view

app.post '/player', (request,response) ->

  {img, name} = request.body

  app.delegate.newPlayer name, img, (player) ->
    response
      .status 201
      .send player

app.post '/table/:table_id/hands', (request,response) ->

  table_id = request.params.table_id
  table_secret = request.body.start.table_secret

  app.delegate.newHand table_id, table_secret, (table_view) ->
    response
      .status 201
      .send table_view

app.post '/hand/:hand_id', (request,response) ->

  body = request.body
  hand_id = request.params.hand_id
  {table_secret} = body.place if body.place
  {table_secret,player_id} = body.deal if body.deal
  {table_secret,player_id,player_secret} = body.reveal if body.reveal

  callback = (table_view) ->
    response
      .status 201
      .send table_view

  switch
    when body.deal then app.delegate.dealCard hand_id, table_secret, player_id, callback
    when body.place then app.delegate.placeCard hand_id, table_secret, callback
    when body.reveal then app.delegate.revealCards hand_id, table_secret, player_id, player_secret, callback
