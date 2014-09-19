
requirejs.config
  paths:
    sjcl: '//bitwiseshiftleft.github.io/sjcl/sjcl'
    async: '//cdnjs.cloudflare.com/ajax/libs/requirejs-plugins/1.0.3/async.min'
    angular: '//ajax.googleapis.com/ajax/libs/angularjs/1.2.25/angular.min'
    firebase: '//cdn.firebase.com/js/client/1.0.21/firebase'
    angularfire: '//cdn.firebase.com/libs/angularfire/0.8.2/angularfire.min'

  shim:
    angular: exports: 'angular'
    angularfire: deps: ['angular','firebase']

define 'gapi', ['async!//apis.google.com/js/client.js!onload'], ->
  gapi.client.setApiKey 'AIzaSyB5_lIi7P3JCqFf5wzFywtsgeiHn1eNHTU'

define ['angular','sjcl','angularfire','gapi'], (angular, sjcl) ->

  app = angular.module 'baralhada', ['firebase']

  app.controller 'LoginCtrl', ($scope, $http) ->

    $scope.login = ->
      gapi.auth.authorize
        immediate: true
        scope: 'https://www.googleapis.com/auth/plus.me'
        client_id: '701172226637-i36kq61j3f8hf2figvk2o1aam9d8oblm.apps.googleusercontent.com'
        (auth) ->
          gapi.client.load 'plus', 'v1', ->
            gapi.client.plus.people.get(userId: 'me').execute (auth) ->

              $scope.$root.auth = auth
              $scope.$root.$digest()

              $http.post '/player', name: auth.displayName, img: auth.image.url
                .success (player) ->
                  $scope.$root.player = player
                  $scope.$root.$digest()

    $scope.login() # silent login

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

    $scope.$root.$watch 'table', (table) ->
      if table
        ref = new Firebase("http://baralhada-public.firebaseio.com/#{table.id}")
        $scope.$root.hand = $firebase(ref).$asObject()

  app.controller 'TableCtrl', ($scope, $http, $location) ->

    search = $location.search()
    $scope.table_id = search.table_id
    $scope.table_secret = search.table_secret

    $scope.newTable = ->
      $http.post '/table'
        .success (table) ->
          $scope.$root.table = table
          $scope.table_id = table.id
          $scope.table_secret = table.secret
          $location.search 'table_id', table.id
          $location.search 'table_secret', table.secret

    $scope.viewTable = (table_id) ->
      $scope.$root.table = id: table_id

    $scope.joinTable = (table_id, table_secret, player_id, player_secret) ->
      data = join: {table_id, table_secret, player_id, player_secret}
      $http.post "/table/#{table_id}", data
        .success (table) -> $scope.$root.table = table
