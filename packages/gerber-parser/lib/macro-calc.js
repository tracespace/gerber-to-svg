(function() {
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

}).call(this);
