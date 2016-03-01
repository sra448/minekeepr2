module.exports = {
  entry: {
    minesweeper: "./minesweeper.ls",
    "spec/minesweeper_spec": "./spec/minesweeper_spec.ls"
  },
  output: {
    path: __dirname,
    filename: "[name].js"
  },
  module: {
    loaders: [
      { test: /\.ls$/, loader: "livescript" }
    ]
  }
}