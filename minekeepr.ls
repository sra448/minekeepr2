# game basics
# -----------

map2 = (xxs, fn) ->
  for xs, i in xxs
    for x, j in xs
      fn x, j, i

getBoard = (width, height, bombs) ->
  bombs = _.shuffle [x < bombs for x in [0 til width * height]]
  addMetadata computeValues do
    for y in [0 til height]
      for x in [0 til width]
        bombs.shift 1

computeValues = (board) ->
  map2 board, (bomb, x, y) ->
    bomb && -1 || (_.filter (getNeighbors x, y, board)).length

addMetadata = (board) ->
  map2 board, (c, x, y) ->
    bomb: c == -1
    value: c
    revealed: false
    position:
      x: x
      y: y

getNeighborCoordinates = (x, y) ->
  [[x-1, y-1], [x-1, y], [x-1, y+1], [x, y-1],
   [x, y+1] ,[x+1, y-1], [x+1, y], [x+1, y+1]]

getNeighbors = (x, y, b) ->
  _.compact [b[yy]?[xx] for [xx, yy] in getNeighborCoordinates x, y]

revealNeighbors = (x, y, board) ->
  coords = getNeighborCoordinates x, y
  _.reduce coords, ((board, [xx, yy]) ->
    c = board[yy]?[xx]
    if c? && !c.revealed
      c.revealed = true
      if c.value == 0
        revealNeighbors xx, yy, board
      else
        board
    else
      board), board


# UI Stuff
# --------

field = React.createClass do

  getInitialState: ->
    flagged: false
    revealed: false

  reveal: ->
    if !@state.flagged
      @props[@props.bomb && "onExplode" || "onReveal"] this
      @setState { revealed:true }

  flag: ->
    if !@state.revealed
      @setState { flagged:!@state.flagged }
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

    React.DOM.div { className:"cell #{fieldType}", onClick:@reveal, onContextMenu:@flag },
      if @state.revealed || @props.revealed
        @props.bomb && "x" || @props.value == 0 && "-" || @props.value
      else if @state.flagged
        "o"
      else
        "-"

board = React.createClass do

  getInitialState: ->
    board: getBoard 30, 18, 55

  reset: (width, height, bombs) ->
    @setState do
      board: getBoard width, height, bombs

  explode: ->
    @setState { lost:true }

  showNeighbors: (cell) ->
    if cell.props.value == 0
      @setState do
        board: revealNeighbors cell.props.position.x, cell.props.position.y, @state.board

  render: ->
    React.DOM.div { className:"board #{@state.lost && "lost" || ""}" },
      (for row in @state.board
        React.DOM.div { className:"row" },
          (for c in row
            field _.extend c,
              onExplode: @explode
              onReveal: @showNeighbors))


# hook ui stuff to the browser
# ----------------------------

React.renderComponent (board {}), (document.getElementById "container")
