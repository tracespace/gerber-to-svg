(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.gerberToSvg = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function (global){
var DEFAULT_OPTS, DrillParser, DrillReader, GerberParser, GerberReader, Plotter, builder, coordFactor;

builder = require('./obj-to-xml');

Plotter = require('./plotter');

DrillReader = require('./drill-reader');

DrillParser = require('./drill-parser');

GerberReader = require('./gerber-reader');

GerberParser = require('./gerber-parser');

coordFactor = require('./svg-coord').factor;

DEFAULT_OPTS = {
  drill: false,
  pretty: false,
  object: false,
  warnArr: null,
  places: null,
  zero: null,
  notation: null,
  units: null
};

module.exports = function(file, options) {
  var a, error, height, key, oldWarn, opts, p, parser, parserOpts, plotterOpts, reader, ref, root, val, width, xml, xmlObject;
  if (options == null) {
    options = {};
  }
  opts = {};
  for (key in DEFAULT_OPTS) {
    val = DEFAULT_OPTS[key];
    opts[key] = val;
  }
  for (key in options) {
    val = options[key];
    opts[key] = val;
  }
  if (typeof file === 'object') {
    if (file.svg != null) {
      return builder(file, {
        pretty: opts.pretty
      });
    } else {
      throw new Error('non SVG object cannot be converted to an SVG string');
    }
  }
  parserOpts = null;
  if ((opts.places != null) || (opts.zero != null)) {
    parserOpts = {
      places: opts.places,
      zero: opts.zero
    };
  }
  if (opts.drill) {
    reader = new DrillReader(file);
    parser = new DrillParser(parserOpts);
  } else {
    reader = new GerberReader(file);
    parser = new GerberParser(parserOpts);
  }
  plotterOpts = null;
  if ((opts.notation != null) || (opts.units != null)) {
    plotterOpts = {
      notation: opts.notation,
      units: opts.units
    };
  }
  p = new Plotter(reader, parser, plotterOpts);
  oldWarn = null;
  root = null;
  if (Array.isArray(opts.warnArr)) {
    root = typeof window !== "undefined" && window !== null ? window : global;
    if (root.console == null) {
      root.console = {};
    }
    oldWarn = root.console.warn;
    root.console.warn = function(chunk) {
      return opts.warnArr.push(chunk.toString());
    };
  }
  try {
    xmlObject = p.plot();
  } catch (_error) {
    error = _error;
    throw new Error("Error at line " + p.reader.line + " - " + error.message);
  } finally {
    if ((oldWarn != null) && (root != null)) {
      root.console.warn = oldWarn;
    }
  }
  if (!(p.bbox.xMin >= p.bbox.xMax)) {
    width = p.bbox.xMax - p.bbox.xMin;
  } else {
    p.bbox.xMin = 0;
    p.bbox.xMax = 0;
    width = 0;
  }
  if (!(p.bbox.yMin >= p.bbox.yMax)) {
    height = p.bbox.yMax - p.bbox.yMin;
  } else {
    p.bbox.yMin = 0;
    p.bbox.yMax = 0;
    height = 0;
  }
  xml = {
    svg: {
      xmlns: 'http://www.w3.org/2000/svg',
      version: '1.1',
      'xmlns:xlink': 'http://www.w3.org/1999/xlink',
      width: "" + (width / coordFactor) + p.units,
      height: "" + (height / coordFactor) + p.units,
      viewBox: [p.bbox.xMin, p.bbox.yMin, width, height],
      _: []
    }
  };
  ref = p.attr;
  for (a in ref) {
    val = ref[a];
    xml.svg[a] = val;
  }
  if (p.defs.length) {
    xml.svg._.push({
      defs: {
        _: p.defs
      }
    });
  }
  if (p.group.g._.length) {
    xml.svg._.push(p.group);
  }
  if (!opts.object) {
    return builder(xml, {
      pretty: opts.pretty
    });
  } else {
    return xml;
  }
};



}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"./drill-parser":3,"./drill-reader":4,"./gerber-parser":5,"./gerber-reader":6,"./obj-to-xml":9,"./plotter":12,"./svg-coord":14}],2:[function(require,module,exports){
var getSvgCoord;

getSvgCoord = require('./svg-coord').get;

module.exports = function(coord, format) {
  var key, parse, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, result, val;
  if (coord == null) {
    return {};
  }
  if (!((format.zero != null) && (format.places != null))) {
    throw new Error('format undefined');
  }
  parse = {};
  result = {};
  parse.x = (ref = coord.match(/X[+-]?[\d\.]+/)) != null ? (ref1 = ref[0]) != null ? ref1.slice(1) : void 0 : void 0;
  parse.y = (ref2 = coord.match(/Y[+-]?[\d\.]+/)) != null ? (ref3 = ref2[0]) != null ? ref3.slice(1) : void 0 : void 0;
  parse.i = (ref4 = coord.match(/I[+-]?[\d\.]+/)) != null ? (ref5 = ref4[0]) != null ? ref5.slice(1) : void 0 : void 0;
  parse.j = (ref6 = coord.match(/J[+-]?[\d\.]+/)) != null ? (ref7 = ref6[0]) != null ? ref7.slice(1) : void 0 : void 0;
  for (key in parse) {
    val = parse[key];
    if (val != null) {
      result[key] = getSvgCoord(val, format);
    }
  }
  return result;
};



},{"./svg-coord":14}],3:[function(require,module,exports){
var ABS_COMMAND, DrillParser, INCH_COMMAND, INC_COMMAND, METRIC_COMMAND, PLACES_BACKUP, Parser, ZERO_BACKUP, getSvgCoord, parseCoord, reCOORD,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Parser = require('./parser');

parseCoord = require('./coord-parser');

getSvgCoord = require('./svg-coord').get;

INCH_COMMAND = {
  'FMAT,1': 'M70',
  'FMAT,2': 'M72'
};

METRIC_COMMAND = 'M71';

ABS_COMMAND = 'G90';

INC_COMMAND = 'G91';

reCOORD = /[XY]{1,2}/;

ZERO_BACKUP = 'L';

PLACES_BACKUP = [2, 4];

DrillParser = (function(superClass) {
  extend(DrillParser, superClass);

  function DrillParser() {
    this.fmat = 'FMAT,2';
    DrillParser.__super__.constructor.call(this, arguments[0]);
  }

  DrillParser.prototype.parseCommand = function(block) {
    var base, base1, base2, base3, code, command, dia, k, ref, ref1, ref2, v;
    command = {};
    if (block[0] === ';') {
      return command;
    }
    if (block === 'FMAT,1') {
      this.fmat = block;
    } else if (block === 'M30' || block === 'M00') {
      command.set = {
        done: true
      };
    } else if (block === INCH_COMMAND[this.fmat] || block.match(/INCH/)) {
      if ((base = this.format).places == null) {
        base.places = [2, 4];
      }
      command.set = {
        units: 'in'
      };
    } else if (block === METRIC_COMMAND || block.match(/METRIC/)) {
      if ((base1 = this.format).places == null) {
        base1.places = [3, 3];
      }
      command.set = {
        units: 'mm'
      };
    } else if (block === ABS_COMMAND) {
      command.set = {
        notation: 'A'
      };
    } else if (block === INC_COMMAND) {
      command.set = {
        notation: 'I'
      };
    } else if ((code = (ref = block.match(/T\d+/)) != null ? ref[0] : void 0)) {
      while (code[1] === '0') {
        code = code[0] + code.slice(2);
      }
      if ((dia = (ref1 = block.match(/C[\d\.]+(?=.*$)/)) != null ? ref1[0] : void 0)) {
        dia = dia.slice(1);
        command.tool = {};
        command.tool[code] = {
          dia: getSvgCoord(dia, {
            places: this.format.places
          })
        };
      } else {
        command.set = {
          currentTool: code
        };
      }
    }
    if (block.match(/TZ/)) {
      if ((base2 = this.format).zero == null) {
        base2.zero = 'L';
      }
    } else if (block.match(/LZ/)) {
      if ((base3 = this.format).zero == null) {
        base3.zero = 'T';
      }
    }
    if (block.match(reCOORD)) {
      command.op = {
        "do": 'flash'
      };
      if (this.format.zero == null) {
        console.warn('no drill file zero suppression specified. assuming leading zero suppression (same as no zero suppression)');
        this.format.zero = ZERO_BACKUP;
      }
      if (this.format.places == null) {
        console.warn('no drill file units specified; assuming 2:4 inches format');
        this.format.places = PLACES_BACKUP;
      }
      ref2 = parseCoord(block, this.format);
      for (k in ref2) {
        v = ref2[k];
        command.op[k] = v;
      }
    }
    return command;
  };

  return DrillParser;

})(Parser);

module.exports = DrillParser;



},{"./coord-parser":2,"./parser":11,"./svg-coord":14}],4:[function(require,module,exports){
var DrillReader;

DrillReader = (function() {
  function DrillReader(drillFile) {
    this.line = 0;
    this.blocks = drillFile.split(/\r?\n/);
  }

  DrillReader.prototype.nextBlock = function() {
    if (this.line < this.blocks.length) {
      return this.blocks[++this.line - 1];
    } else {
      return false;
    }
  };

  return DrillReader;

})();

module.exports = DrillReader;



},{}],5:[function(require,module,exports){
var GerberParser, Parser, getSvgCoord, parseCoord, reCOORD,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Parser = require('./parser');

parseCoord = require('./coord-parser');

getSvgCoord = require('./svg-coord').get;

reCOORD = /([XYIJ][+-]?\d+){1,4}/g;

GerberParser = (function(superClass) {
  extend(GerberParser, superClass);

  function GerberParser() {
    return GerberParser.__super__.constructor.apply(this, arguments);
  }

  GerberParser.prototype.parseFormat = function(p, c) {
    var base, base1, nota, places, zero;
    zero = p[2] === 'L' || p[2] === 'T' ? p[2] : null;
    nota = p[3] === 'A' || p[3] === 'I' ? p[3] : null;
    if (p[4] === 'X' && p[7] === 'Y' && p.slice(5, 7) === p.slice(8, 10) && p[5] < 8 && p[6] < 8) {
      places = [+p[5], +p[6]];
    }
    if ((places == null) || (nota == null) || (zero == null)) {
      throw new Error('invalid format specification');
    }
    if ((base = this.format).zero == null) {
      base.zero = zero;
    }
    if ((base1 = this.format).places == null) {
      base1.places = places;
    }
    if (c.set == null) {
      c.set = {};
    }
    return c.set.notation = nota;
  };

  GerberParser.prototype.parseToolDef = function(p, c) {
    var code, hole, m, mods, ref, ref1, shape;
    if (c.tool == null) {
      c.tool = {};
    }
    code = (ref = p.match(/^ADD\d{2,}/)) != null ? ref[0].slice(2) : void 0;
    ref1 = p.slice(2 + code.length).split(','), shape = ref1[0], mods = ref1[1];
    mods = mods != null ? mods.split('X') : void 0;
    while (code[1] === '0') {
      code = code[0] + code.slice(2);
    }
    switch (shape) {
      case 'C':
        if (mods.length > 2) {
          hole = {
            width: getSvgCoord(mods[1], {
              places: this.format.places
            }),
            height: getSvgCoord(mods[2], {
              places: this.format.places
            })
          };
        } else if (mods.length > 1) {
          hole = {
            dia: getSvgCoord(mods[1], {
              places: this.format.places
            })
          };
        }
        c.tool[code] = {
          dia: getSvgCoord(mods[0], {
            places: this.format.places
          })
        };
        if (hole != null) {
          return c.tool[code].hole = hole;
        }
        break;
      case 'R':
      case 'O':
        if (mods.length > 3) {
          hole = {
            width: getSvgCoord(mods[2], {
              places: this.format.places
            }),
            height: getSvgCoord(mods[3], {
              places: this.format.places
            })
          };
        } else if (mods.length > 2) {
          hole = {
            dia: getSvgCoord(mods[2], {
              places: this.format.places
            })
          };
        }
        c.tool[code] = {
          width: getSvgCoord(mods[0], {
            places: this.format.places
          }),
          height: getSvgCoord(mods[1], {
            places: this.format.places
          })
        };
        if (shape === 'O') {
          c.tool[code].obround = true;
        }
        if (hole != null) {
          return c.tool[code].hole = hole;
        }
        break;
      case 'P':
        if (mods.length > 4) {
          hole = {
            width: getSvgCoord(mods[3], {
              places: this.format.places
            }),
            height: getSvgCoord(mods[4], {
              places: this.format.places
            })
          };
        } else if (mods.length > 3) {
          hole = {
            dia: getSvgCoord(mods[3], {
              places: this.format.places
            })
          };
        }
        c.tool[code] = {
          dia: getSvgCoord(mods[0], {
            places: this.format.places
          }),
          verticies: +mods[1]
        };
        if (mods.length > 2) {
          c.tool[code].degrees = +mods[2];
        }
        if (hole != null) {
          return c.tool[code].hole = hole;
        }
        break;
      default:
        mods = (function() {
          var k, len, ref2, results;
          ref2 = mods != null ? mods : [];
          results = [];
          for (k = 0, len = ref2.length; k < len; k++) {
            m = ref2[k];
            results.push(+m);
          }
          return results;
        })();
        return c.tool[code] = {
          macro: shape,
          mods: mods
        };
    }
  };

  GerberParser.prototype.parseCommand = function(block) {
    var axis, c, code, coord, i, j, k, len, m, op, p, param, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, tool, u, val, x, y;
    if (block == null) {
      block = {};
    }
    c = {};
    if (param = block.param) {
      for (k = 0, len = param.length; k < len; k++) {
        p = param[k];
        switch (code = p.slice(0, 2)) {
          case 'FS':
            this.parseFormat(p, c);
            break;
          case 'MO':
            u = p.slice(2, 4);
            if (c.set == null) {
              c.set = {};
            }
            if (u === 'IN') {
              c.set.units = 'in';
            } else if (u === 'MM') {
              c.set.units = 'mm';
            } else {
              throw new Error(p + " is an invalid units setting");
            }
            break;
          case 'AD':
            this.parseToolDef(p, c);
            break;
          case 'AM':
            return {
              macro: param
            };
          case 'LP':
            if (c["new"] == null) {
              c["new"] = {};
            }
            if (p[2] === 'D' || p[2] === 'C') {
              c["new"].layer = p[2];
            }
            if (c["new"].layer == null) {
              throw new Error('invalid level polarity');
            }
            break;
          case 'SR':
            if (c["new"] == null) {
              c["new"] = {};
            }
            x = (ref = (ref1 = p.match(/X[+-]?[\d\.]+/)) != null ? ref1[0].slice(1) : void 0) != null ? ref : 1;
            y = (ref2 = (ref3 = p.match(/Y[+-]?[\d\.]+/)) != null ? ref3[0].slice(1) : void 0) != null ? ref2 : 1;
            i = (ref4 = p.match(/I[+-]?[\d\.]+/)) != null ? ref4[0].slice(1) : void 0;
            j = (ref5 = p.match(/J[+-]?[\d\.]+/)) != null ? ref5[0].slice(1) : void 0;
            if ((x < 1 || y < 1) || (x > 1 && ((i == null) || i < 0)) || (y > 1 && ((j == null) || j < 0))) {
              throw new Error('invalid step repeat');
            }
            c["new"].sr = {
              x: +x,
              y: +y
            };
            if (i != null) {
              c["new"].sr.i = getSvgCoord(i, {
                places: this.format.places
              });
            }
            if (j != null) {
              c["new"].sr.j = getSvgCoord(j, {
                places: this.format.places
              });
            }
        }
      }
    } else if (block = block.block) {
      if (block === 'M02') {
        return {
          set: {
            done: true
          }
        };
      } else if (block[0] === 'G') {
        switch (code = (ref6 = block.slice(1).match(/^\d{1,2}/)) != null ? ref6[0] : void 0) {
          case '4':
          case '04':
            return {};
          case '1':
          case '01':
          case '2':
          case '02':
          case '3':
          case '03':
            code = code[code.length - 1];
            m = code === '1' ? 'i' : code === '2' ? 'cw' : 'ccw';
            c.set = {
              mode: m
            };
            break;
          case '36':
          case '37':
            c.set = {
              region: code === '36'
            };
            break;
          case '70':
          case '71':
            c.set = {
              backupUnits: code === '70' ? 'in' : 'mm'
            };
            break;
          case '74':
          case '75':
            c.set = {
              quad: code === '74' ? 's' : 'm'
            };
        }
      }
      coord = parseCoord((ref7 = block.match(reCOORD)) != null ? ref7[0] : void 0, this.format);
      if (op = ((ref8 = block.match(/D0?[123]$/)) != null ? ref8[0] : void 0) || Object.keys(coord).length) {
        if (op != null) {
          op = op[op.length - 1];
        }
        op = (function() {
          switch (op) {
            case '1':
              return 'int';
            case '2':
              return 'move';
            case '3':
              return 'flash';
            default:
              return 'last';
          }
        })();
        c.op = {
          "do": op
        };
        for (axis in coord) {
          val = coord[axis];
          c.op[axis] = val;
        }
      } else if (tool = (ref9 = block.match(/D\d+$/)) != null ? ref9[0] : void 0) {
        c.set = {
          currentTool: tool
        };
      }
    }
    return c;
  };

  return GerberParser;

})(Parser);

module.exports = GerberParser;



},{"./coord-parser":2,"./parser":11,"./svg-coord":14}],6:[function(require,module,exports){
var GerberReader;

GerberReader = (function() {
  function GerberReader(gerberFile) {
    this.gerberFile = gerberFile != null ? gerberFile : '';
    this.line = 0;
    this.charIndex = 0;
    this.end = this.gerberFile.length;
  }

  GerberReader.prototype.nextBlock = function() {
    var char, current, parameter;
    if (this.index >= this.end) {
      return false;
    }
    current = '';
    parameter = false;
    if (this.line === 0) {
      this.line++;
    }
    while (!(this.charIndex >= this.end)) {
      char = this.gerberFile[this.charIndex++];
      if (char === '%') {
        if (!parameter) {
          parameter = [];
        } else {
          return {
            param: parameter
          };
        }
      } else if (char === '*') {
        if (parameter) {
          parameter.push(current);
          current = '';
        } else {
          return {
            block: current
          };
        }
      } else if (char === '\n') {
        this.line++;
      } else if ((' ' <= char && char <= '~')) {
        current += char;
      }
    }
    return false;
  };

  GerberReader.prototype.getLine = function() {
    return this.line;
  };

  return GerberReader;

})();

module.exports = GerberReader;



},{}],7:[function(require,module,exports){
var NUMBER, OPERATOR, TOKEN, isNumber, parse, tokenize;

OPERATOR = /[\+\-\/xX\(\)]/;

NUMBER = /[\$\d\.]+/;

TOKEN = new RegExp("(" + OPERATOR.source + ")|(" + NUMBER.source + ")", 'g');

tokenize = function(arith) {
  var results;
  return results = arith.match(TOKEN);
};

isNumber = function(token) {
  return NUMBER.test(token);
};

parse = function(arith) {
  var consume, index, parseExpression, parseMultiplication, parsePrimary, peek, tokens;
  tokens = tokenize(arith);
  index = 0;
  peek = function() {
    return tokens[index];
  };
  consume = function(t) {
    if (t === peek()) {
      return index++;
    }
  };
  parsePrimary = function() {
    var exp, t;
    t = peek();
    consume(t);
    if (isNumber(t)) {
      exp = {
        type: 'n',
        val: t
      };
    } else if (t === '(') {
      exp = parseExpression();
      if (peek() !== ')') {
        throw new Error("expected ')'");
      } else {
        consume(')');
      }
    } else {
      throw new Error(t + " is unexpected in an arithmetic string");
    }
    return exp;
  };
  parseMultiplication = function() {
    var exp, rhs, t;
    exp = parsePrimary();
    t = peek();
    while (t === 'x' || t === '/' || t === 'X') {
      consume(t);
      if (t === 'X') {
        console.warn("Warning: uppercase 'X' as multiplication symbol is incorrect; macros should use lowercase 'x' to multiply");
        t = 'x';
      }
      rhs = parsePrimary();
      exp = {
        type: t,
        left: exp,
        right: rhs
      };
      t = peek();
    }
    return exp;
  };
  parseExpression = function() {
    var exp, rhs, t;
    exp = parseMultiplication();
    t = peek();
    while (t === '+' || t === '-') {
      consume(t);
      rhs = parseMultiplication();
      exp = {
        type: t,
        left: exp,
        right: rhs
      };
      t = peek();
    }
    return exp;
  };
  return parseExpression();
};

module.exports = {
  tokenize: tokenize,
  isNumber: isNumber,
  parse: parse
};



},{}],8:[function(require,module,exports){
var MacroTool, calc, getSvgCoord, shapes, unique;

shapes = require('./pad-shapes');

calc = require('./macro-calc');

unique = require('./unique-id');

getSvgCoord = require('./svg-coord').get;

MacroTool = (function() {
  function MacroTool(blocks, numberFormat) {
    this.modifiers = {};
    this.name = blocks[0].slice(2);
    this.blocks = blocks.slice(1);
    this.shapes = [];
    this.masks = [];
    this.lastExposure = null;
    this.bbox = [null, null, null, null];
    this.format = {
      places: numberFormat
    };
  }

  MacroTool.prototype.run = function(tool, modifiers) {
    var b, group, i, j, k, l, len, len1, len2, len3, m, n, pad, padId, ref, ref1, ref2, s, shape;
    if (modifiers == null) {
      modifiers = [];
    }
    this.lastExposure = null;
    this.shapes = [];
    this.masks = [];
    this.bbox = [null, null, null, null];
    this.modifiers = {};
    for (i = j = 0, len = modifiers.length; j < len; i = ++j) {
      m = modifiers[i];
      this.modifiers["$" + (i + 1)] = m;
    }
    ref = this.blocks;
    for (k = 0, len1 = ref.length; k < len1; k++) {
      b = ref[k];
      this.runBlock(b);
    }
    padId = "tool-" + tool + "-pad-" + (unique());
    pad = [];
    ref1 = this.masks;
    for (l = 0, len2 = ref1.length; l < len2; l++) {
      m = ref1[l];
      pad.push(m);
    }
    if (this.shapes.length > 1) {
      group = {
        id: padId,
        _: []
      };
      ref2 = this.shapes;
      for (n = 0, len3 = ref2.length; n < len3; n++) {
        s = ref2[n];
        group._.push(s);
      }
      pad = [
        {
          g: group
        }
      ];
    } else if (this.shapes.length === 1) {
      shape = Object.keys(this.shapes[0])[0];
      this.shapes[0][shape].id = padId;
      pad.push(this.shapes[0]);
    }
    return {
      pad: pad,
      padId: padId,
      bbox: this.bbox,
      trace: false
    };
  };

  MacroTool.prototype.runBlock = function(block) {
    var a, args, i, j, len, mod, ref, val;
    switch (block[0]) {
      case '$':
        mod = (ref = block.match(/^\$\d+(?=\=)/)) != null ? ref[0] : void 0;
        val = block.slice(1 + mod.length);
        return this.modifiers[mod] = this.getNumber(val);
      case '1':
      case '2':
      case '20':
      case '21':
      case '22':
      case '4':
      case '5':
      case '6':
      case '7':
        args = block.split(',');
        for (i = j = 0, len = args.length; j < len; i = ++j) {
          a = args[i];
          args[i] = this.getNumber(a);
        }
        return this.primitive(args);
      default:
        if (block[0] !== '0') {
          throw new Error("'" + block + "' unrecognized tool macro block");
        }
    }
  };

  MacroTool.prototype.primitive = function(args) {
    var group, i, j, k, key, l, len, len1, len2, len3, len4, m, mask, maskId, n, o, points, q, ref, ref1, ref2, ref3, ref4, ref5, results, rot, rotation, s, shape;
    mask = false;
    rotation = false;
    shape = null;
    switch (args[0]) {
      case 1:
        shape = shapes.circle({
          dia: getSvgCoord(args[2], this.format),
          cx: getSvgCoord(args[3], this.format),
          cy: getSvgCoord(args[4], this.format)
        });
        if (args[1] === 0) {
          mask = true;
        } else {
          this.addBbox(shape.bbox);
        }
        break;
      case 2:
      case 20:
        shape = shapes.vector({
          width: getSvgCoord(args[2], this.format),
          x1: getSvgCoord(args[3], this.format),
          y1: getSvgCoord(args[4], this.format),
          x2: getSvgCoord(args[5], this.format),
          y2: getSvgCoord(args[6], this.format)
        });
        if (args[7]) {
          shape.shape.line.transform = "rotate(" + args[7] + ")";
        }
        if (args[1] === 0) {
          mask = true;
        } else {
          this.addBbox(shape.bbox, args[7]);
        }
        break;
      case 21:
        shape = shapes.rect({
          cx: getSvgCoord(args[4], this.format),
          cy: getSvgCoord(args[5], this.format),
          width: getSvgCoord(args[2], this.format),
          height: getSvgCoord(args[3], this.format)
        });
        if (args[6]) {
          shape.shape.rect.transform = "rotate(" + args[6] + ")";
        }
        if (args[1] === 0) {
          mask = true;
        } else {
          this.addBbox(shape.bbox, args[6]);
        }
        break;
      case 22:
        shape = shapes.lowerLeftRect({
          x: getSvgCoord(args[4], this.format),
          y: getSvgCoord(args[5], this.format),
          width: getSvgCoord(args[2], this.format),
          height: getSvgCoord(args[3], this.format)
        });
        if (args[6]) {
          shape.shape.rect.transform = "rotate(" + args[6] + ")";
        }
        if (args[1] === 0) {
          mask = true;
        } else {
          this.addBbox(shape.bbox, args[6]);
        }
        break;
      case 4:
        points = [];
        for (i = j = 3, ref = 3 + 2 * args[2]; j <= ref; i = j += 2) {
          points.push([getSvgCoord(args[i], this.format), getSvgCoord(args[i + 1], this.format)]);
        }
        shape = shapes.outline({
          points: points
        });
        if (rot = args[args.length - 1]) {
          shape.shape.polygon.transform = "rotate(" + rot + ")";
        }
        if (args[1] === 0) {
          mask = true;
        } else {
          this.addBbox(shape.bbox, args[args.length - 1]);
        }
        break;
      case 5:
        if (args[6] !== 0 && (args[3] !== 0 || args[4] !== 0)) {
          throw new RangeError('polygon center must be 0,0 if rotated in macro');
        }
        shape = shapes.polygon({
          cx: getSvgCoord(args[3], this.format),
          cy: getSvgCoord(args[4], this.format),
          dia: getSvgCoord(args[5], this.format),
          verticies: args[2],
          degrees: args[6]
        });
        if (args[1] === 0) {
          mask = true;
        } else {
          this.addBbox(shape.bbox);
        }
        break;
      case 6:
        if (args[9] !== 0 && (args[1] !== 0 || args[2] !== 0)) {
          throw new RangeError('moiré center must be 0,0 if rotated in macro');
        }
        shape = shapes.moire({
          cx: getSvgCoord(args[1], this.format),
          cy: getSvgCoord(args[2], this.format),
          outerDia: getSvgCoord(args[3], this.format),
          ringThx: getSvgCoord(args[4], this.format),
          ringGap: getSvgCoord(args[5], this.format),
          maxRings: args[6],
          crossThx: getSvgCoord(args[7], this.format),
          crossLength: getSvgCoord(args[8], this.format)
        });
        if (args[9]) {
          ref1 = shape.shape;
          for (k = 0, len = ref1.length; k < len; k++) {
            s = ref1[k];
            if (s.line != null) {
              s.line.transform = "rotate(" + args[9] + ")";
            }
          }
        }
        this.addBbox(shape.bbox, args[9]);
        break;
      case 7:
        if (args[9] !== 0 && (args[1] !== 0 || args[2] !== 0)) {
          throw new RangeError('thermal center must be 0,0 if rotated in macro');
        }
        shape = shapes.thermal({
          cx: getSvgCoord(args[1], this.format),
          cy: getSvgCoord(args[2], this.format),
          outerDia: getSvgCoord(args[3], this.format),
          innerDia: getSvgCoord(args[4], this.format),
          gap: getSvgCoord(args[5], this.format)
        });
        if (args[6]) {
          ref2 = shape.shape;
          for (l = 0, len1 = ref2.length; l < len1; l++) {
            s = ref2[l];
            if (s.mask != null) {
              ref3 = s.mask._;
              for (n = 0, len2 = ref3.length; n < len2; n++) {
                m = ref3[n];
                if (m.rect != null) {
                  m.rect.transform = "rotate(" + args[6] + ")";
                }
              }
            }
          }
        }
        this.addBbox(shape.bbox, args[6]);
        break;
      default:
        throw new Error(args[0] + " is not a valid primitive code");
    }
    if (mask) {
      for (key in shape.shape) {
        shape.shape[key].fill = '#000';
      }
      if (this.lastExposure !== 0) {
        this.lastExposure = 0;
        maskId = "macro-" + this.name + "-mask-" + (unique());
        m = {
          mask: {
            id: maskId
          }
        };
        m.mask._ = [
          {
            rect: {
              x: this.bbox[0],
              y: this.bbox[1],
              width: this.bbox[2] - this.bbox[0],
              height: this.bbox[3] - this.bbox[1],
              fill: '#fff'
            }
          }
        ];
        if (this.shapes.length === 1) {
          for (key in this.shapes[0]) {
            this.shapes[0][key].mask = "url(#" + maskId + ")";
          }
        } else if (this.shapes.length > 1) {
          group = {
            mask: "url(#" + maskId + ")",
            _: []
          };
          ref4 = this.shapes;
          for (o = 0, len3 = ref4.length; o < len3; o++) {
            s = ref4[o];
            group._.push(s);
          }
          this.shapes = [
            {
              g: group
            }
          ];
        }
        this.masks.push(m);
      }
      return this.masks[this.masks.length - 1].mask._.push(shape.shape);
    } else {
      this.lastExposure = 1;
      if (!Array.isArray(shape.shape)) {
        return this.shapes.push(shape.shape);
      } else {
        ref5 = shape.shape;
        results = [];
        for (q = 0, len4 = ref5.length; q < len4; q++) {
          s = ref5[q];
          if (s.mask != null) {
            results.push(this.masks.push(s));
          } else {
            results.push(this.shapes.push(s));
          }
        }
        return results;
      }
    }
  };

  MacroTool.prototype.addBbox = function(bbox, rotation) {
    var b, c, j, len, p, points, s, x, y;
    if (rotation == null) {
      rotation = 0;
    }
    if (!rotation) {
      if (this.bbox[0] === null || bbox[0] < this.bbox[0]) {
        this.bbox[0] = bbox[0];
      }
      if (this.bbox[1] === null || bbox[1] < this.bbox[1]) {
        this.bbox[1] = bbox[1];
      }
      if (this.bbox[2] === null || bbox[2] > this.bbox[2]) {
        this.bbox[2] = bbox[2];
      }
      if (this.bbox[3] === null || bbox[3] > this.bbox[3]) {
        return this.bbox[3] = bbox[3];
      }
    } else {
      s = Math.sin(rotation * Math.PI / 180);
      c = Math.cos(rotation * Math.PI / 180);
      if (Math.abs(s) < 0.000000001) {
        s = 0;
      }
      if (Math.abs(c) < 0.000000001) {
        c = 0;
      }
      points = [[bbox[0], bbox[1]], [bbox[2], bbox[1]], [bbox[2], bbox[3]], [bbox[0], bbox[3]]];
      for (j = 0, len = points.length; j < len; j++) {
        p = points[j];
        x = (p[0] * c) - (p[1] * s);
        y = (p[0] * s) + (p[1] * c);
        if (this.bbox[0] === null || x < this.bbox[0]) {
          this.bbox[0] = x;
        }
        if (this.bbox[1] === null || y < this.bbox[1]) {
          this.bbox[1] = y;
        }
        if (this.bbox[2] === null || x > this.bbox[2]) {
          this.bbox[2] = x;
        }
        if (this.bbox[3] === null || y > this.bbox[3]) {
          this.bbox[3] = y;
        }
      }
      return this.bbox = (function() {
        var k, len1, ref, results;
        ref = this.bbox;
        results = [];
        for (k = 0, len1 = ref.length; k < len1; k++) {
          b = ref[k];
          results.push(b === -0 ? 0 : b);
        }
        return results;
      }).call(this);
    }
  };

  MacroTool.prototype.getNumber = function(s) {
    if (s.match(/^[+-]?[\d.]+$/)) {
      return Number(s);
    } else if (s.match(/^\$\d+$/)) {
      return Number(this.modifiers[s]);
    } else {
      return this.evaluate(calc.parse(s));
    }
  };

  MacroTool.prototype.evaluate = function(op) {
    switch (op.type) {
      case 'n':
        return this.getNumber(op.val);
      case '+':
        return this.evaluate(op.left) + this.evaluate(op.right);
      case '-':
        return this.evaluate(op.left) - this.evaluate(op.right);
      case 'x':
        return this.evaluate(op.left) * this.evaluate(op.right);
      case '/':
        return this.evaluate(op.left) / this.evaluate(op.right);
    }
  };

  return MacroTool;

})();

module.exports = MacroTool;



},{"./macro-calc":7,"./pad-shapes":10,"./svg-coord":14,"./unique-id":15}],9:[function(require,module,exports){
var CKEY, DTAB, objToXml, repeat;

repeat = function(pattern, count) {
  var result;
  result = '';
  if (count === 0) {
    return '';
  }
  while (count > 1) {
    if (count & 1) {
      result += pattern;
    }
    count >>= 1;
    pattern += pattern;
  }
  return result + pattern;
};

CKEY = '_';

DTAB = '  ';

objToXml = function(obj, op) {
  var children, dec, decimals, elem, i, ind, j, key, len, nl, o, pre, ref, ref1, ref2, tb, v, val, xml;
  if (op == null) {
    op = {};
  }
  pre = op.pretty;
  ind = (ref = op.indent) != null ? ref : 0;
  dec = (ref1 = op.maxDec) != null ? ref1 : false;
  decimals = function(n) {
    if (typeof n === 'number') {
      return Number(n.toFixed(dec));
    } else {
      return n;
    }
  };
  nl = pre ? '\n' : '';
  tb = nl ? (typeof pre === 'string' ? pre : DTAB) : '';
  tb = repeat(tb, ind);
  xml = '';
  if (typeof obj === 'function') {
    obj = obj();
  }
  if (Array.isArray(obj)) {
    for (i = j = 0, len = obj.length; j < len; i = ++j) {
      o = obj[i];
      xml += (i !== 0 ? nl : '') + (objToXml(o, op));
    }
  } else if (typeof obj === 'object') {
    children = false;
    elem = Object.keys(obj)[0];
    if (elem != null) {
      xml = tb + "<" + elem;
      if (typeof obj[elem] === 'function') {
        obj[elem] = obj[elem]();
      }
      ref2 = obj[elem];
      for (key in ref2) {
        val = ref2[key];
        if (typeof val === 'function') {
          val = val();
        }
        if (key === CKEY) {
          children = val;
        } else {
          if (Array.isArray(val)) {
            if (dec) {
              val = (function() {
                var k, len1, results;
                results = [];
                for (k = 0, len1 = val.length; k < len1; k++) {
                  v = val[k];
                  results.push(decimals(v));
                }
                return results;
              })();
            }
            val = val.join(' ');
          }
          if (dec) {
            val = decimals(val);
          }
          xml += " " + key + "=\"" + val + "\"";
        }
      }
      if (children) {
        xml += '>' + nl + objToXml(children, {
          pretty: pre,
          indent: ind + 1
        });
      }
      if (obj[elem]._ != null) {
        xml += "" + nl + tb + "</" + elem + ">";
      } else {
        xml += '/>';
      }
    }
  } else {
    xml += obj + " ";
  }
  return xml;
};

module.exports = objToXml;



},{}],10:[function(require,module,exports){
var circle, lowerLeftRect, moire, outline, polygon, rect, thermal, unique, vector;

unique = require('./unique-id');

circle = function(p) {
  var r;
  if (p.dia == null) {
    throw new Error('circle function requires diameter');
  }
  if (p.cx == null) {
    throw new Error('circle function requires x center');
  }
  if (p.cy == null) {
    throw new Error('circle function requires y center');
  }
  r = p.dia / 2;
  return {
    shape: {
      circle: {
        cx: p.cx,
        cy: p.cy,
        r: r
      }
    },
    bbox: [p.cx - r, p.cy - r, p.cx + r, p.cy + r]
  };
};

rect = function(p) {
  var radius, rectangle, x, y;
  if (p.width == null) {
    throw new Error('rectangle requires width');
  }
  if (p.height == null) {
    throw new Error('rectangle requires height');
  }
  if (p.cx == null) {
    throw new Error('rectangle function requires x center');
  }
  if (p.cy == null) {
    throw new Error('rectangle function requires y center');
  }
  x = p.cx - p.width / 2;
  y = p.cy - p.height / 2;
  rectangle = {
    shape: {
      rect: {
        x: x,
        y: y,
        width: p.width,
        height: p.height
      }
    },
    bbox: [x, y, x + p.width, y + p.height]
  };
  if (p.obround) {
    radius = 0.5 * Math.min(p.width, p.height);
    rectangle.shape.rect.rx = radius;
    rectangle.shape.rect.ry = radius;
  }
  return rectangle;
};

polygon = function(p) {
  var i, j, points, r, ref, rx, ry, start, step, theta, x, xMax, xMin, y, yMax, yMin;
  if (p.dia == null) {
    throw new Error('polygon requires diameter');
  }
  if (p.verticies == null) {
    throw new Error('polygon requires verticies');
  }
  if (p.cx == null) {
    throw new Error('polygon function requires x center');
  }
  if (p.cy == null) {
    throw new Error('polygon function requires y center');
  }
  start = p.degrees != null ? p.degrees * Math.PI / 180 : 0;
  step = 2 * Math.PI / p.verticies;
  r = p.dia / 2;
  points = '';
  xMin = null;
  yMin = null;
  xMax = null;
  yMax = null;
  for (i = j = 0, ref = p.verticies; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
    theta = start + (i * step);
    rx = r * Math.cos(theta);
    ry = r * Math.sin(theta);
    if (Math.abs(rx) < 0.000000001) {
      rx = 0;
    }
    if (Math.abs(ry) < 0.000000001) {
      ry = 0;
    }
    x = p.cx + rx;
    y = p.cy + ry;
    if (x < xMin || xMin === null) {
      xMin = x;
    }
    if (x > xMax || xMax === null) {
      xMax = x;
    }
    if (y < yMin || yMin === null) {
      yMin = y;
    }
    if (y > yMax || yMax === null) {
      yMax = y;
    }
    points += " " + x + "," + y;
  }
  return {
    shape: {
      polygon: {
        points: points.slice(1)
      }
    },
    bbox: [xMin, yMin, xMax, yMax]
  };
};

vector = function(p) {
  var theta, xDelta, yDelta;
  if (p.x1 == null) {
    throw new Error('vector function requires start x');
  }
  if (p.y1 == null) {
    throw new Error('vector function requires start y');
  }
  if (p.x2 == null) {
    throw new Error('vector function requires end x');
  }
  if (p.y2 == null) {
    throw new Error('vector function requires end y');
  }
  if (p.width == null) {
    throw new Error('vector function requires width');
  }
  theta = Math.abs(Math.atan((p.y2 - p.y1) / (p.x2 - p.x1)));
  xDelta = p.width / 2 * Math.sin(theta);
  yDelta = p.width / 2 * Math.cos(theta);
  if (xDelta < 0.0000001) {
    xDelta = 0;
  }
  if (yDelta < 0.0000001) {
    yDelta = 0;
  }
  return {
    shape: {
      line: {
        x1: p.x1,
        x2: p.x2,
        y1: p.y1,
        y2: p.y2,
        'stroke-width': p.width,
        'stroke-linecap': 'butt'
      }
    },
    bbox: [(Math.min(p.x1, p.x2)) - xDelta, (Math.min(p.y1, p.y2)) - yDelta, (Math.max(p.x1, p.x2)) + xDelta, (Math.max(p.y1, p.y2)) + yDelta]
  };
};

lowerLeftRect = function(p) {
  if (p.width == null) {
    throw new Error('lower left rect requires width');
  }
  if (p.height == null) {
    throw new Error('lower left rect requires height');
  }
  if (p.x == null) {
    throw new Error('lower left rectangle requires x');
  }
  if (p.y == null) {
    throw new Error('lower left rectangle requires y');
  }
  return {
    shape: {
      rect: {
        x: p.x,
        y: p.y,
        width: p.width,
        height: p.height
      }
    },
    bbox: [p.x, p.y, p.x + p.width, p.y + p.height]
  };
};

outline = function(p) {
  var j, len, point, pointString, ref, x, xLast, xMax, xMin, y, yLast, yMax, yMin;
  if (!(Array.isArray(p.points) && p.points.length > 1)) {
    throw new Error('outline function requires points array');
  }
  xMin = null;
  yMin = null;
  xMax = null;
  yMax = null;
  pointString = '';
  ref = p.points;
  for (j = 0, len = ref.length; j < len; j++) {
    point = ref[j];
    if (!(Array.isArray(point) && point.length === 2)) {
      throw new Error('outline function requires points array');
    }
    x = point[0];
    y = point[1];
    if (x < xMin || xMin === null) {
      xMin = x;
    }
    if (x > xMax || xMax === null) {
      xMax = x;
    }
    if (y < yMin || yMin === null) {
      yMin = y;
    }
    if (y > yMax || yMax === null) {
      yMax = y;
    }
    pointString += " " + x + "," + y;
  }
  xLast = p.points[p.points.length - 1][0];
  yLast = p.points[p.points.length - 1][1];
  if (!(xLast === p.points[0][0] && yLast === p.points[0][1])) {
    throw new RangeError('last point must match first point of outline');
  }
  return {
    shape: {
      polygon: {
        points: pointString.slice(1)
      }
    },
    bbox: [xMin, yMin, xMax, yMax]
  };
};

moire = function(p) {
  var r, rings, shape;
  if (p.cx == null) {
    throw new Error('moiré requires x center');
  }
  if (p.cy == null) {
    throw new Error('moiré requires y center');
  }
  if (p.outerDia == null) {
    throw new Error('moiré requires outer diameter');
  }
  if (p.ringThx == null) {
    throw new Error('moiré requires ring thickness');
  }
  if (p.ringGap == null) {
    throw new Error('moiré requires ring gap');
  }
  if (p.maxRings == null) {
    throw new Error('moiré requires max rings');
  }
  if (p.crossLength == null) {
    throw new Error('moiré requires crosshair length');
  }
  if (p.crossThx == null) {
    throw new Error('moiré requires crosshair thickness');
  }
  shape = [
    {
      line: {
        x1: p.cx - p.crossLength / 2,
        y1: 0,
        x2: p.cx + p.crossLength / 2,
        y2: 0,
        'stroke-width': p.crossThx,
        'stroke-linecap': 'butt'
      }
    }, {
      line: {
        x1: 0,
        y1: p.cy - p.crossLength / 2,
        x2: 0,
        y2: p.cy + p.crossLength / 2,
        'stroke-width': p.crossThx,
        'stroke-linecap': 'butt'
      }
    }
  ];
  r = (p.outerDia - p.ringThx) / 2;
  rings = 0;
  while (r >= p.ringThx && rings < p.maxRings) {
    shape.push({
      circle: {
        cx: p.cx,
        cy: p.cy,
        r: r,
        fill: 'none',
        'stroke-width': p.ringThx
      }
    });
    rings++;
    r -= p.ringThx + p.ringGap;
  }
  r += 0.5 * p.ringThx;
  if (r > 0 && rings < p.maxRings) {
    shape.push({
      circle: {
        cx: p.cx,
        cy: p.cy,
        r: r
      }
    });
  }
  return {
    shape: shape,
    bbox: [Math.min(p.cx - p.crossLength / 2, p.cx - p.outerDia / 2), Math.min(p.cy - p.crossLength / 2, p.cy - p.outerDia / 2), Math.max(p.cx + p.crossLength / 2, p.cx + p.outerDia / 2), Math.max(p.cy + p.crossLength / 2, p.cy + p.outerDia / 2)]
  };
};

thermal = function(p) {
  var halfGap, maskId, outerR, r, thx, xMax, xMin, yMax, yMin;
  if (p.cx == null) {
    throw new Error('thermal requires x center');
  }
  if (p.cy == null) {
    throw new Error('thermal requires y center');
  }
  if (p.outerDia == null) {
    throw new Error('thermal requires outer diameter');
  }
  if (p.innerDia == null) {
    throw new Error('thermal requires inner diameter');
  }
  if (p.gap == null) {
    throw new Error('thermal requires gap');
  }
  maskId = "thermal-mask-" + (unique());
  thx = (p.outerDia - p.innerDia) / 2;
  outerR = p.outerDia / 2;
  r = outerR - thx / 2;
  xMin = p.cx - outerR;
  xMax = p.cx + outerR;
  yMin = p.cy - outerR;
  yMax = p.cy + outerR;
  halfGap = p.gap / 2;
  return {
    shape: [
      {
        mask: {
          id: maskId,
          _: [
            {
              circle: {
                cx: p.cx,
                cy: p.cy,
                r: outerR,
                fill: '#fff'
              }
            }, {
              rect: {
                x: xMin,
                y: -halfGap,
                width: p.outerDia,
                height: p.gap,
                fill: '#000'
              }
            }, {
              rect: {
                x: -halfGap,
                y: yMin,
                width: p.gap,
                height: p.outerDia,
                fill: '#000'
              }
            }
          ]
        }
      }, {
        circle: {
          cx: p.cx,
          cy: p.cy,
          r: r,
          fill: 'none',
          'stroke-width': thx,
          mask: "url(#" + maskId + ")"
        }
      }
    ],
    bbox: [xMin, yMin, xMax, yMax]
  };
};

module.exports = {
  circle: circle,
  rect: rect,
  polygon: polygon,
  vector: vector,
  lowerLeftRect: lowerLeftRect,
  outline: outline,
  moire: moire,
  thermal: thermal
};



},{"./unique-id":15}],11:[function(require,module,exports){
var Parser;

Parser = (function() {
  function Parser(formatOpts) {
    var ref, ref1;
    if (formatOpts == null) {
      formatOpts = {};
    }
    this.format = {
      zero: (ref = formatOpts.zero) != null ? ref : null,
      places: (ref1 = formatOpts.places) != null ? ref1 : null
    };
    if (this.format.places != null) {
      if ((!Array.isArray(this.format.places)) || this.format.places.length !== 2 || typeof this.format.places[0] !== 'number' || typeof this.format.places[1] !== 'number') {
        throw new Error('parser places format must be an array of two numbers');
      }
    }
    if (this.format.zero != null) {
      if (typeof this.format.zero !== 'string' || (this.format.zero !== 'L' && this.format.zero !== 'T')) {
        throw new Error("parser zero format must be either 'L' or 'T'");
      }
    }
  }

  return Parser;

})();

module.exports = Parser;



},{}],12:[function(require,module,exports){
var ASSUMED_UNITS, HALF_PI, Macro, Plotter, THREEHALF_PI, TWO_PI, coordFactor, tool, unique;

unique = require('./unique-id');

Macro = require('./macro-tool');

tool = require('./standard-tool');

coordFactor = require('./svg-coord').factor;

HALF_PI = Math.PI / 2;

THREEHALF_PI = 3 * HALF_PI;

TWO_PI = 2 * Math.PI;

ASSUMED_UNITS = 'in';

Plotter = (function() {
  function Plotter(reader, parser, opts) {
    var ref, ref1;
    this.reader = reader;
    this.parser = parser;
    if (opts == null) {
      opts = {};
    }
    this.units = (ref = opts.units) != null ? ref : null;
    this.notation = (ref1 = opts.notation) != null ? ref1 : null;
    this.macros = {};
    this.tools = {};
    this.currentTool = '';
    this.defs = [];
    this.group = {
      g: {
        _: []
      }
    };
    this.polarity = 'D';
    this.current = [];
    this.stepRepeat = {
      x: 1,
      y: 1,
      i: 0,
      j: 0
    };
    this.srOverClear = false;
    this.srOverCurrent = [];
    this.mode = null;
    this.quad = null;
    this.lastOp = null;
    this.region = false;
    this.done = false;
    this.pos = {
      x: 0,
      y: 0
    };
    this.path = [];
    this.attr = {
      'stroke-linecap': 'round',
      'stroke-linejoin': 'round',
      'stroke-width': 0,
      stroke: '#000'
    };
    this.bbox = {
      xMin: Infinity,
      yMin: Infinity,
      xMax: -Infinity,
      yMax: -Infinity
    };
    this.layerBbox = {
      xMin: Infinity,
      yMin: Infinity,
      xMax: -Infinity,
      yMax: -Infinity
    };
  }

  Plotter.prototype.addTool = function(code, params) {
    var obj, t;
    if (this.tools[code] != null) {
      throw new Error("cannot reassign tool " + code);
    }
    if (params.macro != null) {
      t = this.macros[params.macro].run(code, params.mods);
    } else {
      t = tool(code, params);
    }
    this.tools[code] = {
      trace: t.trace,
      pad: (function() {
        var k, len, ref, results;
        ref = t.pad;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          obj = ref[k];
          results.push(obj);
        }
        return results;
      })(),
      flash: function(x, y) {
        return {
          use: {
            x: x,
            y: y,
            'xlink:href': "#" + t.padId
          }
        };
      },
      flashed: false,
      bbox: function(x, y) {
        if (x == null) {
          x = 0;
        }
        if (y == null) {
          y = 0;
        }
        return {
          xMin: x + t.bbox[0],
          yMin: y + t.bbox[1],
          xMax: x + t.bbox[2],
          yMax: y + t.bbox[3]
        };
      }
    };
    return this.changeTool(code);
  };

  Plotter.prototype.changeTool = function(code) {
    var ref;
    this.finishPath();
    if (this.region) {
      throw new Error('cannot change tool when in region mode');
    }
    if (this.tools[code] == null) {
      if (!((ref = this.parser) != null ? ref.fmat : void 0)) {
        throw new Error("tool " + code + " is not defined");
      }
    } else {
      return this.currentTool = code;
    }
  };

  Plotter.prototype.command = function(c) {
    var code, m, params, ref, ref1, state, val;
    if (c.macro != null) {
      m = new Macro(c.macro, this.parser.format.places);
      this.macros[m.name] = m;
      return;
    }
    ref = c.set;
    for (state in ref) {
      val = ref[state];
      if (state === 'region') {
        this.finishPath();
      }
      switch (state) {
        case 'currentTool':
          this.changeTool(val);
          break;
        case 'units':
        case 'notation':
          if (this[state] == null) {
            this[state] = val;
          }
          break;
        default:
          this[state] = val;
      }
    }
    if (c.tool != null) {
      ref1 = c.tool;
      for (code in ref1) {
        params = ref1[code];
        this.addTool(code, params);
      }
    }
    if (c.op != null) {
      this.operate(c.op);
    }
    if (c["new"] != null) {
      this.finishLayer();
      if (c["new"].layer != null) {
        return this.polarity = c["new"].layer;
      } else if (c["new"].sr != null) {
        this.finishSR();
        return this.stepRepeat = c["new"].sr;
      }
    }
  };

  Plotter.prototype.plot = function() {
    var block, ref;
    while (!this.done) {
      block = this.reader.nextBlock();
      if (block === false) {
        if (((ref = this.parser) != null ? ref.fmat : void 0) == null) {
          throw new Error('end of file encountered before required M02 command');
        } else {
          throw new Error('end of drill file encountered before M00/M30 command');
        }
      } else {
        this.command(this.parser.parseCommand(block));
      }
    }
    return this.finish();
  };

  Plotter.prototype.finish = function() {
    this.finishPath();
    this.finishLayer();
    this.finishSR();
    this.group.g.fill = 'currentColor';
    this.group.g.stroke = 'currentColor';
    return this.group.g.transform = "translate(0," + (this.bbox.yMin + this.bbox.yMax) + ") scale(1,-1)";
  };

  Plotter.prototype.finishSR = function() {
    var k, l, layer, len, m, maskId, n, ref, ref1, ref2, ref3, ref4, ref5, u, x, y;
    if (this.srOverClear && this.srOverCurrent) {
      maskId = "gerber-sr-mask_" + (unique());
      m = {
        mask: {
          color: '#000',
          id: maskId,
          _: []
        }
      };
      m.mask._.push({
        rect: {
          fill: '#fff',
          x: this.bbox.xMin,
          y: this.bbox.yMin,
          width: this.bbox.xMax - this.bbox.xMin,
          height: this.bbox.yMax - this.bbox.yMin
        }
      });
      for (x = k = 0, ref = this.stepRepeat.x * this.stepRepeat.i, ref1 = this.stepRepeat.i; ref1 > 0 ? k < ref : k > ref; x = k += ref1) {
        for (y = l = 0, ref2 = this.stepRepeat.y * this.stepRepeat.j, ref3 = this.stepRepeat.j; ref3 > 0 ? l < ref2 : l > ref2; y = l += ref3) {
          ref4 = this.srOverCurrent;
          for (n = 0, len = ref4.length; n < len; n++) {
            layer = ref4[n];
            u = {
              use: {}
            };
            if (x !== 0) {
              u.use.x = x;
            }
            if (y !== 0) {
              u.use.y = y;
            }
            u.use['xlink:href'] = '#' + ((ref5 = layer.C) != null ? ref5 : layer.D);
            if (layer.D != null) {
              u.use.fill = '#fff';
            }
            m.mask._.push(u);
          }
        }
      }
      this.srOverClear = false;
      this.srOverCurrent = [];
      this.defs.push(m);
      return this.group.g.mask = "url(#" + maskId + ")";
    }
  };

  Plotter.prototype.finishLayer = function() {
    var c, h, id, k, l, len, n, obj, ref, ref1, ref2, srId, u, w, x, y;
    this.finishPath();
    if (!this.current.length) {
      return;
    }
    if (this.stepRepeat.x > 1 || this.stepRepeat.y > 1) {
      srId = "gerber-sr_" + (unique());
      this.current = [
        {
          g: {
            id: srId,
            _: this.current
          }
        }
      ];
      if (this.srOverClear || this.stepRepeat.i < this.layerBbox.xMax - this.layerBbox.xMin || this.stepRepeat.j < this.layerBbox.yMax - this.layerBbox.yMin) {
        obj = {};
        obj[this.polarity] = srId;
        this.srOverCurrent.push(obj);
        if (this.polarity === 'C') {
          this.srOverClear = true;
          this.defs.push(this.current[0]);
        }
      }
      for (x = k = 0, ref = this.stepRepeat.x; 0 <= ref ? k < ref : k > ref; x = 0 <= ref ? ++k : --k) {
        for (y = l = 0, ref1 = this.stepRepeat.y; 0 <= ref1 ? l < ref1 : l > ref1; y = 0 <= ref1 ? ++l : --l) {
          if (!(x === 0 && y === 0)) {
            u = {
              use: {
                'xlink:href': "#" + srId
              }
            };
            if (x !== 0) {
              u.use.x = x * this.stepRepeat.i;
            }
            if (y !== 0) {
              u.use.y = y * this.stepRepeat.j;
            }
            this.current.push(u);
          }
        }
      }
      this.layerBbox.xMax += (this.stepRepeat.x - 1) * this.stepRepeat.i;
      this.layerBbox.yMax += (this.stepRepeat.y - 1) * this.stepRepeat.j;
    }
    this.addBbox(this.layerBbox, this.bbox);
    this.layerBbox = {
      xMin: Infinity,
      yMin: Infinity,
      xMax: -Infinity,
      yMax: -Infinity
    };
    if (this.polarity === 'D') {
      if (this.group.g.mask != null) {
        this.current.unshift(this.group);
      }
      if ((this.group.g.mask == null) && this.group.g._.length) {
        ref2 = this.current;
        for (n = 0, len = ref2.length; n < len; n++) {
          c = ref2[n];
          this.group.g._.push(c);
        }
      } else {
        this.group = {
          g: {
            _: this.current
          }
        };
      }
    } else if (this.polarity === 'C' && !this.srOverClear) {
      id = "gerber-mask_" + (unique());
      w = this.bbox.xMax - this.bbox.xMin;
      h = this.bbox.yMax - this.bbox.yMin;
      this.current.unshift({
        rect: {
          x: this.bbox.xMin,
          y: this.bbox.yMin,
          width: w,
          height: h,
          fill: '#fff'
        }
      });
      this.defs.push({
        mask: {
          id: id,
          color: '#000',
          _: this.current
        }
      });
      this.group.g.mask = "url(#" + id + ")";
    }
    return this.current = [];
  };

  Plotter.prototype.finishPath = function() {
    var key, p, ref, val;
    if (this.path.length) {
      p = {
        path: {}
      };
      if (this.region) {
        this.path.push('Z');
      } else {
        ref = this.tools[this.currentTool].trace;
        for (key in ref) {
          val = ref[key];
          p.path[key] = val;
        }
      }
      p.path.d = this.path;
      this.current.push(p);
      return this.path = [];
    }
  };

  Plotter.prototype.operate = function(op) {
    var bbox, ex, ey, k, len, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, shape, sx, sy, t;
    if (op["do"] === 'last') {
      op["do"] = this.lastOp;
      console.warn('modal operation codes are deprecated');
    } else {
      this.lastOp = op["do"];
    }
    sx = this.pos.x;
    sy = this.pos.y;
    if (this.notation === 'I') {
      this.pos.x += (ref = op.x) != null ? ref : 0;
      this.pos.y += (ref1 = op.y) != null ? ref1 : 0;
    } else {
      this.pos.x = (ref2 = op.x) != null ? ref2 : this.pos.x;
      this.pos.y = (ref3 = op.y) != null ? ref3 : this.pos.y;
    }
    ex = this.pos.x;
    ey = this.pos.y;
    t = this.tools[this.currentTool];
    if (this.units == null) {
      if (this.backupUnits != null) {
        this.units = this.backupUnits;
        console.warn("units set to '" + this.units + "' according to deprecated command G7" + (this.units === 'in' ? 0 : 1));
      } else {
        this.units = ASSUMED_UNITS;
        console.warn('no units set; assuming inches');
      }
    }
    if (this.notation == null) {
      if (((ref4 = this.parser) != null ? ref4.fmat : void 0) != null) {
        this.notation = 'A';
      } else {
        throw new Error('format has not been set');
      }
    }
    if (op["do"] === 'move' && this.path.length) {
      return this.path.push('M', ex, ey);
    } else if (op["do"] === 'flash') {
      this.finishPath();
      if (this.region) {
        throw new Error('cannot flash while in region mode');
      }
      if (!t.flashed) {
        ref5 = t.pad;
        for (k = 0, len = ref5.length; k < len; k++) {
          shape = ref5[k];
          this.defs.push(shape);
        }
        t.flashed = true;
      }
      this.current.push(t.flash(ex, ey));
      return this.addBbox(t.bbox(ex, ey), this.layerBbox);
    } else if (op["do"] === 'int') {
      if (!this.region && !t.trace) {
        throw new Error(this.currentTool + " is not a strokable tool");
      }
      if (this.path.length === 0) {
        this.path.push('M', sx, sy);
        bbox = !this.region ? t.bbox(sx, sy) : {
          xMin: sx,
          yMin: sy,
          xMax: sx,
          yMax: sy
        };
        this.addBbox(bbox, this.layerBbox);
      }
      if (this.mode == null) {
        this.mode = 'i';
        console.warn('no interpolation mode set. Assuming linear (G01)');
      }
      if (this.mode === 'i') {
        return this.drawLine(sx, sy, ex, ey);
      } else {
        return this.drawArc(sx, sy, ex, ey, (ref6 = op.i) != null ? ref6 : 0, (ref7 = op.j) != null ? ref7 : 0);
      }
    }
  };

  Plotter.prototype.drawLine = function(sx, sy, ex, ey) {
    var bbox, exm, exp, eym, eyp, halfHeight, halfWidth, sxm, sxp, sym, syp, t, theta;
    t = this.tools[this.currentTool];
    bbox = !this.region ? t.bbox(ex, ey) : {
      xMin: ex,
      yMin: ey,
      xMax: ex,
      yMax: ey
    };
    this.addBbox(bbox, this.layerBbox);
    if (this.region || t.trace['stroke-width'] >= 0) {
      return this.path.push('L', ex, ey);
    } else {
      halfWidth = t.pad[0].rect.width / 2;
      halfHeight = t.pad[0].rect.height / 2;
      sxm = sx - halfWidth;
      sxp = sx + halfWidth;
      sym = sy - halfHeight;
      syp = sy + halfHeight;
      exm = ex - halfWidth;
      exp = ex + halfWidth;
      eym = ey - halfHeight;
      eyp = ey + halfHeight;
      theta = Math.atan2(ey - sy, ex - sx);
      if ((0 <= theta && theta < HALF_PI)) {
        return this.path.push('M', sxm, sym, sxp, sym, exp, eym, exp, eyp, exm, eyp, sxm, syp, 'Z');
      } else if ((HALF_PI <= theta && theta <= Math.PI)) {
        return this.path.push('M', sxm, sym, sxp, sym, sxp, syp, exp, eyp, exm, eyp, exm, eym, 'Z');
      } else if ((-Math.PI <= theta && theta < -HALF_PI)) {
        return this.path.push('M', sxp, sym, sxp, syp, sxm, syp, exm, eyp, exm, eym, exp, eym, 'Z');
      } else if ((-HALF_PI <= theta && theta < 0)) {
        return this.path.push('M', sxm, sym, exm, eym, exp, eym, exp, eyp, sxp, syp, sxm, syp, 'Z');
      }
    }
  };

  Plotter.prototype.drawArc = function(sx, sy, ex, ey, i, j) {
    var arcEps, c, cand, cen, dist, k, l, large, len, len1, r, rTool, ref, ref1, ref2, sweep, t, theta, thetaE, thetaS, validCen, xMax, xMin, xn, xp, yMax, yMin, yn, yp, zeroLength;
    arcEps = 1.5 * coordFactor * Math.pow(10, -1 * ((ref = (ref1 = this.parser) != null ? ref1.format.places[1] : void 0) != null ? ref : 7));
    t = this.tools[this.currentTool];
    if (!this.region && !t.trace['stroke-width']) {
      throw Error("cannot stroke an arc with non-circular tool " + this.currentTool);
    }
    if (this.quad == null) {
      throw new Error('arc quadrant mode has not been set');
    }
    r = Math.sqrt(Math.pow(i, 2) + Math.pow(j, 2));
    sweep = this.mode === 'cw' ? 0 : 1;
    large = 0;
    validCen = [];
    cand = [[sx + i, sy + j]];
    if (this.quad === 's') {
      cand.push([sx - i, sy - j], [sx - i, sy + j], [sx + i, sy - j]);
    }
    for (k = 0, len = cand.length; k < len; k++) {
      c = cand[k];
      dist = Math.sqrt(Math.pow(c[0] - ex, 2) + Math.pow(c[1] - ey, 2));
      if ((Math.abs(r - dist)) < arcEps) {
        validCen.push({
          x: c[0],
          y: c[1]
        });
      }
    }
    thetaE = 0;
    thetaS = 0;
    cen = null;
    for (l = 0, len1 = validCen.length; l < len1; l++) {
      c = validCen[l];
      thetaE = Math.atan2(ey - c.y, ex - c.x);
      if (thetaE < 0) {
        thetaE += TWO_PI;
      }
      thetaS = Math.atan2(sy - c.y, sx - c.x);
      if (thetaS < 0) {
        thetaS += TWO_PI;
      }
      if (this.mode === 'cw' && thetaS < thetaE) {
        thetaS += TWO_PI;
      } else if (this.mode === 'ccw' && thetaE < thetaS) {
        thetaE += TWO_PI;
      }
      theta = Math.abs(thetaE - thetaS);
      if (this.quad === 's' && theta <= HALF_PI) {
        cen = c;
      } else if (this.quad === 'm') {
        if (theta >= Math.PI) {
          large = 1;
        }
        cen = {
          x: c.x,
          y: c.y
        };
      }
      if (cen != null) {
        break;
      }
    }
    if (cen == null) {
      console.warn("start " + sx + "," + sy + " " + this.mode + " to end " + ex + "," + ey + " with center offset " + i + "," + j + " is an impossible arc in " + (this.quad === 's' ? 'single' : 'multi') + " quadrant mode with epsilon set to " + arcEps);
      return;
    }
    rTool = this.region ? 0 : t.bbox().xMax;
    if (this.mode === 'cw') {
      ref2 = [thetaS, thetaE], thetaE = ref2[0], thetaS = ref2[1];
    }
    xp = thetaS > 0 ? TWO_PI : 0;
    yp = HALF_PI + (thetaS > HALF_PI ? TWO_PI : 0);
    xn = Math.PI + (thetaS > Math.PI ? TWO_PI : 0);
    yn = THREEHALF_PI + (thetaS > THREEHALF_PI ? TWO_PI : 0);
    if ((thetaS <= xn && xn <= thetaE)) {
      xMin = cen.x - r - rTool;
    } else {
      xMin = (Math.min(sx, ex)) - rTool;
    }
    if ((thetaS <= xp && xp <= thetaE)) {
      xMax = cen.x + r + rTool;
    } else {
      xMax = (Math.max(sx, ex)) + rTool;
    }
    if ((thetaS <= yn && yn <= thetaE)) {
      yMin = cen.y - r - rTool;
    } else {
      yMin = (Math.min(sy, ey)) - rTool;
    }
    if ((thetaS <= yp && yp <= thetaE)) {
      yMax = cen.y + r + rTool;
    } else {
      yMax = (Math.max(sy, ey)) + rTool;
    }
    zeroLength = (Math.abs(sx - ex) < arcEps) && (Math.abs(sy - ey) < arcEps);
    if (this.quad === 'm' && zeroLength) {
      this.path.push('A', r, r, 0, 0, sweep, ex + 2 * i, ey + 2 * j);
      xMin = cen.x - r - rTool;
      yMin = cen.y - r - rTool;
      xMax = cen.x + r + rTool;
      yMax = cen.y + r + rTool;
    }
    this.path.push('A', r, r, 0, large, sweep, ex, ey);
    if (this.quad === 's' && zeroLength) {
      this.path.push('Z');
    }
    return this.addBbox({
      xMin: xMin,
      yMin: yMin,
      xMax: xMax,
      yMax: yMax
    }, this.layerBbox);
  };

  Plotter.prototype.addBbox = function(bbox, target) {
    if (bbox.xMin < target.xMin) {
      target.xMin = bbox.xMin;
    }
    if (bbox.yMin < target.yMin) {
      target.yMin = bbox.yMin;
    }
    if (bbox.xMax > target.xMax) {
      target.xMax = bbox.xMax;
    }
    if (bbox.yMax > target.yMax) {
      return target.yMax = bbox.yMax;
    }
  };

  return Plotter;

})();

module.exports = Plotter;



},{"./macro-tool":8,"./standard-tool":13,"./svg-coord":14,"./unique-id":15}],13:[function(require,module,exports){
var shapes, standardTool, unique;

unique = require('./unique-id');

shapes = require('./pad-shapes');

standardTool = function(tool, p) {
  var hole, id, mask, maskId, pad, result, shape;
  result = {
    pad: [],
    trace: false
  };
  p.cx = 0;
  p.cy = 0;
  id = "tool-" + tool + "-pad-" + (unique());
  shape = '';
  if ((p.dia != null) && (p.verticies == null)) {
    if ((p.obround != null) || (p.width != null) || (p.height != null) || (p.degrees != null)) {
      throw new Error("incompatible parameters for tool " + tool);
    }
    if (p.dia < 0) {
      throw new RangeError(tool + " circle diameter out of range (" + p.dia + "<0)");
    }
    shape = 'circle';
    if (p.hole == null) {
      result.trace = {
        'stroke-width': p.dia,
        fill: 'none'
      };
    }
  } else if ((p.width != null) && (p.height != null)) {
    if ((p.dia != null) || (p.verticies != null) || (p.degrees != null)) {
      throw new Error("incompatible parameters for tool " + tool);
    }
    if (p.width < 0) {
      throw new RangeError(tool + " rect width out of range (" + p.width + "<0)");
    }
    if (p.height < 0) {
      throw new RangeError(tool + " rect height out of range (" + p.height + "<0)");
    }
    shape = 'rect';
    if ((p.width === 0 || p.height === 0) && !p.obround) {
      console.warn("zero-size rectangle tools are not allowed; converting " + tool + " to a zero-size circle");
      shape = 'circle';
      p.dia = 0;
    }
    if (!((p.hole != null) || p.obround)) {
      result.trace = {};
    }
  } else if ((p.dia != null) && (p.verticies != null)) {
    if ((p.obround != null) || (p.width != null) || (p.height != null)) {
      throw new Error("incompatible parameters for tool " + tool);
    }
    if (p.verticies < 3 || p.verticies > 12) {
      throw new RangeError(tool + " polygon points out of range (" + p.verticies + "<3 or >12)]");
    }
    shape = 'polygon';
  } else {
    throw new Error('unidentified standard tool shape');
  }
  pad = shapes[shape](p);
  if (p.hole != null) {
    hole = null;
    if ((p.hole.dia != null) && (p.hole.width == null) && (p.hole.height == null)) {
      if (!(p.hole.dia >= 0)) {
        throw new RangeError(tool + " hole diameter out of range (" + p.hole.dia + "<0)");
      }
      hole = shapes.circle({
        cx: p.cx,
        cy: p.cy,
        dia: p.hole.dia
      });
      hole = hole.shape;
      hole.circle.fill = '#000';
    } else if ((p.hole.width != null) && (p.hole.height != null)) {
      if (!(p.hole.width >= 0)) {
        throw new RangeError(tool + " hole width out of range (" + p.hole.width + "<0)");
      }
      if (!(p.hole.height >= 0)) {
        throw new RangeError(tool + " hole height out of range (" + p.hole.height + "<0)");
      }
      hole = shapes.rect({
        cx: p.cx,
        cy: p.cy,
        width: p.hole.width,
        height: p.hole.height
      });
      hole = hole.shape;
      hole.rect.fill = '#000';
    } else {
      throw new Error(tool + " has invalid hole parameters");
    }
    maskId = id + '-mask';
    mask = {
      mask: {
        id: id + '-mask',
        _: [
          {
            rect: {
              x: pad.bbox[0],
              y: pad.bbox[1],
              width: pad.bbox[2] - pad.bbox[0],
              height: pad.bbox[3] - pad.bbox[1],
              fill: '#fff'
            }
          }, hole
        ]
      }
    };
    pad.shape[shape].mask = "url(#" + maskId + ")";
    result.pad.push(mask);
  }
  if (id) {
    pad.shape[shape].id = id;
  }
  result.pad.push(pad.shape);
  result.bbox = pad.bbox;
  result.padId = id;
  return result;
};

module.exports = standardTool;



},{"./pad-shapes":10,"./unique-id":15}],14:[function(require,module,exports){
var SVG_COORD_E, getSvgCoord,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

SVG_COORD_E = 3;

getSvgCoord = function(numberString, format) {
  var after, before, c, i, j, k, len, len1, ref, ref1, ref2, ref3, sign, subNumbers;
  if (numberString != null) {
    numberString = "" + numberString;
  } else {
    return NaN;
  }
  before = '';
  after = '';
  sign = '+';
  if (numberString[0] === '-' || numberString[0] === '+') {
    sign = numberString[0];
    numberString = numberString.slice(1);
  }
  if ((indexOf.call(numberString, '.') >= 0) || (format.zero == null)) {
    subNumbers = numberString.split('.');
    if (subNumbers.length > 2) {
      return NaN;
    }
    ref1 = [subNumbers[0], (ref = subNumbers[1]) != null ? ref : ''], before = ref1[0], after = ref1[1];
  } else {
    if (typeof (format != null ? (ref2 = format.places) != null ? ref2[0] : void 0 : void 0) !== 'number' || typeof (format != null ? (ref3 = format.places) != null ? ref3[1] : void 0 : void 0) !== 'number') {
      return NaN;
    }
    if (format.zero === 'T') {
      for (i = j = 0, len = numberString.length; j < len; i = ++j) {
        c = numberString[i];
        if (i < format.places[0]) {
          before += c;
        } else {
          after += c;
        }
      }
      while (before.length < format.places[0]) {
        before += '0';
      }
    } else if (format.zero === 'L') {
      for (i = k = 0, len1 = numberString.length; k < len1; i = ++k) {
        c = numberString[i];
        if (numberString.length - i <= format.places[1]) {
          after += c;
        } else {
          before += c;
        }
      }
      while (after.length < format.places[1]) {
        after = '0' + after;
      }
    }
  }
  while (after.length < SVG_COORD_E) {
    after += '0';
  }
  before = before + after.slice(0, SVG_COORD_E);
  after = after.length > SVG_COORD_E ? "." + after.slice(SVG_COORD_E) : '';
  return Number(sign + before + after);
};

module.exports = {
  get: getSvgCoord,
  factor: Math.pow(10, SVG_COORD_E)
};



},{}],15:[function(require,module,exports){
var generateUniqueId, id;

id = 1000;

generateUniqueId = function() {
  return id++;
};

module.exports = generateUniqueId;



},{}]},{},[1])(1)
});