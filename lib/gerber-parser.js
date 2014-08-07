(function() {
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

}).call(this);
