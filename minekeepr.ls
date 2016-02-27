_ = require "lodash"
react = require "react"
react-dom = require "react-dom"

# game basics
# -----------

map2 = (xxs, fn) ->
  for xs, i in xxs
    for x, j in xs
      fn x, j, i

get-board = (width, height, bombs) ->
  bombs = _.shuffle [x < bombs for x in [0 til width * height]]
  add-metadata compute-values do
    for y in [0 til height]
      for x in [0 til width]
        bombs.shift 1

compute-values = (board) ->
  map2 board, (bomb, x, y) ->
    bomb && -1 || (_.filter (get-neighbors x, y, board)).length

add-metadata = (board) ->
  map2 board, (c, x, y) ->
    bomb: c == -1
    value: c
    revealed: false
    position:
      x: x
      y: y

get-neighbor-coordinates = (x, y) ->
  [[x-1, y-1], [x-1, y], [x-1, y+1], [x, y-1],
   [x, y+1] ,[x+1, y-1], [x+1, y], [x+1, y+1]]

get-neighbors = (x, y, b) ->
  _.compact [b[yy]?[xx] for [xx, yy] in get-neighbor-coordinates x, y]

reveal-neighbors = (x, y, board) ->
  coords = get-neighbor-coordinates x, y
  _.reduce coords, ((board, [xx, yy]) ->
    c = board[yy]?[xx]
    if c? && !c.revealed
      c.revealed = true
      if c.value == 0
        reveal-neighbors xx, yy, board
      else
        board
    else
      board), board


# UI Stuff
# --------

field = react.create-factory react.create-class do

  get-initial-state: ->
    flagged: false
    revealed: false

  reveal: ->
    if !@state.flagged
      @props[@props.bomb && "onExplode" || "onReveal"] this
      @set-state { revealed:true }

  flag: ->
    if !@state.revealed
      @set-state { flagged:!@state.flagged }
    false

  render: ->
    fieldType = if @state.flagged
      "flagged"
    else if @state.revealed || @props.revealed
      if @props.value == 0
        "revealed empty"
      else
        "revealed"
    else ""

    react.DOM.div { class-name:"cell #{fieldType}", onClick:@reveal, onContextMenu:@flag },
      if @state.revealed || @props.revealed
        @props.bomb && "x" || @props.value == 0 && "-" || @props.value
      else if @state.flagged
        "o"
      else
        "-"

board = react.create-factory react.create-class do

  get-initial-state: ->
    board: get-board 30, 18, 55

  reset: (width, height, bombs) ->
    @set-state do
      board: get-board width, height, bombs

  explode: ->
    @set-state { lost:true }

  show-neighbors: (cell) ->
    if cell.props.value == 0
      @set-state do
        board: reveal-neighbors cell.props.position.x, cell.props.position.y, @state.board

  render: ->
    react.DOM.div { class-name:"board #{@state.lost && "lost" || ""}" },
      (for row in @state.board
        react.DOM.div { class-name:"row" },
          (for c in row
            field _.extend c,
              onExplode: @explode
              onReveal: @show-neighbors))


# hook ui stuff to the browser
# ----------------------------

react-dom.render (board {}), (document.get-element-by-id "container")
