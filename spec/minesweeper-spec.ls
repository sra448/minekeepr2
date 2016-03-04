test-if-it = it

logic = require "../src/minesweeper-logic.ls"

describe "minesweeper logic", ->

  test-if-it "is defined", ->
    (expect logic).to-be-defined!

  describe "update-game-state", ->

    test-if-it "is defined", ->
      (expect logic.update-game-state).to-be-defined!
