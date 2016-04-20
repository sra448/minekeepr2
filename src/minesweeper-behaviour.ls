Rx = require \rx

const HTML_CONTAINER = document.get-element-by-id \container

time-increments = Rx.Observable.interval 1000, [\increment-time]

player-reveals-cell = do
  Rx.Observable
    .fromEvent HTML_CONTAINER, \click
    .filter (.target.id)
    .map ->
      [\reveal-field, +it.target.id]

player-toggles-cell = do
  Rx.Observable
    .fromEvent HTML_CONTAINER, \contextmenu
    .filter (.target.id)
    .map ->
      it.preventDefault()
      [\toggle-field-flag, +it.target.id]

player-starts-game = player-reveals-cell.take 1

player-acting = Rx.Observable.merge [time-increments, player-reveals-cell, player-toggles-cell]

module.exports = {
  player-starts-game
  player-acting
}