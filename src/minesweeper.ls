React-DOM = require \react-dom
game = require \./minesweeper-game.ls
game-ui = require \./minesweeper-ui.ls

const HTML_CONTAINER = document.get-element-by-id \container
const DIFFICULTIES =
  easy: [10, 10, 9]
  medium: [16, 16, 40]
  hard: [30, 20, 99]

ms-game = new game do
  difficulties: DIFFICULTIES
  default-difficulty: \medium

ms-game.subscribe ({world, difficulty}) ->
  ui = game-ui do
    world: world
    difficulty: difficulty
    reset-game: ms-game.reset
    change-board: ms-game.change-board
    reveal-field: ms-game.reveal-field
    toggle-field: ms-game.toggle-field

  React-DOM.render ui, HTML_CONTAINER

ms-game.reset!
