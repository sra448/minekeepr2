Rx = require \rx
game-ui = require \./minesweeper-ui.ls
{update-game-state} = require \./minesweeper-logic.ls

# basic configuration

const DIFFICULTIES =
  easy: [10, 10, 9]
  medium: [16, 16, 40]
  hard: [30, 20, 99]
const DEFAULT_DIFFICULTY = DIFFICULTIES.medium

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
  size = board-size || DIFFICULTIES[difficulty]
  player-changes-difficulty.on-next difficulty
  player-changes-board.on-next [\reset-game, size]

reset-game = ->
  player-resets-game.on-next [\reset-game]

# internal observers

maybe-finish-game = (state) ->
  if (state.get \game-won) || (state.get \game-lost)
    game-is-finished.on-next true

game-interactions = ->
  interactions = Rx.Observable.merge [player-reveals-field, player-toggles-field]
  time-increments = interactions.first().flat-map ->
    Rx.Observable
      .interval 1000
      .map -> [\increment-time]

  Rx.Observable
    .merge [(Rx.Observable.return it), interactions, time-increments]
    .take-until game-is-finished

observe-difficulty = do
  player-changes-difficulty
    .start-with \medium

remember-board-size = ([_, prev-value], [action, value]) ->
  [action, value || prev-value]

game-starts = do
  Rx.Observable
    .merge [player-changes-board, player-resets-game]
    .scan remember-board-size, [0, DEFAULT_DIFFICULTY]
    .do -> game-is-finished.on-next true

observe-game = do
  game-starts
    .flat-map game-interactions
    .scan update-game-state, 0
    .do maybe-finish-game
    .combine-latest observe-difficulty, (world, difficulty) ->
      {world, difficulty}

module.exports = {
  observe-game
  reset-game
  change-board
  reveal-field
  toggle-field
}
