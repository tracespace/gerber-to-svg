# parser for arithmetic expressions in gerber aperture macros

# alert module
alert = require('./alert').warn

# regex matches
OPERATOR = /[\+\-\/xX\(\)]/
NUMBER = /[\$\d\.]+/
TOKEN = new RegExp "(#{OPERATOR.source})|(#{NUMBER.source})", 'g'

# split apart a arithmetic string into individual tokens
tokenize = (arith) ->
  results = arith.match TOKEN

# identify a token as a number / modifier
isNumber = (token) ->
  NUMBER.test token

# parse an arithmetic string into operation nodes and return the top node
parse = (arith) ->
  tokens = tokenize arith
  index = 0

  # some helper functions
  peek = -> tokens[index]
  consume = (t) -> if t is peek() then index++
  # recursive parsing functions
  # highest priority - numbers and parentheses
  parsePrimary = ->
    t = peek()
    consume t
    if isNumber t then exp = { type: 'n', val: t }
    else if t is '('
      exp = parseExpression()
      if peek() isnt ')' then throw new Error "expected ')'" else consume ')'
    else
      throw new Error "#{t} is unexpected in an arithmetic string"
    exp

  # second highest priority - multiplication and division
  parseMultiplication = ->
    exp = parsePrimary()
    t = peek()
    while t is 'x' or t is '/' or t is 'X'
      consume t
      # allow uppercase X as multiply with warning
      if t is 'X'
        console.warn "Warning: uppercase 'X' as multiplication symbol is
          incorrect; macros should use lowercase 'x' to multiply"
        t = 'x'
      rhs = parsePrimary()
      exp = { type: t, left: exp, right: rhs }
      t = peek()
    exp

  # lowest priority - addition and subtraction
  parseExpression = ->
    exp = parseMultiplication()
    t = peek()
    while t is '+' or t is '-'
      consume t
      rhs = parseMultiplication()
      exp = { type: t, left: exp, right: rhs }
      t = peek()
    exp

  parseExpression()

module.exports = {
  tokenize: tokenize
  isNumber: isNumber
  parse: parse
}
