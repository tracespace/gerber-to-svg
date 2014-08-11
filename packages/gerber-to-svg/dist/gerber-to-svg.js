!function(e){if("object"==typeof exports&&"undefined"!=typeof module)module.exports=e();else if("function"==typeof define&&define.amd)define([],e);else{var f;"undefined"!=typeof window?f=window:"undefined"!=typeof global?f=global:"undefined"!=typeof self&&(f=self),f.gerberToSvg=e()}}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

/*
@license copyright 2014 by mike cousins <mike@cousins.io> (http://cousins.io)
shared under the terms of the MIT license
view source at http://github.com/mcous/gerber-to-svg
 */
var Plotter, builder, gerberToSvg;

builder = require('./obj-to-xml');

Plotter = require('./plotter');

gerberToSvg = function(gerber) {
  var e, p, xmlObject;
  p = new Plotter(gerber);
  try {
    xmlObject = p.plot();
  } catch (_error) {
    e = _error;
    console.log("error at gerber line " + p.parser.line);
    throw e;
  }
  return builder(xmlObject, {
    pretty: true
  });
};

module.exports = gerberToSvg;



},{"./obj-to-xml":5,"./plotter":7}],2:[function(require,module,exports){
var GerberParser;

GerberParser = (function() {
  function GerberParser(file) {
    this.file = file;
    this.index = 0;
    this.line = 1;
  }

  GerberParser.prototype.nextCommand = function() {
    var blocks, char, current, done, parameter;
    blocks = [];
    current = '';
    parameter = false;
    done = false;
    while (!done) {
      char = this.file[this.index];
      if (char === '%') {
        if (!parameter) {
          parameter = true;
        } else {
          done = true;
        }
        if (current.length === 0) {
          blocks.push('%');
        } else {
          throw new Error("% after " + current + " doesn't make sense");
        }
      } else if (char === '*') {
        blocks.push(current);
        current = '';
        if (!parameter) {
          done = true;
        }
      } else if ((' ' <= char && char <= '~')) {
        current += char;
      } else if (char === '\n') {
        this.line++;
      }
      this.index++;
    }
    return blocks;
  };

  return GerberParser;

})();

module.exports = GerberParser;



},{}],3:[function(require,module,exports){
var NUMBER, OPERATOR, TOKEN, isNumber, parse, tokenize;

OPERATOR = /[\+-\/x\(\)]/;

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
        throw new SytaxError("expected ')'");
      } else {
        consume(')');
      }
    } else {
      throw new SytaxError("" + t + " is unexpected in an arithmetic string");
    }
    return exp;
  };
  parseMultiplication = function() {
    var exp, rhs, t;
    exp = parsePrimary();
    t = peek();
    while (t === 'x' || t === '/') {
      consume(t);
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



},{}],4:[function(require,module,exports){
var MacroTool, calc, shapes, unique;

shapes = require('./pad-shapes');

calc = require('./macro-calc');

unique = require('./unique-id');

MacroTool = (function() {
  function MacroTool(blocks) {
    this.modifiers = {};
    this.name = blocks[0].slice(2);
    this.blocks = blocks.slice(1);
    this.shapes = [];
    this.masks = [];
    this.bbox = [null, null, null, null];
  }

  MacroTool.prototype.run = function(tool, modifiers) {
    var b, group, i, m, pad, padId, s, shape, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2;
    if (modifiers == null) {
      modifiers = [];
    }
    for (i = _i = 0, _len = modifiers.length; _i < _len; i = ++_i) {
      m = modifiers[i];
      this.modifiers["$" + (i + 1)] = m;
    }
    _ref = this.blocks;
    for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
      b = _ref[_j];
      this.runBlock(b);
    }
    padId = "tool-" + tool + "-pad-" + (unique());
    pad = [];
    _ref1 = this.masks;
    for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
      m = _ref1[_k];
      pad.push(m);
    }
    if (this.shapes.length > 1) {
      group = {
        id: padId,
        _: []
      };
      _ref2 = this.shapes;
      for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
        s = _ref2[_l];
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
    var a, args, i, mod, val, _i, _len, _ref;
    switch (block[0]) {
      case '$':
        mod = (_ref = block.match(/^\$\d+(?=\=)/)) != null ? _ref[0] : void 0;
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
        for (i = _i = 0, _len = args.length; _i < _len; i = ++_i) {
          a = args[i];
          args[i] = this.getNumber(a);
        }
        return this.primitive(args);
      default:
        if (block[0] !== '0') {
          throw new SyntaxError("'" + block + "' unrecognized tool macro block");
        }
    }
  };

  MacroTool.prototype.primitive = function(args) {
    var group, i, key, m, mask, maskId, points, rot, rotation, s, shape, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _results;
    mask = false;
    rotation = false;
    shape = null;
    switch (args[0]) {
      case 1:
        shape = shapes.circle({
          dia: args[2],
          cx: args[3],
          cy: args[4]
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
          width: args[2],
          x1: args[3],
          y1: args[4],
          x2: args[5],
          y2: args[6]
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
          cx: args[4],
          cy: args[5],
          width: args[2],
          height: args[3]
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
          x: args[4],
          y: args[5],
          width: args[2],
          height: args[3]
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
        for (i = _i = 3, _ref = 3 + 2 * args[2]; _i <= _ref; i = _i += 2) {
          points.push([args[i], args[i + 1]]);
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
          cx: args[3],
          cy: args[4],
          dia: args[5],
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
          cx: args[1],
          cy: args[2],
          outerDia: args[3],
          ringThx: args[4],
          ringGap: args[5],
          maxRings: args[6],
          crossThx: args[7],
          crossLength: args[8]
        });
        if (args[9]) {
          _ref1 = shape.shape;
          for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
            s = _ref1[_j];
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
          cx: args[1],
          cy: args[2],
          outerDia: args[3],
          innerDia: args[4],
          gap: args[5]
        });
        if (args[6]) {
          _ref2 = shape.shape;
          for (_k = 0, _len1 = _ref2.length; _k < _len1; _k++) {
            s = _ref2[_k];
            if (s.mask != null) {
              _ref3 = s.mask._;
              for (_l = 0, _len2 = _ref3.length; _l < _len2; _l++) {
                m = _ref3[_l];
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
        throw new SyntaxError("" + args[0] + " is not a valid primitive code");
    }
    if (mask) {
      for (key in shape.shape) {
        shape.shape[key].fill = '#000';
      }
      maskId = "macro-" + this.name + "-mask-" + (unique());
      m = {
        mask: {
          id: maskId,
          _: [
            {
              rect: {
                x: this.bbox[0],
                y: this.bbox[1],
                width: this.bbox[2] - this.bbox[0],
                height: this.bbox[3] - this.bbox[1],
                fill: '#fff'
              }
            }, shape.shape
          ]
        }
      };
      if (this.shapes.length === 1) {
        for (key in this.shapes[0]) {
          this.shapes[0][key].mask = "url(#" + maskId + ")";
        }
      } else if (this.shapes.length > 1) {
        group = {
          mask: "url(#" + maskId + ")",
          _: []
        };
        _ref4 = this.shapes;
        for (_m = 0, _len3 = _ref4.length; _m < _len3; _m++) {
          s = _ref4[_m];
          group._.push(s);
        }
        this.shapes = [
          {
            g: group
          }
        ];
      }
      return this.masks.push(m);
    } else {
      if (!Array.isArray(shape.shape)) {
        return this.shapes.push(shape.shape);
      } else {
        _ref5 = shape.shape;
        _results = [];
        for (_n = 0, _len4 = _ref5.length; _n < _len4; _n++) {
          s = _ref5[_n];
          if (s.mask != null) {
            _results.push(this.masks.push(s));
          } else {
            _results.push(this.shapes.push(s));
          }
        }
        return _results;
      }
    }
  };

  MacroTool.prototype.addBbox = function(bbox, rotation) {
    var c, p, points, s, x, y, _i, _len, _results;
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
      _results = [];
      for (_i = 0, _len = points.length; _i < _len; _i++) {
        p = points[_i];
        x = p[0] * c - p[1] * s;
        y = p[0] * s + p[1] * c;
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
          _results.push(this.bbox[3] = y);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  };

  MacroTool.prototype.getNumber = function(s) {
    if (s.match(/^[+-]?[\d.]+$/)) {
      return parseFloat(s);
    } else if (s.match(/^\$\d+$/)) {
      return parseFloat(this.modifiers[s]);
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



},{"./macro-calc":3,"./pad-shapes":6,"./unique-id":9}],5:[function(require,module,exports){
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
  var children, elem, i, ind, key, nl, o, pre, tb, val, xml, _i, _len, _ref, _ref1;
  if (op == null) {
    op = {};
  }
  pre = op.pretty;
  ind = (_ref = op.indent) != null ? _ref : 0;
  nl = pre ? '\n' : '';
  tb = nl ? (typeof pre === 'string' ? pre : DTAB) : '';
  tb = repeat(tb, ind);
  xml = '';
  if (Array.isArray(obj)) {
    for (i = _i = 0, _len = obj.length; _i < _len; i = ++_i) {
      o = obj[i];
      xml += (i !== 0 ? nl : '') + (objToXml(o, op));
    }
  } else {
    children = false;
    elem = Object.keys(obj)[0];
    if (elem != null) {
      xml = "" + tb + "<" + elem;
      _ref1 = obj[elem];
      for (key in _ref1) {
        val = _ref1[key];
        if (key === CKEY) {
          children = val;
        } else {
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
  }
  return xml;
};

module.exports = objToXml;



},{}],6:[function(require,module,exports){
var circle, lowerLeftRect, moire, outline, polygon, rect, thermal, unique, vector;

unique = require('./unique-id');

circle = function(p) {
  var r;
  if (p.dia == null) {
    throw new SyntaxError('circle function requires diameter');
  }
  if (p.cx == null) {
    throw new SyntaxError('circle function requires x center');
  }
  if (p.cy == null) {
    throw new SyntaxError('circle function requires y center');
  }
  r = p.dia / 2;
  return {
    shape: {
      circle: {
        cx: p.cx,
        cy: p.cy,
        r: r,
        'stroke-width': 0,
        fill: 'currentColor'
      }
    },
    bbox: [p.cx - r, p.cy - r, p.cx + r, p.cy + r]
  };
};

rect = function(p) {
  var radius, rectangle, x, y;
  if (p.width == null) {
    throw new SyntaxError('rectangle requires width');
  }
  if (p.height == null) {
    throw new SyntaxError('rectangle requires height');
  }
  if (p.cx == null) {
    throw new SyntaxError('rectangle function requires x center');
  }
  if (p.cy == null) {
    throw new SyntaxError('rectangle function requires y center');
  }
  x = p.cx - p.width / 2;
  y = p.cy - p.height / 2;
  rectangle = {
    shape: {
      rect: {
        x: x,
        y: y,
        width: p.width,
        height: p.height,
        'stroke-width': 0,
        fill: 'currentColor'
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
  var i, points, r, rx, ry, start, step, theta, x, xMax, xMin, y, yMax, yMin, _i, _ref;
  if (p.dia == null) {
    throw new SyntaxError('polygon requires diameter');
  }
  if (p.verticies == null) {
    throw new SyntaxError('polygon requires verticies');
  }
  if (p.cx == null) {
    throw new SyntaxError('polygon function requires x center');
  }
  if (p.cy == null) {
    throw new SyntaxError('polygon function requires y center');
  }
  start = p.degrees != null ? p.degrees * Math.PI / 180 : 0;
  step = 2 * Math.PI / p.verticies;
  r = p.dia / 2;
  points = '';
  xMin = null;
  yMin = null;
  xMax = null;
  yMax = null;
  for (i = _i = 0, _ref = p.verticies; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
    theta = start + i * step;
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
        points: points.slice(1),
        'stroke-width': 0,
        fill: 'currentColor'
      }
    },
    bbox: [xMin, yMin, xMax, yMax]
  };
};

vector = function(p) {
  var theta, xDelta, yDelta;
  if (p.x1 == null) {
    throw new SyntaxError('vector function requires start x');
  }
  if (p.y1 == null) {
    throw new SyntaxError('vector function requires start y');
  }
  if (p.x2 == null) {
    throw new SyntaxError('vector function requires end x');
  }
  if (p.y2 == null) {
    throw new SyntaxError('vector function requires end y');
  }
  if (p.width == null) {
    throw new SyntaxError('vector function requires width');
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
        stroke: 'currentColor'
      }
    },
    bbox: [(Math.min(p.x1, p.x2)) - xDelta, (Math.min(p.y1, p.y2)) - yDelta, (Math.max(p.x1, p.x2)) + xDelta, (Math.max(p.y1, p.y2)) + yDelta]
  };
};

lowerLeftRect = function(p) {
  if (p.width == null) {
    throw new SyntaxError('lower left rect requires width');
  }
  if (p.height == null) {
    throw new SyntaxError('lower left rect requires height');
  }
  if (p.x == null) {
    throw new SyntaxError('lower left rectangle requires x');
  }
  if (p.y == null) {
    throw new SyntaxError('lower left rectangle requires y');
  }
  return {
    shape: {
      rect: {
        x: p.x,
        y: p.y,
        width: p.width,
        height: p.height,
        'stroke-width': 0,
        fill: 'currentColor'
      }
    },
    bbox: [p.x, p.y, p.x + p.width, p.y + p.height]
  };
};

outline = function(p) {
  var point, pointString, x, xLast, xMax, xMin, y, yLast, yMax, yMin, _i, _len, _ref;
  if (!(Array.isArray(p.points) && p.points.length > 1)) {
    throw new SyntaxError('outline function requires points array');
  }
  xMin = null;
  yMin = null;
  xMax = null;
  yMax = null;
  pointString = '';
  _ref = p.points;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    point = _ref[_i];
    if (!(Array.isArray(point) && point.length === 2)) {
      throw new SyntaxError('outline function requires points array');
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
        points: pointString.slice(1),
        'stroke-width': 0,
        fill: 'currentColor'
      }
    },
    bbox: [xMin, yMin, xMax, yMax]
  };
};

moire = function(p) {
  var r, rings, shape;
  if (p.cx == null) {
    throw new SyntaxError('moiré requires x center');
  }
  if (p.cy == null) {
    throw new SyntaxError('moiré requires y center');
  }
  if (p.outerDia == null) {
    throw new SyntaxError('moiré requires outer diameter');
  }
  if (p.ringThx == null) {
    throw new SyntaxError('moiré requires ring thickness');
  }
  if (p.ringGap == null) {
    throw new SyntaxError('moiré requires ring gap');
  }
  if (p.maxRings == null) {
    throw new SyntaxError('moiré requires max rings');
  }
  if (p.crossLength == null) {
    throw new SyntaxError('moiré requires crosshair length');
  }
  if (p.crossThx == null) {
    throw new SyntaxError('moiré requires crosshair thickness');
  }
  shape = [
    {
      line: {
        x1: p.cx - p.crossLength / 2,
        y1: 0,
        x2: p.cx + p.crossLength / 2,
        y2: 0,
        'stroke-width': p.crossThx,
        stroke: 'currentColor'
      }
    }, {
      line: {
        x1: 0,
        y1: p.cy - p.crossLength / 2,
        x2: 0,
        y2: p.cy + p.crossLength / 2,
        'stroke-width': p.crossThx,
        stroke: 'currentColor'
      }
    }
  ];
  r = (p.outerDia - p.ringThx) / 2;
  rings = 0;
  while (r >= p.ringThx && rings <= p.maxRings) {
    shape.push({
      circle: {
        cx: p.cx,
        cy: p.cy,
        r: r,
        fill: 'none',
        'stroke-width': p.ringThx,
        stroke: 'currentColor'
      }
    });
    rings++;
    r -= p.ringThx + p.ringGap;
  }
  if (r > 0 && rings <= p.maxRings) {
    shape.push({
      circle: {
        cx: p.cx,
        cy: p.cy,
        r: r,
        'stroke-width': 0,
        fill: 'currentColor'
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
    throw new SyntaxError('thermal requires x center');
  }
  if (p.cy == null) {
    throw new SyntaxError('thermal requires y center');
  }
  if (p.outerDia == null) {
    throw new SyntaxError('thermal requires outer diameter');
  }
  if (p.innerDia == null) {
    throw new SyntaxError('thermal requires inner diameter');
  }
  if (p.gap == null) {
    throw new SyntaxError('thermal requires gap');
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
                'stroke-width': 0,
                fill: '#fff'
              }
            }, {
              rect: {
                x: xMin,
                y: -halfGap,
                width: p.outerDia,
                height: p.gap,
                'stroke-width': 0,
                fill: '#000'
              }
            }, {
              rect: {
                x: -halfGap,
                y: yMin,
                width: p.gap,
                height: p.outerDia,
                'stroke-width': 0,
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
          stroke: 'currentColor',
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



},{"./unique-id":9}],7:[function(require,module,exports){
var Macro, Parser, Plotter, parseAD, tool, unique;

Parser = require('./gerber-parser');

unique = require('./unique-id');

Macro = require('./macro-tool');

tool = require('./standard-tool');

parseAD = function(block) {
  var ad, am, code, def, mods, name, params, _ref, _ref1, _ref2;
  code = (_ref = block.match(/^ADD\d+/)) != null ? (_ref1 = _ref[0]) != null ? _ref1.slice(2) : void 0 : void 0;
  if (!((code != null) && parseInt(code.slice(1), 10) > 9)) {
    throw new SyntaxError("" + code + " is an invalid tool code (must be >= 10)");
  }
  ad = null;
  am = false;
  switch (block.slice(2 + code.length, 4 + code.length)) {
    case 'C,':
      mods = block.slice(4 + code.length).split('X');
      params = {
        dia: parseFloat(mods[0])
      };
      if (mods.length > 2) {
        params.hole = {
          width: parseFloat(mods[1]),
          height: parseFloat(mods[2])
        };
      } else if (mods.length > 1) {
        params.hole = {
          dia: parseFloat(mods[1])
        };
      }
      ad = tool(code, params);
      break;
    case 'R,':
      mods = block.slice(4 + code.length).split('X');
      params = {
        width: parseFloat(mods[0]),
        height: parseFloat(mods[1])
      };
      if (mods.length > 3) {
        params.hole = {
          width: parseFloat(mods[2]),
          height: parseFloat(mods[3])
        };
      } else if (mods.length > 2) {
        params.hole = {
          dia: parseFloat(mods[2])
        };
      }
      ad = tool(code, params);
      break;
    case 'O,':
      mods = block.slice(4 + code.length).split('X');
      params = {
        width: parseFloat(mods[0]),
        height: parseFloat(mods[1])
      };
      if (mods.length > 3) {
        params.hole = {
          width: parseFloat(mods[2]),
          height: parseFloat(mods[3])
        };
      } else if (mods.length > 2) {
        params.hole = {
          dia: parseFloat(mods[2])
        };
      }
      params.obround = true;
      ad = tool(code, params);
      break;
    case 'P,':
      mods = block.slice(4 + code.length).split('X');
      params = {
        dia: parseFloat(mods[0]),
        verticies: parseFloat(mods[1])
      };
      if (mods[2] != null) {
        params.degrees = parseFloat(mods[2]);
      }
      if (mods.length > 4) {
        params.hole = {
          width: parseFloat(mods[3]),
          height: parseFloat(mods[4])
        };
      } else if (mods.length > 3) {
        params.hole = {
          dia: parseFloat(mods[3])
        };
      }
      ad = tool(code, params);
      break;
    default:
      def = block.slice(2 + code.length);
      name = (_ref2 = def.match(/[a-zA-Z_$][a-zA-Z_$.0-9]{0,126}(?=,)?/)) != null ? _ref2[0] : void 0;
      if (!name) {
        throw new SyntaxError('invalid definition with macro');
      }
      mods = def.slice(name.length + 1).split('X');
      if (mods.length === 1 && mods[0] === '') {
        mods = null;
      }
      am = {
        name: name,
        mods: mods
      };
  }
  return {
    macro: am,
    tool: ad,
    code: code
  };
};

Plotter = (function() {
  function Plotter(file) {
    if (file == null) {
      file = '';
    }
    this.parser = new Parser(file);
    this.macros = {};
    this.tools = {};
    this.currentTool = '';
    this.defs = [];
    this.gerberId = "gerber-" + (unique());
    this.group = {
      g: {
        id: "" + this.gerberId + "-layer-0",
        _: []
      }
    };
    this.layer = {
      level: 0,
      type: 'g',
      current: this.group
    };
    this.stepRepeat = {
      x: 1,
      y: 1,
      xStep: null,
      yStep: null,
      block: 0
    };
    this.done = false;
    this.units = null;
    this.format = {
      set: false,
      zero: null,
      notation: null,
      places: null
    };
    this.position = {
      x: 0,
      y: 0
    };
    this.mode = null;
    this.trace = {
      region: false,
      path: ''
    };
    this.quad = null;
    this.bbox = {
      xMin: Infinity,
      yMin: Infinity,
      xMax: -Infinity,
      yMax: -Infinity
    };
  }

  Plotter.prototype.plot = function() {
    var current;
    while (!this.done) {
      current = this.parser.nextCommand();
      if (current[0] === '%') {
        this.parameter(current);
      } else {
        this.operate(current[0]);
      }
    }
    return this.finish();
  };

  Plotter.prototype.finish = function() {
    var height, width, xml;
    this.finishTrace();
    this.finishStepRepeat();
    width = parseFloat((this.bbox.xMax - this.bbox.xMin).toPrecision(10));
    height = parseFloat((this.bbox.yMax - this.bbox.yMin).toPrecision(10));
    xml = {
      svg: {
        xmlns: 'http://www.w3.org/2000/svg',
        version: '1.1',
        'xmlns:xlink': 'http://www.w3.org/1999/xlink',
        width: "" + width + this.units,
        height: "" + height + this.units,
        viewBox: "" + this.bbox.xMin + " " + this.bbox.yMin + " " + width + " " + height,
        id: this.gerberId,
        _: []
      }
    };
    if (this.defs.length) {
      xml.svg._.push({
        defs: {
          _: this.defs
        }
      });
    }
    this.group.g.transform = "translate(0," + (this.bbox.yMin + this.bbox.yMax) + ") scale(1,-1)";
    xml.svg._.push(this.group);
    return xml;
  };

  Plotter.prototype.parameter = function(blocks) {
    var ad, block, done, error, groupId, hgt, index, invalid, m, maskId, obj, p, srBlock, u, wid, x, y, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _results;
    done = false;
    if (blocks[0] === '%' && blocks[blocks.length - 1] !== '%') {
      throw new SyntaxError('@parameter should only be called with paramters');
    }
    blocks = blocks.slice(1);
    index = 0;
    _results = [];
    while (!done) {
      block = blocks[index];
      switch (block.slice(0, 2)) {
        case 'FS':
          invalid = false;
          if (this.format.set) {
            throw new SyntaxError('format spec cannot be redefined');
          }
          try {
            if (block[2] === 'L' || block[2] === 'T') {
              this.format.zero = block[2];
            } else {
              invalid = true;
            }
            if (block[3] === 'A' || block[3] === 'I') {
              this.format.notation = block[3];
            } else {
              invalid = true;
            }
            if (block[4] === 'X' && block[7] === 'Y' && block.slice(5, 7) === block.slice(8, 10)) {
              this.format.places = [parseInt(block[5], 10), parseInt(block[6], 10)];
              if (this.format.places[0] > 7 || this.format.places[1] > 7) {
                invalid = true;
              }
            } else {
              invalid = true;
            }
          } catch (_error) {
            error = _error;
            invalid = true;
          }
          if (invalid) {
            throw new SyntaxError('invalid format spec');
          } else {
            this.format.set = true;
          }
          break;
        case 'MO':
          u = block.slice(2);
          if (this.units == null) {
            if (u === 'MM') {
              this.units = 'mm';
            } else if (u === 'IN') {
              this.units = 'in';
            } else {
              throw new SyntaxError("" + u + " are unrecognized units");
            }
          } else {
            throw new SyntaxError("gerber file may not redifine units");
          }
          break;
        case 'AD':
          ad = parseAD(blocks[index]);
          if (this.tools[ad.code] != null) {
            throw new SyntaxError('duplicate tool code');
          }
          if (ad.macro) {
            ad.tool = this.macros[ad.macro.name].run(ad.code, ad.macro.mods);
          }
          this.tools[ad.code] = {
            stroke: ad.tool.trace,
            flash: function(x, y) {
              return {
                use: {
                  x: x,
                  y: y,
                  'xlink:href': '#' + ad.tool.padId
                }
              };
            },
            bbox: function(x, y) {
              if (x == null) {
                x = 0;
              }
              if (y == null) {
                y = 0;
              }
              return {
                xMin: x + ad.tool.bbox[0],
                yMin: y + ad.tool.bbox[1],
                xMax: x + ad.tool.bbox[2],
                yMax: y + ad.tool.bbox[3]
              };
            }
          };
          _ref = ad.tool.pad;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            obj = _ref[_i];
            this.defs.push(obj);
          }
          this.currentTool = ad.code;
          break;
        case 'AM':
          m = new Macro(blocks.slice(0, -1));
          this.macros[m.name] = m;
          done = true;
          break;
        case 'SR':
          this.finishTrace();
          this.finishStepRepeat();
          this.stepRepeat.x = Number((_ref1 = (_ref2 = block.match(/X\d+/)) != null ? _ref2[0].slice(1) : void 0) != null ? _ref1 : 1);
          this.stepRepeat.y = Number((_ref3 = (_ref4 = block.match(/Y\d+/)) != null ? _ref4[0].slice(1) : void 0) != null ? _ref3 : 1);
          if (this.stepRepeat.x > 1) {
            this.stepRepeat.xStep = Number((_ref5 = block.match(/I[\d\.]+/)) != null ? _ref5[0].slice(1) : void 0);
          }
          if (this.stepRepeat.y > 1) {
            this.stepRepeat.yStep = Number((_ref6 = block.match(/J[\d\.]+/)) != null ? _ref6[0].slice(1) : void 0);
          }
          if (this.stepRepeat.x !== 1 || this.stepRepeat.y !== 1) {
            if (this.layer.level === 0) {
              srBlock = {
                g: {
                  id: "" + this.gerberId + "-sr-block-" + this.stepRepeat.block,
                  _: []
                }
              };
              this.layer.current[this.layer.type]._.push(srBlock);
              this.layer.current = srBlock;
            }
          }
          break;
        case 'LP':
          this.finishTrace();
          p = block[2];
          if (!(p === 'D' || p === 'C')) {
            throw new SyntaxError("" + block + " is an unrecognized level polarity");
          }
          if (p === 'D' && this.layer.type === 'mask') {
            groupId = "" + this.gerberId + "-layer-" + (++this.layer.level);
            this.group = {
              g: {
                id: groupId,
                _: [this.group]
              }
            };
            this.layer.current = this.group;
            this.layer.type = 'g';
          } else if (p === 'C' && this.layer.type === 'g') {
            maskId = "" + this.gerberId + "-layer-" + (++this.layer.level);
            x = this.bbox.xMin;
            y = this.bbox.yMin;
            wid = this.bbox.xMax - this.bbox.xMin;
            hgt = this.bbox.yMax - this.bbox.yMin;
            m = {
              mask: {
                id: maskId,
                color: '#000',
                _: [
                  {
                    rect: {
                      x: x,
                      y: y,
                      width: wid,
                      height: hgt,
                      fill: '#fff'
                    }
                  }
                ]
              }
            };
            this.defs.push(m);
            this.layer.current.g.mask = "url(#" + maskId + ")";
            this.layer.current = this.defs[this.defs.length - 1];
            this.layer.type = 'mask';
          }
          this.position.x = null;
          this.position.y = null;
      }
      if (blocks[++index] === '%') {
        _results.push(done = true);
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  Plotter.prototype.operate = function(block) {
    var c, cen, code, coord, cx, cy, dist, end, large, op, r, rTool, start, sweep, t, theta, thetaE, thetaS, valid, xMax, xMin, yMax, yMin, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref10, _ref11, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
    valid = false;
    code = block.slice(0, 3);
    if (block[0] === 'M') {
      if (code === 'M02') {
        this.done = true;
        block = '';
      } else if (!(code === 'M00' || code === 'M01')) {
        throw new SyntaxError('invalid operation M code');
      }
      valid = true;
    } else if (block[0] === 'G') {
      if (block.match(/^G0?1/)) {
        this.mode = 'i';
      } else if (block.match(/^G0?2/)) {
        this.mode = 'cw';
      } else if (block.match(/^G0?3(?![67])/)) {
        this.mode = 'ccw';
      } else if (code === 'G36') {
        this.finishTrace();
        this.trace.region = true;
      } else if (code === 'G37') {
        this.finishTrace();
        this.trace.region = false;
      } else if (code === 'G74') {
        this.quad = 's';
      } else if (code === 'G75') {
        this.quad = 'm';
      } else if (code === 'G70') {
        this.backupUnits = 'in';
      } else if (code === 'G71') {
        this.backupUnits = 'mm';
      } else if (!code.match(/^G(0?4)|(5[45])|(7[01])|(9[01])/)) {
        throw new SyntaxError('invalid operation G code');
      }
      valid = true;
    }
    t = (_ref = block.match(/D[1-9]\d{1,}$/)) != null ? _ref[0] : void 0;
    if (t != null) {
      this.finishTrace();
      if (this.tools[t] == null) {
        throw new SyntaxError("tool " + t + " does not exist");
      }
      if (this.trace.region) {
        throw new SyntaxError("cannot change tool while region mode is on");
      }
      this.currentTool = t;
    }
    if (block.match(/^(G0?[123])?([XYIJ][+-]?\d+){0,4}D0?[123]$/)) {
      op = block[block.length - 1];
      coord = (_ref1 = block.match(/[XYIJ][+-]?\d+/g)) != null ? _ref1.join('') : void 0;
      start = {
        x: this.position.x,
        y: this.position.y
      };
      end = this.move(coord);
      if (op === '3') {
        this.finishTrace();
        this.layer.current[this.layer.type]._.push(this.tools[this.currentTool].flash(this.position.x, this.position.y));
        return this.addBbox(this.tools[this.currentTool].bbox(this.position.x, this.position.y));
      } else if (op === '1') {
        if (!this.trace.path) {
          this.trace.path = "M" + start.x + " " + start.y;
          if (this.mode === 'i') {
            if (this.trace.region) {
              this.addBbox({
                xMin: start.x,
                yMin: start.y,
                xMax: start.x,
                yMax: start.y
              });
            } else {
              this.addBbox(this.tools[this.currentTool].bbox(start.x, start.y));
            }
          }
        }
        if (this.mode == null) {
          console.warn("Warning: no interpolation mode was set by G01/2/3. Assuming linear interpolation (G01)");
          this.mode = 'i';
        }
        if (this.mode === 'i') {
          this.trace.path += "L" + end.x + " " + end.y;
          if (this.trace.region) {
            return this.addBbox({
              xMin: end.x,
              yMin: end.y,
              xMax: end.x,
              yMax: end.y
            });
          } else {
            return this.addBbox(this.tools[this.currentTool].bbox(end.x, end.y));
          }
        } else if (this.mode === 'cw' || this.mode === 'ccw') {
          r = Math.sqrt(Math.pow(end.i, 2) + Math.pow(end.j, 2));
          sweep = this.mode === 'cw' ? 0 : 1;
          large = 0;
          cen = [];
          thetaE = 0;
          thetaS = 0;
          if (this.quad === 's') {
            _ref2 = [start.x - end.i, start.x + end.i];
            for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
              cx = _ref2[_i];
              _ref3 = [start.y - end.j, start.y + end.j];
              for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
                cy = _ref3[_j];
                dist = Math.sqrt(Math.pow(cx - end.x, 2) + Math.pow(cy - end.y, 2));
                if ((Math.abs(r - dist)) < 0.0000001) {
                  cen.push({
                    x: cx,
                    y: cy
                  });
                }
              }
            }
          } else if (this.quad === 'm') {
            cen.push({
              x: start.x + end.i,
              y: start.y + end.j
            });
          }
          for (_k = 0, _len2 = cen.length; _k < _len2; _k++) {
            c = cen[_k];
            thetaE = Math.atan2(end.y - c.y, end.x - c.x);
            if (thetaE < 0) {
              thetaE += 2 * Math.PI;
            }
            thetaS = Math.atan2(start.y - c.y, start.x - c.x);
            if (thetaS < 0) {
              thetaS += 2 * Math.PI;
            }
            if (this.mode === 'cw' && thetaS < thetaE) {
              thetaS += 2 * Math.PI;
            } else if (this.mode === 'ccw' && thetaE < thetaS) {
              thetaE += 2 * Math.PI;
            }
            theta = Math.abs(thetaE - thetaS);
            if (this.quad === 's' && Math.abs(thetaE - thetaS) > Math.PI / 2) {
              continue;
            } else {
              if (this.quad === 'm' && theta >= Math.PI) {
                large = 1;
              }
              cen = {
                x: c.x,
                y: c.y
              };
              break;
            }
          }
          rTool = this.trace.region ? 0 : this.tools[this.currentTool].bbox().xMax;
          if ((thetaS <= (_ref4 = Math.PI) && _ref4 <= thetaE) || (thetaS >= (_ref5 = Math.PI) && _ref5 >= thetaE)) {
            xMin = cen.x - r - rTool;
          } else {
            xMin = (Math.min(start.x, end.x)) - rTool;
          }
          if ((thetaS <= (_ref6 = 2 * Math.PI) && _ref6 <= thetaE) || (thetaS >= (_ref7 = 2 * Math.PI) && _ref7 >= thetaE) || (thetaS <= 0 && 0 <= thetaE) || (thetaS >= 0 && 0 >= thetaE)) {
            xMax = cen.x + r + rTool;
          } else {
            xMax = (Math.max(start.x, end.x)) + rTool;
          }
          if ((thetaS <= (_ref8 = 3 * Math.PI / 2) && _ref8 <= thetaE) || (thetaS >= (_ref9 = 3 * Math.PI / 2) && _ref9 >= thetaE)) {
            yMin = cen.y - r - rTool;
          } else {
            yMin = (Math.min(start.y, end.y)) - rTool;
          }
          if ((thetaS <= (_ref10 = Math.PI / 2) && _ref10 <= thetaE) || (thetaS >= (_ref11 = Math.PI / 2) && _ref11 >= thetaE)) {
            yMax = cen.y + r + rTool;
          } else {
            yMax = (Math.max(start.y, end.y)) + rTool;
          }
          if (this.quad === 'm' && (Math.abs(start.x - end.x) < 0.000001) && (Math.abs(start.y - end.y) < 0.000001)) {
            this.trace.path += "A" + r + " " + r + " 0 0 " + sweep + " " + (end.x + 2 * end.i) + " " + (end.y + 2 * end.j);
            xMin = cen.x - r - rTool;
            yMin = cen.y - r - rTool;
            xMax = cen.x + r + rTool;
            yMax = cen.y + r + rTool;
          }
          this.trace.path += "A" + r + " " + r + " 0 " + large + " " + sweep + " " + end.x + " " + end.y;
          return this.addBbox({
            xMin: xMin,
            yMin: yMin,
            xMax: xMax,
            yMax: yMax
          });
        } else {
          throw new SyntaxError('cannot interpolate without a G01/2/3');
        }
      } else if (op === '2') {
        return this.finishTrace();
      } else {
        throw new SyntaxError("" + op + " is an invalid operation (D) code");
      }
    }
  };

  Plotter.prototype.finishStepRepeat = function() {
    var srId, x, y, _i, _ref, _results;
    if (this.stepRepeat.x !== 1 || this.stepRepeat.y !== 1) {
      if (this.layer.level !== 0) {
        throw new Error('step repeat with clear levels is unimplimented');
      }
      srId = this.layer.current.g.id;
      this.layer.current = this.group;
      _results = [];
      for (x = _i = 0, _ref = this.stepRepeat.x; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _ref1, _results1;
          _results1 = [];
          for (y = _j = 0, _ref1 = this.stepRepeat.y; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; y = 0 <= _ref1 ? ++_j : --_j) {
            if (!(x === 0 && y === 0)) {
              _results1.push(this.layer.current[this.layer.type]._.push({
                use: {
                  x: x * this.stepRepeat.xStep,
                  y: y * this.stepRepeat.yStep,
                  'xlink:href': srId
                }
              }));
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    }
  };

  Plotter.prototype.finishTrace = function() {
    var key, p, val, _ref;
    if (this.trace.path) {
      p = {
        path: {
          d: this.trace.path
        }
      };
      if (this.trace.region) {
        p.path['stroke-width'] = 0;
        p.path.fill = 'currentColor';
      } else {
        _ref = this.tools[this.currentTool].stroke;
        for (key in _ref) {
          val = _ref[key];
          p.path[key] = val;
        }
      }
      this.layer.current[this.layer.type]._.push(p);
      return this.trace.path = '';
    }
  };

  Plotter.prototype.move = function(coord) {
    var newPosition;
    if (this.units == null) {
      if (this.backupUnits != null) {
        this.units = this.backupUnits;
        console.warn("Warning: units set to '" + this.units + "' according to deprecated command G7" + (this.units === 'in' ? 0 : 1));
      } else {
        throw new Error('units have not been set');
      }
    }
    newPosition = this.coordinate(coord);
    this.position.x = newPosition.x;
    this.position.y = newPosition.y;
    return newPosition;
  };

  Plotter.prototype.coordinate = function(coord) {
    var divisor, key, result, val, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
    if (!this.format.set) {
      throw new SyntaxError('format undefined');
    }
    result = {
      x: 0,
      y: 0
    };
    result.x = (_ref = coord.match(/X[+-]?\d+/)) != null ? (_ref1 = _ref[0]) != null ? _ref1.slice(1) : void 0 : void 0;
    result.y = (_ref2 = coord.match(/Y[+-]?\d+/)) != null ? (_ref3 = _ref2[0]) != null ? _ref3.slice(1) : void 0 : void 0;
    result.i = (_ref4 = coord.match(/I[+-]?\d+/)) != null ? (_ref5 = _ref4[0]) != null ? _ref5.slice(1) : void 0 : void 0;
    result.j = (_ref6 = coord.match(/J[+-]?\d+/)) != null ? (_ref7 = _ref6[0]) != null ? _ref7.slice(1) : void 0 : void 0;
    for (key in result) {
      val = result[key];
      if (val != null) {
        divisor = 1;
        if (val[0] === '+' || val[0] === '-') {
          if (val[0] === '-') {
            divisor = -1;
          }
          val = val.slice(1);
        }
        if (this.format.zero === 'L') {
          divisor *= Math.pow(10, this.format.places[1]);
        } else if (this.format.zero === 'T') {
          divisor *= Math.pow(10, val.length - this.format.places[0]);
        } else {
          throw new SyntaxError('invalid zero suppression format');
        }
        result[key] = Number(val) / divisor;
        if (this.format.notation === 'I') {
          result[key] += (_ref8 = this.position[key]) != null ? _ref8 : 0;
        }
      }
    }
    if (result.x == null) {
      result.x = this.position.x;
    }
    if (result.y == null) {
      result.y = this.position.y;
    }
    if (result.i == null) {
      result.i = 0;
    }
    if (result.j == null) {
      result.j = 0;
    }
    return result;
  };

  Plotter.prototype.addBbox = function(bbox) {
    if (bbox.xMin < this.bbox.xMin) {
      this.bbox.xMin = bbox.xMin;
    }
    if (bbox.yMin < this.bbox.yMin) {
      this.bbox.yMin = bbox.yMin;
    }
    if (bbox.xMax > this.bbox.xMax) {
      this.bbox.xMax = bbox.xMax;
    }
    if (bbox.yMax > this.bbox.yMax) {
      return this.bbox.yMax = bbox.yMax;
    }
  };

  return Plotter;

})();

module.exports = Plotter;



},{"./gerber-parser":2,"./macro-tool":4,"./standard-tool":8,"./unique-id":9}],8:[function(require,module,exports){
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
      throw new RangeError("" + tool + " circle diameter out of range (" + p.dia + "<0)");
    }
    shape = 'circle';
    if (p.hole == null) {
      result.trace = {
        'stroke-linecap': 'round',
        'stroke-linejoin': 'round',
        'stroke-width': p.dia,
        stroke: 'currentColor',
        fill: 'none'
      };
    }
  } else if ((p.width != null) && (p.height != null)) {
    if ((p.dia != null) || (p.verticies != null) || (p.degrees != null)) {
      throw new Error("incompatible parameters for tool " + tool);
    }
    if (p.width <= 0) {
      throw new RangeError("" + tool + " rect width out of range (" + p.width + "<=0)");
    }
    if (p.height <= 0) {
      throw new RangeError("" + tool + " rect height out of range (" + p.height + "<=0)");
    }
    shape = 'rect';
    if (!((p.hole != null) || p.obround)) {
      result.trace = {
        'stroke-width': 0
      };
    }
  } else if ((p.dia != null) && (p.verticies != null)) {
    if ((p.obround != null) || (p.width != null) || (p.height != null)) {
      throw new Error("incompatible parameters for tool " + tool);
    }
    if (p.verticies < 3 || p.verticies > 12) {
      throw new RangeError("" + tool + " polygon points out of range (" + p.verticies + "<3 or >12)]");
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
        throw new RangeError("" + tool + " hole diameter out of range (" + p.hole.dia + "<0)");
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
        throw new RangeError("" + tool + " hole width out of range (" + p.hole.width + "<0)");
      }
      if (!(p.hole.height >= 0)) {
        throw new RangeError("" + tool + " hole height out of range");
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
      throw new Error("" + tool + " has invalid hole parameters");
    }
    maskId = id + '-mask';
    mask = {
      mask: {
        id: id + "-mask",
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



},{"./pad-shapes":6,"./unique-id":9}],9:[function(require,module,exports){
var generateUniqueId, id;

id = 1000;

generateUniqueId = function() {
  return id++;
};

module.exports = generateUniqueId;



},{}]},{},[1])(1)
});