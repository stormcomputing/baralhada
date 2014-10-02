
express = require 'express'
services = require './services'

module.exports = router = express.Router()

router.post '/table', (request,response) ->

  router.delegate.newTable (table_view) ->
    response
      .status 201
      .send table_view

router.post '/table/:table_id', (request,response) ->

  table_id = request.params.table_id
  {table_secret, player_id, player_secret} = request.body.join

  router.delegate.joinTable table_id, table_secret, player_id, player_secret, (table_view) ->
    response.send table_view

router.post '/player', (request,response) ->

  {img, name} = request.body

  router.delegate.newPlayer name, img, (player) ->
    response
      .status 201
      .send player

router.post '/table/:table_id/hands', (request,response) ->

  table_id = request.params.table_id
  table_secret = request.body.start.table_secret

  router.delegate.newHand table_id, table_secret, (table_view) ->
    response
      .status 201
      .send table_view

router.post '/hand/:hand_id', (request,response) ->

  body = request.body
  hand_id = request.params.hand_id
  {table_secret} = body.place if body.place
  {table_secret,player_id} = body.deal if body.deal
  {table_secret,player_id,player_secret,card_idx} = body.reveal if body.reveal

  callback = (table_view) ->
    response
      .status 201
      .send table_view

  switch
    when body.deal then router.delegate.dealCard hand_id, table_secret, player_id, callback
    when body.place then router.delegate.placeCard hand_id, table_secret, callback
    when body.reveal then router.delegate.revealCard hand_id, table_secret, player_id, player_secret, card_idx, callback
