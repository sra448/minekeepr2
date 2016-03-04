module.exports = {
  entry: {
    "src/minesweeper": "./src/minesweeper.ls",
    "spec/minesweeper_spec": "./spec/minesweeper-spec.ls"
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