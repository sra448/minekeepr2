Immutable = require \immutable

{shuffle} = require \lodash
{map, filter, fold, flip} = require \prelude-ls

# board data structures

Field = (id, is-bomb, neighbor-ids, surrounding-bombs-count) ->
  Immutable.Map().with-mutations ->
    it.set \id, id
      .set \is-bomb, is-bomb
      .set \surrounding-bombs-count, is-bomb && -1 || surrounding-bombs-count
      .set \neighbor-ids, neighbor-ids
      .set \is-revealed, false
      .set \is-flagged, false

Fields = (width, height, bombs) ->
  bombs-sequence = shuffle [x < bombs for x til width * height]
  Immutable.List do
    for is-bomb, i in bombs-sequence
      neighbor-ids = get-neighbor-ids i, width, height
      surrounding-bombs-count = do
        neighbor-ids
          |> filter (x) -> bombs-sequence[x]
          |> (.length)
      Field i, is-bomb, neighbor-ids, surrounding-bombs-count

# board data helpers

get-board-for = (width, height, bombs, id) ->
  board = Fields width, height, bombs
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

reset-game = ([board-width, board-height, bombs-count] = []) ->
  Immutable.Map().with-mutations ->
    it.set \game-running, false
      .set \game-won, false
      .set \game-lost, false
      .set \time-elapsed, 0
      .set \fields-flagged, 0
      .set \fields-revealed, 0
      .set \board-width, board-width || it.get \board-width
      .set \board-height, board-height || it.get \board-height
      .set \bombs-count, bombs-count || it.get \bombs-count
      .set \fields, Fields (it.get \board-width), (it.get \board-height), 0

start-game-with = (state, initial-cell-id) ->
  (flip reveal-field) initial-cell-id,
    state.with-mutations ->
      it.set \game-running, true
        .set \time-elapsed, 1
        .set \fields,
          get-board-for (it.get \board-width), (it.get \board-height), (it.get \bombs-count), initial-cell-id

check-game-won = (state) ->
  if (state.get \fields).size - (state.get \fields-revealed) > state.get \bombs-count
    state
  else
    state.set \game-won, true

lose-game = (state) ->
  state.set \game-lost, true

increment-time = (state, time) ->
  state.update \time-elapsed, (+ 1)

reveal-field = (state, id) ->
  if !state.get \game-running
    start-game-with state, id
  else if (state.get \game-lost) || (state.get \game-won) || state.getIn [\fields, id, \is-flagged] || state.getIn [\fields, id, \is-revealed]
    state
  else if state.getIn [\fields, id, \is-bomb]
    lose-game state
  else if (state.getIn [\fields, id, \surrounding-bombs-count]) > 0
    set-field-revealed state, id
  else
    neighbor-fields = state.getIn [\fields, id, \neighbor-ids]
      |> map -> state.getIn [\fields, it]

    neighbor-fields
      |> filter -> (!it.get \is-revealed) && (it.get \surrounding-bombs-count) == 0
      |> map -> it.get \id
      |> fold reveal-field,
        neighbor-fields
          |> filter -> (!it.get \is-revealed) && (!it.get \is-flagged)
          |> map -> it.get \id
          |> fold set-field-revealed, set-field-revealed state, id

set-field-revealed = (state, id) ->
  if state.getIn [\fields, id, \is-revealed]
    state
  else
    state.with-mutations ->
      it.setIn [\fields, id, \is-revealed], true
        .update \fields-revealed, (+ 1)

toggle-field-flag = (state, id) ->
  if !state.get \game-running
    state
  else
    is-currently-flagged = state.getIn [\fields, id, \is-flagged]
    state.with-mutations ->
      it.setIn [\fields, id, \is-flagged], !is-currently-flagged
        .update \fields-flagged, is-currently-flagged && (- 1) || (+ 1)

# dispatch actions

update-game-state = (state, [action, value]) ->
  console.log action, value
  switch action
    case \reset-game then reset-game value
    case \increment-time then increment-time state
    case \reveal-field then check-game-won <| reveal-field state, value
    case \toggle-field-flag then toggle-field-flag state, value
    default state

module.exports = {
  reset-game
  update-game-state
}
