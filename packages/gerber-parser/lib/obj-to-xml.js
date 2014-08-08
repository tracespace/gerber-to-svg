(function() {
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

}).call(this);
