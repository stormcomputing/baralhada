
CARDS =
  X: X: '🂠'
  S: A:'🂡',2:'🂢',3:'🂣',4:'🂤',5:'🂥',6:'🂦',7:'🂧',8:'🂨',9:'🂩',T:'🂪',J:'🂫',Q:'🂭',K:'🂮'
  H: A:'🂱',2:'🂲',3:'🂳',4:'🂴',5:'🂵',6:'🂶',7:'🂷',8:'🂸',9:'🂹',T:'🂺',J:'🂻',Q:'🂽',K:'🂾'
  D: A:'🃁',2:'🃂',3:'🃃',4:'🃄',5:'🃅',6:'🃆',7:'🃇',8:'🃈',9:'🃉',T:'🃊',J:'🃋',Q:'🃍',K:'🃎'
  C: A:'🃑',2:'🃒',3:'🃓',4:'🃔',5:'🃕',6:'🃖',7:'🃗',8:'🃘',9:'🃙',T:'🃚',J:'🃛',Q:'🃝',K:'🃞'

app = angular.module 'baralhada', ['firebase']

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

  $scope.decript = (encrypted, player_secret) ->
    string = angular.toJson encrypted
    try
      angular.fromJson sjcl.decrypt player_secret, string
    catch err
      {suit: 'X', number: 'X'}

  $scope.toUnicode = (card) -> CARDS[card.suit][card.number]

  $scope.$root.$watch 'table', (table) ->
    if table
      ref = new Firebase("https://baralhada-public.firebaseio.com/#{table.id}")
      $scope.$root.hand = $firebase(ref).$asObject()

app.controller 'TableCtrl', ($scope, $http) ->

  $scope.newTable = ->
    $http.post '/table'
      .success (table) ->
        $scope.$root.table = table
        $scope.table_id = table.id
        $scope.table_secret = table.secret

  $scope.viewTable = (table_id) ->
    $scope.$root.table = table: id: table_id

  $scope.joinTable = (table_id, table_secret, player_id, player_secret) ->
    data = join: {table_id, table_secret, player_id, player_secret}
    $http.post "/table/#{table_id}", data
      .success (table) -> $scope.$root.table = table

app.controller 'PlayerCtrl', ($scope, $http) ->

  $scope.newPlayer = (player_name) ->
    data = name: player_name
    $http.post '/player', data
      .success (player) -> $scope.$root.player = player
