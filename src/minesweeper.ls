React-DOM = require \react-dom
game-ui = require \./minesweeper-ui.ls
{observe-game, reset-game, change-board, reveal-field, toggle-field} = require \./minesweeper-behaviour.ls

const HTML_CONTAINER = document.get-element-by-id \container

observe-game
  .subscribe ({world, difficulty}) ->
    ui = game-ui {world, difficulty, reset-game, change-board, reveal-field, toggle-field}
    React-DOM.render ui, HTML_CONTAINER

reset-game!
