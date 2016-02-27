_ = require "lodash"
Immutable = require "immutable"
Kefir = require "kefir"
{ apply, map, filter, fold } = require "prelude-ls"

# game basics
# -----------

const INIT_WIDTH = 30
const INIT_HEIGHT = 20
const INIT_BOMBS = 55
const HTML_CONTAINER = document.get-element-by-id "container"

Field = (id, has-bomb, neighbor-ids, surrounding-bombs-count) ->
  Immutable.Map().with-mutations (s) ->
    s.set \id, id
     .set \has-bomb, has-bomb
     .set \surrounding-bombs-count, if has-bomb then -1 else surrounding-bombs-count
     .set \neighbor-ids, neighbor-ids
     .set \is-revealed, false
     .set \is-marked, false

Board = (width, height, bombs) ->
  sequence-lenght = width * height
  bombs-sequence = _.shuffle [x < bombs for x to sequence-lenght]
  Immutable.Map do
    for has-bomb, i in bombs-sequence
      neighbor-ids = get-neighbor-ids i, width, height
      surrounding-bombs-count = do
        neighbor-ids
          |> filter (x) -> bombs-sequence[x]
          |> (.length)
      [i, Field i,  has-bomb, neighbor-ids, surrounding-bombs-count]

get-neighbor-coordinates = ([x, y]) ->
  [[x-1, y-1] [x-1, y] [x-1, y+1] [x, y-1] [x, y+1] [x+1, y-1] [x+1, y] [x+1, y+1]]

check-boundaries = (board-width, board-height) ->
  ([x, y]) ->
    0 <= x < board-height && 0 <= y < board-width

get-neighbor-ids = (i, board-width, board-height) ->
  x = Math.floor <| i / board-width
  y = i % board-width
  get-neighbor-coordinates [x, y]
    |> filter check-boundaries board-width, board-height
    |> map ([x, y]) -> x * board-width + y


reset-game = (state) ->
  state.with-mutations (s) ->
    s.set \game-running, false
     .set \game-won, false
     .set \game-lost, false
     .set \time-elapsed, 0
     .set \bombs-guessed, 0
     .set \bombs-revealed, 0
     .set \fields, Board (s.get \board-width), (s.get \board-height), INIT_BOMBS

initial-world-state = reset-game do
  Immutable.Map().with-mutations (s) ->
    s.set \board-width, INIT_WIDTH
     .set \board-height, INIT_HEIGHT
     .set \bombs-count, INIT_BOMBS

set-board-width = (state, new-width) ->
  reset-game <| state.set \board-width, new-width

set-board-height = (state, new-height) ->
  reset-game <| state.set \board-height, new-height

set-world-bombs = (state, new-bombs) ->
  reset-game <| state.set \bombs-count, new-bombs

increment-time = (state, time) ->
  state.update \time-elapsed, (+ 1)

reveal-field = (state, id) -->
  surrounding-bombs-count = state.getIn [\fields, id, \surrounding-bombs-count]
  is-revealed = state.getIn [\fields, id, \is-revealed]

  if !is-revealed && surrounding-bombs-count == 0
    fold reveal-field, (set-field-revealed state, id), state.getIn [\fields, id, \neighbor-ids]
  else
    set-field-revealed state, id

set-field-revealed = (state, id) ->
  state.setIn [\fields, id, \is-revealed], true

toggle-field-bomb-guess = (state, id) ->
  state.updateIn [\fields, id, \is-marked], (!)

update-world-state = (state, [action, value]) ->
  switch action
    case \increment-time then increment-time state
    case \reveal-field then reveal-field state, value
    case \toggle-field-bomb-guess then toggle-field-bomb-guess state, value


# the UI
# ------

react = require "react"
react-dom = require "react-dom"
{div} = react.DOM

field-ui = ({field}) ->
  div {class-name:\cell, id:field.get \id},
    if (field.get \is-revealed)
      (field.get \has-bomb) && \x || (field.get \surrounding-bombs-count) == 0 && " " || field.get \surrounding-bombs-count
    else if field.get \is-marked
      \o
    else
      \-

board-ui = ({world}) ->
  div {},
    div {}, "Time: " + world.get \time-elapsed
    div {class-name:\board},
      for y til world.get \board-height
        div {class-name:\row"},
          for x til world.get \board-width
            div {className:\cell},
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
      !!e.target.id
    .map (e) ->
      [\reveal-field, +e.target.id]

player-toggle-cell = do
  Kefir
    .fromEvents HTML_CONTAINER, \contextmenu
    .filter (e) ->
      !!e.target.id
    .map (e) ->
      e.preventDefault()
      [\toggle-field-bomb-guess, +e.target.id]

game-stream = do
  Kefir
    .merge [increment-game-time, player-reveal-cell, player-toggle-cell]
    .scan update-world-state, initial-world-state
    .map render-game


# kickk off game
game-stream.log "game"
render-game initial-world-state
