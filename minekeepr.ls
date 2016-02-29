Immutable = require "immutable"
Kefir = require "kefir"

{shuffle} = require "lodash"
{apply, map, filter, fold, flip} = require "prelude-ls"

const INIT_WIDTH = 30
const INIT_HEIGHT = 20
const INIT_BOMBS = 100
const HTML_CONTAINER = document.get-element-by-id "container"

# board data structures

Field = (id, is-bomb, neighbor-ids, surrounding-bombs-count) ->
  Immutable.Map().with-mutations (s) ->
    s.set \id, id
     .set \is-bomb, is-bomb
     .set \surrounding-bombs-count, is-bomb && -1 || surrounding-bombs-count
     .set \neighbor-ids, neighbor-ids
     .set \is-revealed, false
     .set \is-flagged, false

Board = (width, height, bombs) ->
  bombs-sequence = shuffle [x < bombs for x til width * height]
  Immutable.Map do
    for is-bomb, i in bombs-sequence
      neighbor-ids = get-neighbor-ids i, width, height
      surrounding-bombs-count = do
        neighbor-ids
          |> filter (x) -> bombs-sequence[x]
          |> (.length)
      [i, (Field i, is-bomb, neighbor-ids, surrounding-bombs-count)]

# board data helpers

get-board-for = (width, height, bombs, id) ->
  board = Board width, height, bombs
  if (board.getIn [id, \surrounding-bombs-count]) != 0
    get-board-for ...
  else
    board

get-neighbor-coordinates = ([x, y]) ->
  [[x-1, y-1] [x-1, y] [x-1, y+1] [x, y-1] [x, y+1] [x+1, y-1] [x+1, y] [x+1, y+1]]

check-board-boundaries = (board-width, board-height) ->
  ([x, y]) ->
    0 <= x < board-height && 0 <= y < board-width

get-neighbor-ids = (i, board-width, board-height) ->
  x = Math.floor <| i / board-width
  y = i % board-width
  get-neighbor-coordinates [x, y]
    |> filter check-board-boundaries board-width, board-height
    |> map ([x, y]) -> x * board-width + y

# game actions

set-board-width = (state, new-width) ->
  reset-game <| state.set \board-width, new-width

set-board-height = (state, new-height) ->
  reset-game <| state.set \board-height, new-height

set-world-bombs = (state, new-bombs) ->
  reset-game <| state.set \bombs-count, new-bombs

start-game = (state, initial-cell-id) ->
  (flip reveal-field) initial-cell-id,
    state.with-mutations ->
      it.set \game-running, true
        .set \time-elapsed, 1
        .set \fields,
          get-board-for (it.get \board-width), (it.get \board-height), (it.get \bombs-count), initial-cell-id

reset-game = (state) ->
  state.with-mutations ->
    it.set \game-running, false
      .set \game-won, false
      .set \game-lost, false
      .set \time-elapsed, 0
      .set \fields-flagged, 0
      .set \fields,
        Board (it.get \board-width), (it.get \board-height), 0

loose-game = (state, id) ->
  state.with-mutations ->
    it.set \game-lost, true
    it.setIn [\fields, id, \is-revealed], true

increment-time = (state, time) ->
  if (state.get \game-lost) || (state.get \game-won)
    state
  else
    state.update \time-elapsed, (+ 1)

reveal-field = (state, id) ->
  if state.getIn [\fields, id, \is-flagged]
    state
  else if state.getIn [\fields, id, \is-bomb]
    loose-game state, id
  else
    surrounding-bombs-count = state.getIn [\fields, id, \surrounding-bombs-count]
    is-revealed = state.getIn [\fields, id, \is-revealed]

    if surrounding-bombs-count != 0
      set-field-revealed state, id
    else
      state.getIn [\fields, id, \neighbor-ids]
        |> map -> state.getIn [\fields, it]
        |> filter -> !(it.get \is-revealed) && (it.get \surrounding-bombs-count) == 0
        |> map -> it.get \id
        |> fold reveal-field,
          state.getIn [\fields, id, \neighbor-ids]
            |> fold set-field-revealed, set-field-revealed state, id

set-field-revealed = (state, id) ->
  if (state.getIn [\fields, id, \is-revealed]) || state.getIn [\fields, id, \is-flagged]
    state
  else
    state.setIn [\fields, id, \is-revealed], true

toggle-field-flag = (state, id) ->
  if !state.get \game-running
    state
  else
    is-currently-flagged = state.getIn [\fields, id, \is-flagged]
    state.with-mutations ->
      it.setIn [\fields, id, \is-flagged], !is-currently-flagged
        .update \fields-flagged, is-currently-flagged && (- 1) || (+ 1)

world-explode = (state, amount) ->
  if amount == 9
    state.set \game-running, false
  else
    state.set \explotion, amount

# dispatch actions

update-world-state = (state, [action, value]) ->
  switch action
    case \reset-game then increment-time state
    case \increment-time then increment-time state
    case \reveal-field then reveal-field state, value
    case \toggle-field-flag then toggle-field-flag state, value
    case \world-explode then world-explode state, value
    default state

# UI Elements

react = require "react"
react-dom = require "react-dom"
{div, h1, a} = react.DOM

field-ui = ({field}) ->
  value = field.get \surrounding-bombs-count

  if field.get \is-revealed
    div {class-name:"cell revealed value-#value", id:field.get \id},
      (field.get \is-bomb) && "\uD83D\uDCA3" || value == 0 && " " || value
  else if field.get \is-flagged
    div {class-name:"cell flagged", id:field.get \id}, \\u2691
  else
    div {class-name:"cell", id:field.get \id}, \-

board-ui = ({world}) ->
  div {class-name:\board, id:\board},
    for y til world.get \board-height
      div {class-name:\row, key:y},
        for x til world.get \board-width
          field-ui field: (world.get \fields).get y * (world.get \board-width) + x

game-ui = ({world}) ->
  div {},
    h1 {}, "minesweeper"

    div {},
      div {}, "Bombs: " + ((world.get \bombs-count) - (world.get \fields-flagged))
      a {id:\reset-game},
        if world.get \game-lost
          \\u2639
        else if world.get \game-won
          \\u263A
        else
          \\u263A
      div {}, "Time: " + world.get \time-elapsed

    board-ui {world}


# player interactions

increment-game-time = do
  Kefir
    .interval 1000, 1
    .map ->
      [\increment-time, 1]

player-reveal-cell = do
  Kefir
    .fromEvents HTML_CONTAINER, \click
    .filter ->
      it.target.id
    .map ->
      [\reveal-field, +it.target.id]

player-toggle-cell = do
  Kefir
    .fromEvents HTML_CONTAINER, \contextmenu
    .filter ->
      it.target.id
    .map ->
      it.preventDefault()
      [\toggle-field-flag, +it.target.id]

# kick off game

render-game = (world) ->
  react-dom.render (game-ui {world}), HTML_CONTAINER

initial-world-state = reset-game do
  Immutable.Map().with-mutations ->
    it.set \board-width, INIT_WIDTH
      .set \board-height, INIT_HEIGHT
      .set \bombs-count, INIT_BOMBS

player-reveal-cell
  .take 1
  .onValue ([_, initial-cell-id]) ->
    Kefir
      .merge [increment-game-time, player-reveal-cell, player-toggle-cell]
      .scan update-world-state, start-game initial-world-state, initial-cell-id
      .flatMap ->
        if !it.get \game-lost
          Kefir.constant it
        else
          Kefir
            .sequentially 100, [[\world-explode, i] for i til 10]
            .scan update-world-state, it
      .takeWhile ->
        it.get \game-running
      .on-value render-game

render-game initial-world-state
