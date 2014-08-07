(function() {
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
          'stroke-width': "" + p.dia,
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
          'stroke-width': '0'
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
        hole.circle._attr.fill = '#000';
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
        hole.rect._attr.fill = '#000';
      } else {
        throw new Error("" + tool + " has invalid hole parameters");
      }
      maskId = id + '-mask';
      mask = {
        mask: [
          {
            _attr: {
              id: id + "-mask"
            }
          }, {
            rect: {
              _attr: {
                x: "" + pad.bbox[0],
                y: "" + pad.bbox[1],
                width: "" + (pad.bbox[2] - pad.bbox[0]),
                height: "" + (pad.bbox[3] - pad.bbox[1]),
                fill: '#fff'
              }
            }
          }, hole
        ]
      };
      pad.shape[shape]._attr.mask = "url(#" + maskId + ")";
      result.pad.push(mask);
    }
    if (id) {
      pad.shape[shape]._attr.id = id;
    }
    result.pad.push(pad.shape);
    result.bbox = pad.bbox;
    result.padId = id;
    return result;
  };

  module.exports = standardTool;

}).call(this);
