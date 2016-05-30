react = require "react"

{div, h1, a, input} = react.DOM

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


module.exports = ({world, current-difficulty, change-board-size, reset-game}) ->
  size = [(world.get \board-width), (world.get \board-height), (world.get \bombs-count)]
  game-state = if world.get \game-lost then \game-lost else if world.get \game-won then \game-won else ""

  div {},
    h1 {}, "Minesweeper"

    div {class-name:\board-settings},
      a {class-name:"active" if current-difficulty == \easy, on-click: -> change-board-size \easy}, \easy
      a {class-name:"active" if current-difficulty == \medium, on-click: -> change-board-size \medium}, \medium
      a {class-name:"active" if current-difficulty == \hard, on-click: -> change-board-size \hard}, \hard
      a {class-name:"active" if current-difficulty == \custom, on-click: -> change-board-size \custom, size}, \custom

    if current-difficulty == \custom
      div {class-name:\board-size},
        div {style:flex:1},
          a {}, "\u2191 " + size[1]
          input {type:\range, value:size[1], min:9, max:40, on-change:(e) -> change-board-size \custom, [size[0], +e.target.value, size[2]]}
        div {style:flex:1},
          a {}, "\u2192 " + size[0]
          input {type:\range, value:size[0], min:9, max:70, on-change:(e) -> change-board-size \custom, [+e.target.value, size[1], size[2]]}
        div {style:flex:1},
          a {}, "\uD83D\uDCA3 " + size[2]
          input {type:\range, value:size[2], min:9, max:size[0]*size[1]/3, on-change:(e) -> change-board-size \custom, [size[0], size[1], +e.target.value]}


    div {class-name:\board-info},
      div {style:flex:"1"}, "\uD83D\uDCA3 " + ((world.get \bombs-count) - (world.get \fields-flagged))
      a {id:\reset-game, class-name:game-state, on-click:reset-game},
        div {class-name:\smiley}, \\u263A
        div {}, \reset
      div {style:flex:"1"}, (world.get \time-elapsed) + " \uD83D\uDD64"

    board-ui {world}
