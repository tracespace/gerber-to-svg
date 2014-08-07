(function() {
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
      var b, group, i, key, m, pad, padId, s, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2;
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
        group = [
          {
            _attr: {
              id: padId
            }
          }
        ];
        _ref2 = this.shapes;
        for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
          s = _ref2[_l];
          group.push(s);
        }
        pad = [
          {
            g: group
          }
        ];
      } else if (this.shapes.length === 1) {
        for (key in this.shapes[0]) {
          this.shapes[0][key]._attr.id = padId;
        }
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
            shape.shape.line._attr.transform = "rotate(" + args[7] + ")";
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
            shape.shape.rect._attr.transform = "rotate(" + args[6] + ")";
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
            shape.shape.rect._attr.transform = "rotate(" + args[6] + ")";
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
            shape.shape.polygon._attr.transform = "rotate(" + rot + ")";
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
                s.line._attr.transform = "rotate(" + args[9] + ")";
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
                _ref3 = s.mask;
                for (_l = 0, _len2 = _ref3.length; _l < _len2; _l++) {
                  m = _ref3[_l];
                  if (m.rect != null) {
                    m.rect._attr.transform = "rotate(" + args[6] + ")";
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
          shape.shape[key]._attr.fill = '#000';
        }
        maskId = "macro-" + this.name + "-mask-" + (unique());
        m = {
          mask: [
            {
              _attr: {
                id: maskId
              }
            }, {
              rect: {
                _attr: {
                  x: "" + this.bbox[0],
                  y: "" + this.bbox[1],
                  width: "" + (this.bbox[2] - this.bbox[0]),
                  height: "" + (this.bbox[3] - this.bbox[1]),
                  fill: '#fff'
                }
              }
            }, shape.shape
          ]
        };
        if (this.shapes.length === 1) {
          for (key in this.shapes[0]) {
            this.shapes[0][key]._attr.mask = "url(#" + maskId + ")";
          }
        } else if (this.shapes.length > 1) {
          group = [
            {
              _attr: {
                mask: "url(#" + maskId + ")"
              }
            }
          ];
          _ref4 = this.shapes;
          for (_m = 0, _len3 = _ref4.length; _m < _len3; _m++) {
            s = _ref4[_m];
            group.push(s);
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

}).call(this);
