module.exports = {
  entry: "./minekeepr.ls",
  output: {
    path: __dirname + "/dist",
    filename: "minekeepr.js"
  },
  module: {
    loaders: [
      { test: /\.ls$/, loader: "livescript" }
    ]
  }
}