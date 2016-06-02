react = require "react"
{div, h1, a, input} = react.DOM

cancel-context-menu = (fn, e) -->
  e.prevent-default!
  fn!

field = ({id, field, game-lost, reveal-field, toggle-field}) ->
  if (!field.get \is-bomb) && (field.get \is-revealed)
    surrounding-bombs-count = field.get \surrounding-bombs-count
    class-name = "cell revealed value-#surrounding-bombs-count"
    value = surrounding-bombs-count > 0 && surrounding-bombs-count || " "
  else if field.get \is-flagged
    class-name = "cell flagged"
    value = \\u2691
  else if game-lost && field.get \is-bomb
    class-name = "cell bomb"
    value = "\uD83D\uDCA3"
  else
    class-name = "cell"
    value = \-

  div {class-name, on-click:(->reveal-field id), on-context-menu:(cancel-context-menu -> toggle-field id)}, value


board = ({world, reveal-field, toggle-field}) ->
  div {class-name:\board, id:\board},
    for y til world.get \board-height
      div {class-name:\row, key:"row-#y"},
        for x til world.get \board-width
          id = y * (world.get \board-width) + x
          field do
            id: id
            game-lost: world.get \game-lost
            field: (world.get \fields).get id
            reveal-field: reveal-field
            toggle-field: toggle-field



board-size-panel = ({width, height, bombs-count, change-board}) ->
  div {class-name:\board-size-panel},
    div {style:flex:1},
      a {}, "\u2191 " + height
      input do
        type: \range
        value: height
        min: 9
        max: 40
        on-change: (e) ->
          bombs-percentage = 100 / (width * height) * bombs-count
          new-bombs-count = width * +e.target.value / 100 * bombs-percentage
          change-board \custom, [width, +e.target.value, new-bombs-count]

    div {style:flex:1},
      a {}, "\u2192 " + width
      input do
        type: \range
        value: width
        min: 9
        max: 70
        on-change: (e) ->
          bombs-percentage = 100 / (width * height) * bombs-count
          new-bombs-count = height * +e.target.value / 100 * bombs-percentage
          change-board \custom, [+e.target.value, height, new-bombs-count]

    div {style:flex:1},
      a {}, "\uD83D\uDCA3 " + Math.floor bombs-count
      input do
        type: \range
        value: bombs-count
        min: 9
        max: Math.min width * height / 4
        on-change: (e) ->
          change-board \custom, [width, height, +e.target.value]



module.exports = ({world, difficulty, change-board, reset-game, reveal-field, toggle-field}) ->
  [width, height, bombs-count] = size = [(world.get \board-width), (world.get \board-height), (world.get \bombs-count)]
  game-state = if world.get \game-lost then \game-lost else if world.get \game-won then \game-won else ""

  div {},
    h1 {}, "Minesweeper"

    div {class-name:\board-settings},
      a {class-name:"active" if difficulty == \easy, on-click: -> change-board \easy}, \easy
      a {class-name:"active" if difficulty == \medium, on-click: -> change-board \medium}, \medium
      a {class-name:"active" if difficulty == \hard, on-click: -> change-board \hard}, \hard
      a {class-name:"active" if difficulty == \custom, on-click: -> change-board \custom, size}, \custom

    if difficulty == \custom
      board-size-panel {width, height, bombs-count, change-board}

    div {class-name:\board-info},
      div {style:flex:"1"}, "\uD83D\uDCA3 " + ((world.get \bombs-count) - (world.get \fields-flagged))
      a {class-name:"reset-game #game-state", on-click:reset-game},
        div {class-name:\smiley}, \\u263A
        div {}, \reset
      div {style:flex:"1"}, (world.get \time-elapsed) + " \uD83D\uDD64"

    board {world, reveal-field, toggle-field}
