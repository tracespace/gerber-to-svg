// parse a macro expression and return a function that takes mods
'use strict'

const partial = require('lodash.partial')

const reOP = /[+\-\/xX()]/
const reNUMBER = /[$\d.]+/
const reTOKEN = new RegExp([reOP.source, reNUMBER.source].join('|'), 'g')

// expects this to be bound to the parser
const parseMacroExpression = function(expr) {
  // parser
  const parser = this
  // tokenize the expression
  const tokens = expr.match(reTOKEN)

  // forward declare parse expression
  let parseExpression

  // primary tokens are numbers and parentheses
  const parsePrimary = function() {
    const t = tokens.shift()
    let exp
    if (reNUMBER.test(t)) {
      exp = {type: 'n', val: t}
    }
    else {
      exp = parseExpression()
      tokens.shift()
    }
    return exp
  }

  // parse multiplication and division tokens
  const parseMultiplication = function() {
    let exp = parsePrimary()
    let t = tokens[0]
    if (t === 'X') {
      parser._warn("multiplication in macros should use 'x', not 'X'")
      t = 'x'
    }
    while ((t === 'x') || (t === '/')) {
      tokens.shift()
      const right = parsePrimary()
      exp = {type: t, left: exp, right: right}
      t = tokens[0]
    }
    return exp
  }

  // parse addition and subtraction tokens
  parseExpression = function() {
    let exp = parseMultiplication()
    let t = tokens[0]
    while ((t === '+') || (t === '-')) {
      tokens.shift()
      const right = parseMultiplication()
      exp = {type: t, left: exp, right: right}
      t = tokens[0]
    }
    return exp
  }

  // parse the expression string into a binary tree
  const tree = parseExpression()

  // evalute by recursively traversing the tree
  const evaluate = function(op, mods) {
    const getValue = function(t) {
      if (t[0] === '$') {
        return Number(mods[t])
      }
      return Number(t)
    }

    const type = op.type
    if (type === 'n') {
      return getValue(op.val)
    }
    if (type === '+') {
      return (evaluate(op.left, mods) + evaluate(op.right, mods))
    }
    if (type === '-') {
      return (evaluate(op.left, mods) - evaluate(op.right, mods))
    }
    if (type === 'x') {
      return (evaluate(op.left, mods) * evaluate(op.right, mods))
    }
    // else division
    return (evaluate(op.left, mods) / evaluate(op.right, mods))
  }

  // return the evaluation function bound to the parsed expression tree
  return partial(evaluate, tree)
}

module.exports = parseMacroExpression
