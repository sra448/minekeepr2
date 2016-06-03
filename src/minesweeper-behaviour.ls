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
    .scan remember-board-size, [0, DEFAULT_DIFFICULTY]

# the game observer combines all of the above

observe-game = do
  game-resets
    .flat-map-latest game-interactions
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
