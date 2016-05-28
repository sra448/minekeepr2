React-DOM = require \react-dom
Rx = require \rx

game-ui = require \./minesweeper-ui.ls
{update-game-state} = require \./minesweeper-logic.ls

const HTML_CONTAINER = document.get-element-by-id \container
const DIFFICULTIES =
  easy: [10, 10, 9]
  medium: [16, 16, 40]
  hard: [30, 20, 99]
const DEFAULT_DIFFICULTY = DIFFICULTIES.medium

clicks = Rx.Observable.from-event HTML_CONTAINER, \click
right-clicks = do
  Rx.Observable
    .from-event HTML_CONTAINER, \contextmenu
    .do -> it.preventDefault()

player-clicks = clicks.filter (.target.id)

player-reveals-field = do
  player-clicks
    .filter -> /^[0-9]+/.test it.target.id
    .map -> [\reveal-field, +it.target.id]

player-toggles-cell = do
  right-clicks
    .filter (.target.id)
    .map -> [\toggle-field-flag, +it.target.id]

stop-timer = new Rx.Subject
maybe-stop-timer = (state) ->
  if (state.get \game-won) || (state.get \game-lost)
    stop-timer.on-next true

player-resets-game = do
  player-clicks
    .filter -> /^reset/.test it.target.id
    .map -> [\reset-game, DIFFICULTIES[current-difficulty]]
    .start-with [\reset-game, DEFAULT_DIFFICULTY]

current-difficulty = \medium
change-board = new Rx.Subject
change-board-size = (difficulty, board-size) ->
  size = board-size || DIFFICULTIES[difficulty]
  if size?
    current-difficulty := difficulty
    change-board.on-next [\reset-game, size]
  else
    change-board.on-next [\reset-game, DIFFICULTIES[current-difficulty]]
    current-difficulty := difficulty

game-starts = do
  Rx.Observable
    .merge [change-board, player-resets-game]
    .do -> stop-timer.on-next true

render-game = (world) ->
    React-DOM.render (game-ui {world, current-difficulty, change-board-size}), HTML_CONTAINER

game-interactions = ->
  interactions = Rx.Observable.merge [player-reveals-field, player-toggles-cell]
  time-increments = interactions.first().flat-map ->
    Rx.Observable
      .interval 1000
      .map -> [\increment-time]
  Rx.Observable
    .merge [(Rx.Observable.return it), interactions, time-increments]
    .take-until stop-timer


game-starts
  .flat-map game-interactions
  .scan update-game-state, 0
  .do maybe-stop-timer
  .subscribe render-game
