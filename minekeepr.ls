Immutable = require "immutable"
Kefir = require "kefir"

{shuffle} = require "lodash"
{apply, map, filter, fold, flip} = require "prelude-ls"

# game basics

const INIT_WIDTH = 30
const INIT_HEIGHT = 20
const INIT_BOMBS = 99
const HTML_CONTAINER = document.get-element-by-id "container"

Field = (id, is-bomb, neighbor-ids, surrounding-bombs-count) ->
  Immutable.Map().with-mutations (s) ->
    s.set \id, id
     .set \is-bomb, is-bomb
     .set \surrounding-bombs-count, is-bomb && -1 || surrounding-bombs-count
     .set \neighbor-ids, neighbor-ids
     .set \is-revealed, false
     .set \is-marked, false

Board = (width, height, bombs) ->
  bombs-sequence = shuffle [x < bombs for x to width * height]
  Immutable.Map do
    for is-bomb, i in bombs-sequence
      neighbor-ids = get-neighbor-ids i, width, height
      surrounding-bombs-count = do
        neighbor-ids
          |> filter (x) -> bombs-sequence[x]
          |> (.length)
      [i, Field i,  is-bomb, neighbor-ids, surrounding-bombs-count]

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

reset-game = (state) ->
  state.with-mutations ->
    it.set \game-running, false
      .set \game-won, false
      .set \game-lost, false
      .set \time-elapsed, 0
      .set \bombs-guessed, 0
      .set \bombs-revealed, 0
      .set \fields,
        Board (it.get \board-width), (it.get \board-height), 0

set-board-width = (state, new-width) ->
  reset-game <| state.set \board-width, new-width

set-board-height = (state, new-height) ->
  reset-game <| state.set \board-height, new-height

set-world-bombs = (state, new-bombs) ->
  reset-game <| state.set \bombs-count, new-bombs

increment-time = (state, time) ->
  state.update \time-elapsed, (+ 1)

reveal-field = (state, id) ->
  if !state.get \game-running
    (flip reveal-field) id,
      state.with-mutations ->
        it.set \game-running, true
          .set \fields,
            get-board-for (it.get \board-width), (it.get \board-height), (it.get \bombs-count), id

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
  if !state.getIn [\fields, id, \is-revealed]
    state.setIn [\fields, id, \is-revealed], true
  else
    state

toggle-field-bomb-guess = (state, id) ->
  if state.get \game-running
    state.updateIn [\fields, id, \is-marked], (!)
  else
    state

update-world-state = (state, [action, value]) ->
  switch action
    case \increment-time then increment-time state
    case \reveal-field then reveal-field state, value
    case \toggle-field-bomb-guess then toggle-field-bomb-guess state, value

initial-world-state = reset-game do
  Immutable.Map().with-mutations (s) ->
    s.set \board-width, INIT_WIDTH
     .set \board-height, INIT_HEIGHT
     .set \bombs-count, INIT_BOMBS


# UI Elements

react = require "react"
react-dom = require "react-dom"
{div} = react.DOM

field-ui = ({field}) ->
  div {class-name:\cell, id:field.get \id},
    if (field.get \is-revealed)
      (field.get \is-bomb) && \x || (field.get \surrounding-bombs-count) == 0 && " " || field.get \surrounding-bombs-count
    else if field.get \is-marked
      \o
    else
      \-

board-ui = ({world}) ->
  div {},
    div {}, "Time: " + world.get \time-elapsed
    div {class-name:\board},
      for y til world.get \board-height
        div {class-name:\row, key:y},
          for x til world.get \board-width
            field-ui field: (world.get \fields).get y * (world.get \board-width) + x


# game mechanics
# --------------

render-game = (world) ->
  react-dom.render (board-ui {world}), HTML_CONTAINER

increment-game-time = do
  Kefir
    .interval 1000, 1
    .map ->
      [\increment-time, 1]

player-reveal-cell = do
  Kefir
    .fromEvents HTML_CONTAINER, \click
    .filter (e) ->
      e.target.id
    .map (e) ->
      [\reveal-field, +e.target.id]

player-toggle-cell = do
  Kefir
    .fromEvents HTML_CONTAINER, \contextmenu
    .filter (e) ->
      e.target.id
    .map (e) ->
      e.preventDefault()
      [\toggle-field-bomb-guess, +e.target.id]

game-stream = do
  Kefir
    .merge [increment-game-time, player-reveal-cell, player-toggle-cell]
    .scan update-world-state, initial-world-state
    # .map render-game

# kick off game
player-reveal-cell.onValue ->
  game-stream.on-value render-game

render-game initial-world-state
