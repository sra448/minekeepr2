react = require "react"

{div, h1, a} = react.DOM

field-ui = ({id, field, game-lost}) ->
  if (!field.get \is-bomb) && (field.get \is-revealed)
    value = field.get \surrounding-bombs-count
    div {class-name:"cell revealed value-#value", id:id}, value > 0 && value || " "
  else if field.get \is-flagged
    div {class-name:"cell flagged", id:id}, \\u2691
  else if game-lost && field.get \is-bomb
    div {class-name:"cell bomb"}, "\uD83D\uDCA3"
  else
    div {class-name:"cell", id:id}, \-

board-ui = ({world}) ->
  div {class-name:\board, id:\board},
    for y til world.get \board-height
      div {class-name:\row, key:"row-#y"},
        for x til world.get \board-width
          id = y * (world.get \board-width) + x
          field-ui do
            id: id
            game-lost: world.get \game-lost
            field: (world.get \fields).get id

module.exports = ({world}) ->
  div {},
    h1 {}, "minesweeper"

    div {},
      div {}, "Bombs: " + ((world.get \bombs-count) - (world.get \fields-flagged))
      a {id:\reset-game},
        if world.get \game-lost
          \\u2639
        else if world.get \game-won
          \won
        else
          \\u263A
      div {}, "Time: " + world.get \time-elapsed

    board-ui {world}
