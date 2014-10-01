
requirejs.config
  paths:
    css: '//cdnjs.cloudflare.com/ajax/libs/require-css/0.1.1/css'
    sjcl: '//bitwiseshiftleft.github.io/sjcl/sjcl'
    angular: '//ajax.googleapis.com/ajax/libs/angularjs/1.3.0-rc.3/angular'
    firebase: '//cdn.firebase.com/js/client/1.0.21/firebase'
    angularfire: '//cdn.firebase.com/libs/angularfire/0.8.2/angularfire'
  shim:
    sjcl: exports: 'sjcl'
    angular: exports: 'angular'
    angularfire: deps: ['angular','firebase']

define 'gapi', ['//apis.google.com/js/api.js'], ->
  load: (name, req, onload) -> gapi.load name, onload

define 'g', ->
  load: (name, req, onload) ->
    [api,version] = name.split ','
    req ['gapi!client'], ->
      gapi.client.load api, version, onload

define 'gapis', ['gapi!auth','g!plus,v1','g!urlshortener,v1'], ->

define 'styles', [
  'css!app'
  'css!//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap'
  'css!//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome'
]

define 'app', ['angular','sjcl','angularfire','gapis'], (angular, sjcl) ->

  app = angular.module 'baralhada', ['firebase']

  app.controller 'LoginCtrl', ($scope, $http) ->
    $scope.login = (immediate=false) ->
      gapi.auth.authorize
        immediate: immediate
        scope: 'https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/urlshortener'
        client_id: '701172226637-i36kq61j3f8hf2figvk2o1aam9d8oblm.apps.googleusercontent.com'
        (auth) -> if auth.status.signed_in
          gapi.client.plus.people.get(userId: 'me').execute (user) ->
            $scope.$root.user = user
            $scope.$root.$digest()
            console.log auth, user

      $scope.$root.$watch 'user', (user) -> if user
        $http.post '/player', id: user.id, name: user.displayName, img: user.image.url
          .success (player) -> $scope.$root.player = player

    $scope.login true # silent login

  app.controller 'HandCtrl', ($scope, $http, $firebase) ->

    $scope.newHand = (table_id, table_secret) ->
      data = start: table_secret: table_secret
      $http.post "/table/#{table_id}/hands", data

    $scope.placeCard = (hand_id, table_secret) ->
      data = place: table_secret: table_secret
      $http.post "/hand/#{hand_id}", data

    $scope.dealCard = (hand_id, table_secret, player_id) ->
      data = deal: player_id: player_id, table_secret: table_secret
      $http.post "/hand/#{hand_id}", data

    $scope.revealCards = (hand_id, table_secret, player_id, player_secret) ->
      data = reveal: player_id: player_id, table_secret: table_secret, player_secret: player_secret
      $http.post "/hand/#{hand_id}", data

    $scope.decript = (encrypted, player_secret) ->
      return encrypted if encrypted.suit and encrypted.number
      string = angular.toJson encrypted
      try
        angular.fromJson sjcl.decrypt player_secret, string
      catch err
        suit: 'X', number: 'X'

    $scope.$root.$watch 'table', (table) -> if table
      ref = new Firebase("http://baralhada-public.firebaseio.com/#{table.id}")
      $scope.$root.hand = $firebase(ref).$asObject()

  app.controller 'TableCtrl', ($scope, $http, $location) ->

    {table_id,table_secret} = $location.search()

    if table_id # view table
      $scope.$root.table = id: table_id
    else # create table
      $http.post('/table').success (table) -> $scope.$root.table = table

    $scope.$root.$watchGroup ['player', 'table'], (values) ->

      [player,table] = values
      table_secret ?= table?.secret

      if table

        url = $location.absUrl()
        urlshortener = (url, callback) ->
          request = gapi.client.urlshortener.url.insert resource: longUrl: url
          request.execute (response) ->
            callback response.id

        view_url = "#{url}#?table_id=#{table.id}"
        urlshortener view_url, (shortUrl) -> $scope.$root.view_url = shortUrl
        if table.secret
          share_url = "#{view_url}&table_secret=#{table.secret}"
          urlshortener share_url, (shortUrl) -> $scope.$root.share_url = shortUrl

      if player and table_secret and not table.players?[player.id] # join table

        data = join:
          table_id: table.id
          player_id: player.id
          table_secret: table_secret
          player_secret: player.secret

        $http.post "/table/#{table.id}", data
          .success (table) -> $scope.$root.table = table

define ['angular','app','styles'], (angular) ->
  angular.bootstrap document, ['baralhada']
