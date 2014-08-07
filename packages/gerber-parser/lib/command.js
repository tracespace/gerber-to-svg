(function() {
  var fs, gerberToSvg, run;

  fs = require('fs');

  gerberToSvg = require('./gerber-to-svg');

  run = function() {
    var args, file;
    args = process.argv.slice(2);
    file = args[args.length - 1];
    return fs.readFile(file, 'utf-8', function(e, d) {
      if (e) {
        throw e;
      } else {
        process.stdout.write(gerberToSvg(d));
      }
      return process.exit(0);
    });
  };

  module.exports = run;

}).call(this);
