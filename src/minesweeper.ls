React-DOM = require \react-dom

game-ui = require \./minesweeper-ui.ls
{update-game-state, reset-game} = require \./minesweeper-logic.ls
{player-starts-game, player-acting} = require \./minesweeper-behaviour.ls

const INIT_WIDTH = 16
const INIT_HEIGHT = 16
const INIT_BOMBS = 40
const HTML_CONTAINER = document.get-element-by-id \container

render-game = (world) ->
  React-DOM.render (game-ui {world}), HTML_CONTAINER

init-game-state = reset-game INIT_WIDTH, INIT_HEIGHT, INIT_BOMBS

player-starts-game.onValue ([_, initial-cell-id]) ->
  player-acting
    .scan update-game-state,
      update-game-state init-game-state, [\start-game-with, initial-cell-id]
    .takeWhile (.get \game-running)
    .on-value render-game

render-game init-game-state
