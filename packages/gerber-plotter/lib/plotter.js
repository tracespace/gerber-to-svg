(function() {
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
            width: parseFloat(mods[2]),
            height: parseFloat(mods[1])
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
            width: parseFloat(mods[3]),
            height: parseFloat(mods[2])
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
            width: parseFloat(mods[3]),
            height: parseFloat(mods[2])
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
            width: parseFloat(mods[4]),
            height: parseFloat(mods[3])
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
        name = (_ref2 = def.match(/[a-zA-Z_$][a-zA-Z_$.]{0,126}(?=,)?/)) != null ? _ref2[0] : void 0;
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
        g: [
          {
            _attr: {
              id: "" + this.gerberId + "-layer-0"
            }
          }
        ]
      };
      this.layer = {
        level: 0,
        type: 'g',
        current: this.group
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
      width = parseFloat((this.bbox.xMax - this.bbox.xMin).toPrecision(10));
      height = parseFloat((this.bbox.yMax - this.bbox.yMin).toPrecision(10));
      xml = {
        svg: [
          {
            _attr: {
              id: this.gerberId,
              width: "" + width + this.units,
              height: "" + height + this.units,
              viewBox: "" + this.bbox.xMin + " " + this.bbox.yMin + " " + width + " " + height
            }
          }
        ]
      };
      if (this.defs.length) {
        xml.svg.push({
          defs: this.defs
        });
      }
      xml.svg.push(this.group);
      return xml;
    };

    Plotter.prototype.parameter = function(blocks) {
      var ad, block, done, error, groupId, index, invalid, m, maskId, obj, p, u, _i, _len, _ref, _results;
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
                    _attr: {
                      x: "" + x,
                      y: "" + y,
                      'xlink:href': '#' + ad.tool.padId
                    }
                  }
                };
              },
              bbox: function(x, y) {
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
            break;
          case 'AM':
            m = new Macro(blocks.slice(0, -1));
            this.macros[m.name] = m;
            done = true;
            break;
          case 'SR':
            throw new Error('step repeat unimplimented');
            break;
          case 'LP':
            p = block[2];
            if (!(p === 'D' || p === 'C')) {
              throw new SyntaxError("" + block + " is an unrecognized level polarity");
            }
            if (p === 'D' && this.layer.type === 'mask') {
              groupId = "" + this.gerberId + "-layer-" + (++this.layer.level);
              this.group = {
                g: [
                  {
                    _attr: {
                      id: groupId
                    }
                  }, this.group
                ]
              };
              this.layer.current = this.group;
              this.layer.type = 'g';
            } else if (p === 'C' && this.layer.type === 'g') {
              maskId = "" + this.gerberId + "-layer-" + (++this.layer.level);
              this.defs.push({
                mask: [
                  {
                    _attr: {
                      id: maskId,
                      color: '#000'
                    }
                  }, {
                    rect: {
                      x: "" + this.bbox.xMin,
                      y: "" + this.bbox.yMin,
                      width: "" + (this.bbox.xMax - this.bbox.xMin),
                      height: "" + (this.bbox.yMax - this.bbox.yMin),
                      fill: '#fff'
                    }
                  }
                ]
              });
              this.layer.current.g[0]._attr.mask = "url(#" + maskId + ")";
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
      var cen, code, coord, end, large, op, r, start, sweep, theta, thetaE, thetaS, valid, _ref;
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
        } else if (!code.match(/^G(0?4)|(5[45])|(7[01])|(9[01])/)) {
          throw new SyntaxError('invalid operation G code');
        }
        valid = true;
      } else if (block[0] === 'D' && !block.match(/D0?[123]$/)) {
        if (this.tools[block] == null) {
          throw new SyntaxError("tool " + block + " does not exist");
        }
        if (this.trace.region) {
          throw new SyntaxError("cannot change tool while region mode is on");
        }
        this.currentTool = block;
      }
      if (block.match(/^(G0?[123])?([XYIJ][+-]?\d+){0,4}D0?[123]$/)) {
        op = block[block.length - 1];
        coord = (_ref = block.match(/[XYIJ][+-]?\d+/g)) != null ? _ref.join('') : void 0;
        start = {
          x: this.position.x,
          y: this.position.y
        };
        end = this.move(coord);
        if (op === '3') {
          this.finishTrace();
          this.layer.current[this.layer.type].push(this.tools[this.currentTool].flash(this.position.x, this.position.y));
          return this.addBbox(this.tools[this.currentTool].bbox(this.position.x, this.position.y));
        } else if (op === '1') {
          if (!this.trace.path) {
            this.trace.path = "M" + start.x + " " + start.y;
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
            large = this.quad === 's' ? 0 : (cen = {
              x: start.x + end.i,
              y: start.y + end.j
            }, thetaE = Math.atan2(end.y - cen.y, end.x - cen.x), thetaE < 0 ? thetaE = 2 * Math.PI + thetaE : void 0, thetaS = Math.atan2(start.y - cen.y, start.x - cen.x), thetaS < 0 ? thetaS = 2 * Math.PI + thetaS : void 0, theta = Math.abs(thetaE - thetaS), this.mode === 'ccw' ? theta = 2 * Math.PI - theta : void 0, (Math.abs(start.x - end.x) < 0.000001) && (Math.abs(start.y - end.y) < 0.000001) ? this.trace.path += "A" + r + " " + r + " 0 0 " + sweep + " " + (end.x + 2 * end.i) + " " + (end.y + 2 * end.j) : void 0, theta >= Math.PI ? 1 : 0);
            return this.trace.path += "A" + r + " " + r + " 0 " + large + " " + sweep + " " + end.x + " " + end.y;
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

    Plotter.prototype.finishTrace = function() {
      var key, p, val, _ref;
      if (this.trace.path) {
        p = {
          path: {
            _attr: {
              d: this.trace.path
            }
          }
        };
        if (this.trace.region) {
          p.path._attr['stroke-width'] = '0';
          p.path._attr.fill = 'currentColor';
        } else {
          _ref = this.tools[this.currentTool].stroke;
          for (key in _ref) {
            val = _ref[key];
            p.path._attr[key] = val;
          }
        }
        this.layer.current[this.layer.type].push(p);
        return this.trace.path = '';
      }
    };

    Plotter.prototype.move = function(coord) {
      var newPosition;
      if (this.units == null) {
        throw new Error('units have not been set');
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

}).call(this);
