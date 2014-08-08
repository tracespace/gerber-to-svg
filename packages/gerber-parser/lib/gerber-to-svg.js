(function() {
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

}).call(this);
