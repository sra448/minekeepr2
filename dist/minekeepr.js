/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};

/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {

/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;

/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};

/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);

/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;

/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}


/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;

/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;

/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";

/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports) {

	var map2, getBoard, computeValues, addMetadata, getNeighborCoordinates, getNeighbors, revealNeighbors, field, board;
	map2 = function(xxs, fn){
	  var i$, len$, i, xs, lresult$, j$, len1$, j, x, results$ = [];
	  for (i$ = 0, len$ = xxs.length; i$ < len$; ++i$) {
	    i = i$;
	    xs = xxs[i$];
	    lresult$ = [];
	    for (j$ = 0, len1$ = xs.length; j$ < len1$; ++j$) {
	      j = j$;
	      x = xs[j$];
	      lresult$.push(fn(x, j, i));
	    }
	    results$.push(lresult$);
	  }
	  return results$;
	};
	getBoard = function(width, height, bombs){
	  var x, y;
	  bombs = _.shuffle((function(){
	    var i$, ref$, len$, results$ = [];
	    for (i$ = 0, len$ = (ref$ = (fn$())).length; i$ < len$; ++i$) {
	      x = ref$[i$];
	      results$.push(x < bombs);
	    }
	    return results$;
	    function fn$(){
	      var i$, to$, results$ = [];
	      for (i$ = 0, to$ = width * height; i$ < to$; ++i$) {
	        results$.push(i$);
	      }
	      return results$;
	    }
	  }()));
	  return addMetadata(computeValues((function(){
	    var i$, ref$, len$, lresult$, j$, ref1$, len1$, results$ = [];
	    for (i$ = 0, len$ = (ref$ = (fn$())).length; i$ < len$; ++i$) {
	      y = ref$[i$];
	      lresult$ = [];
	      for (j$ = 0, len1$ = (ref1$ = (fn1$())).length; j$ < len1$; ++j$) {
	        x = ref1$[j$];
	        lresult$.push(bombs.shift(1));
	      }
	      results$.push(lresult$);
	    }
	    return results$;
	    function fn$(){
	      var i$, to$, results$ = [];
	      for (i$ = 0, to$ = height; i$ < to$; ++i$) {
	        results$.push(i$);
	      }
	      return results$;
	    }
	    function fn1$(){
	      var i$, to$, results$ = [];
	      for (i$ = 0, to$ = width; i$ < to$; ++i$) {
	        results$.push(i$);
	      }
	      return results$;
	    }
	  }())));
	};
	computeValues = function(board){
	  return map2(board, function(bomb, x, y){
	    return bomb && -1 || _.filter(getNeighbors(x, y, board)).length;
	  });
	};
	addMetadata = function(board){
	  return map2(board, function(c, x, y){
	    return {
	      bomb: c === -1,
	      value: c,
	      revealed: false,
	      position: {
	        x: x,
	        y: y
	      }
	    };
	  });
	};
	getNeighborCoordinates = function(x, y){
	  return [[x - 1, y - 1], [x - 1, y], [x - 1, y + 1], [x, y - 1], [x, y + 1], [x + 1, y - 1], [x + 1, y], [x + 1, y + 1]];
	};
	getNeighbors = function(x, y, b){
	  var xx, yy;
	  return _.compact((function(){
	    var i$, ref$, len$, ref1$, results$ = [];
	    for (i$ = 0, len$ = (ref$ = getNeighborCoordinates(x, y)).length; i$ < len$; ++i$) {
	      ref1$ = ref$[i$], xx = ref1$[0], yy = ref1$[1];
	      results$.push((ref1$ = b[yy]) != null ? ref1$[xx] : void 8);
	    }
	    return results$;
	  }()));
	};
	revealNeighbors = function(x, y, board){
	  var coords;
	  coords = getNeighborCoordinates(x, y);
	  return _.reduce(coords, function(board, arg$){
	    var xx, yy, c, ref$;
	    xx = arg$[0], yy = arg$[1];
	    c = (ref$ = board[yy]) != null ? ref$[xx] : void 8;
	    if (c != null && !c.revealed) {
	      c.revealed = true;
	      if (c.value === 0) {
	        return revealNeighbors(xx, yy, board);
	      } else {
	        return board;
	      }
	    } else {
	      return board;
	    }
	  }, board);
	};
	field = React.createClass({
	  getInitialState: function(){
	    return {
	      flagged: false,
	      revealed: false
	    };
	  },
	  reveal: function(){
	    if (!this.state.flagged) {
	      this.props[this.props.bomb && "onExplode" || "onReveal"](this);
	      return this.setState({
	        revealed: true
	      });
	    }
	  },
	  flag: function(){
	    if (!this.state.revealed) {
	      this.setState({
	        flagged: !this.state.flagged
	      });
	    }
	    return false;
	  },
	  render: function(){
	    var fieldType;
	    fieldType = this.state.flagged
	      ? "flagged"
	      : this.state.revealed || this.props.revealed ? this.props.value === 0 ? "revealed empty" : "revealed" : "";
	    return React.DOM.div({
	      className: "cell " + fieldType,
	      onClick: this.reveal,
	      onContextMenu: this.flag
	    }, this.state.revealed || this.props.revealed
	      ? this.props.bomb && "x" || this.props.value === 0 && "-" || this.props.value
	      : this.state.flagged ? "o" : "-");
	  }
	});
	board = React.createClass({
	  getInitialState: function(){
	    return {
	      board: getBoard(30, 18, 55)
	    };
	  },
	  reset: function(width, height, bombs){
	    return this.setState({
	      board: getBoard(width, height, bombs)
	    });
	  },
	  explode: function(){
	    return this.setState({
	      lost: true
	    });
	  },
	  showNeighbors: function(cell){
	    if (cell.props.value === 0) {
	      return this.setState({
	        board: revealNeighbors(cell.props.position.x, cell.props.position.y, this.state.board)
	      });
	    }
	  },
	  render: function(){
	    var row, c;
	    return React.DOM.div({
	      className: "board " + (this.state.lost && "lost" || "")
	    }, (function(){
	      var i$, ref$, len$, results$ = [];
	      for (i$ = 0, len$ = (ref$ = this.state.board).length; i$ < len$; ++i$) {
	        row = ref$[i$];
	        results$.push(React.DOM.div({
	          className: "row"
	        }, (fn$.call(this))));
	      }
	      return results$;
	      function fn$(){
	        var i$, ref$, len$, results$ = [];
	        for (i$ = 0, len$ = (ref$ = row).length; i$ < len$; ++i$) {
	          c = ref$[i$];
	          results$.push(field(_.extend(c, {
	            onExplode: this.explode,
	            onReveal: this.showNeighbors
	          })));
	        }
	        return results$;
	      }
	    }.call(this)));
	  }
	});
	React.renderComponent(board({}), document.getElementById("container"));
	//# sourceMappingURL=C:\Users\Florian\OneDrive\Dokumente\GitHub\minekeepr2\node_modules\livescript-loader\index.js!C:\Users\Florian\OneDrive\Dokumente\GitHub\minekeepr2\minekeepr.ls.map


/***/ }
/******/ ]);