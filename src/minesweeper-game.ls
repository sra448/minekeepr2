Rx = require \rx
{reset-game, increment-time, reveal-field, toggle-field-flag} = require \./minesweeper-logic.ls

# dispatch actions

update-game-state = (state, [action, value]) ->
  switch action
    case \reset-game then reset-game value
    case \increment-time then increment-time state
    case \reveal-field then check-game-won <| reveal-field state, value
    case \toggle-field-flag then toggle-field-flag state, value
    default state

module.exports = ({difficulties, default-difficulty}) ->

  # subjects for interacting with a running game

  player-reveals-field = new Rx.Subject
  player-toggles-field = new Rx.Subject
  player-changes-difficulty = new Rx.Subject
  player-changes-board = new Rx.Subject
  player-resets-game = new Rx.Subject
  game-is-finished = new Rx.Subject

  # public actions

  reveal-field = (id) ->
    player-reveals-field.on-next [\reveal-field, id]

  toggle-field = (id) ->
    player-toggles-field.on-next [\toggle-field-flag, id]

  change-board = (difficulty, board-size) ->
    size = board-size || difficulties[difficulty]
    player-changes-difficulty.on-next difficulty
    player-changes-board.on-next [\reset-game, size]

  reset-game = ->
    player-resets-game.on-next [\reset-game]

  # internal observers

  time-increments = do
    Rx.Observable
      .interval 1000
      .map -> [\increment-time]

  game-interactions = ->
    interactions = Rx.Observable.merge [player-reveals-field, player-toggles-field]
    game-time-increments = interactions.first().flat-map -> time-increments
    Rx.Observable
      .merge [(Rx.Observable.return it), interactions, game-time-increments]
      .take-until game-is-finished

  observe-difficulty = do
    player-changes-difficulty
      .start-with \medium

  remember-board-size = ([_, prev-value], [action, value]) ->
    [action, value || prev-value]

  maybe-finish-game = (state) ->
    if (state.get \game-won) || (state.get \game-lost)
      game-is-finished.on-next true

  game-resets = do
    Rx.Observable
      .merge [player-changes-board, player-resets-game]
      .scan remember-board-size, [0, difficulties[default-difficulty]]

  # the game observer combines all of the above

  observe-game = do
    game-resets
      .flat-map-latest game-interactions
      .scan update-game-state, 0
      .do maybe-finish-game
      .combine-latest observe-difficulty, (world, difficulty) ->
        {world, difficulty}

  # return the instance of the game

  return {
    reset: reset-game
    change-board: change-board
    reveal-field: reveal-field
    toggle-field: toggle-field
    subscribe: (fn) -> observe-game.subscribe fn
  }
