React-DOM = require \react-dom
Rx = require \rx

game-ui = require \./minesweeper-ui.ls
{update-game-state} = require \./minesweeper-logic.ls

const BOARD_EASY = [10, 10, 9]
const BOARD_MEDIUM = [16, 16, 40]
const BOARD_HARD = [30, 20, 99]
const HTML_CONTAINER = document.get-element-by-id \container

time-increments = do
  Rx.Observable.interval 1000
    .map -> [\increment-time]

player-clicks = do
  Rx.Observable
    .fromEvent HTML_CONTAINER, \click
    .filter (.target.id)

player-resets-game = do
  player-clicks
    .filter -> /^reset/.test it.target.id
    .map -> [\reset-game, BOARD_MEDIUM]
    .start-with [\reset-game, BOARD_MEDIUM]

player-reveals-field = do
  player-clicks
    .filter -> /^[0-9]+/.test it.target.id
    .map -> [\reveal-field, +it.target.id]

player-toggles-cell = do
  Rx.Observable
    .fromEvent HTML_CONTAINER, \contextmenu
    .filter (.target.id)
    .do -> it.preventDefault()
    .map -> [\toggle-field-flag, +it.target.id]

player-starts-game = do
  player-reveals-field.take 1

player-acting = do
  Rx.Observable
    .merge [time-increments, player-reveals-field, player-toggles-cell]

render-game = (world) ->
  React-DOM.render (game-ui {world}), HTML_CONTAINER

player-resets-game
  # .flat-map-latest -> player-starts-game
  .flat-map ->
    Rx.Observable.merge [(Rx.Observable.return it), player-acting]
  .scan update-game-state, 0
  .subscribe render-game
