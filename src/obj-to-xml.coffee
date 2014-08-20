# dead simple object to xml string parser

# fast string repeat function for convenience
# from http://stackoverflow.com/a/5450113/3826558
repeat = (pattern, count) ->
  result = ''
  if count is 0 then return ''
  while count > 1
    if count & 1 then result += pattern
    count >>= 1
    pattern += pattern
  result + pattern

CKEY = '_'
DTAB = '  '
objToXml = ( obj, op = {} ) ->
  # parse options
  pre = op.pretty
  ind = op.indent ? 0
  dec = op.maxDec ? false
  # round to a precision
  decimals = (n) ->
    if typeof n is 'number' then Number n.toFixed dec else n
  # new line
  nl = if pre then '\n' else ''
  tb = if nl then (if typeof pre is 'string' then pre else DTAB) else ''
  tb = repeat tb, ind
  # xml
  xml = ''
  # check if obj is a function, if it is, get its value
  if typeof obj is 'function' then obj = obj()
  # array
  if Array.isArray obj
    for o, i in obj
      xml += (if i isnt 0 then nl else '') + (objToXml o, op)
  # object
  else if typeof obj is 'object'
    # children
    children = false
    # get the name of the element
    elem = Object.keys(obj)[0]
    if elem?
      xml = "#{tb}<#{elem}"
      if typeof obj[elem] is 'function' then obj[elem] = obj[elem]()
      # loop through keys of the object to get attributs and children
      for key, val of obj[elem]
        if typeof val is 'function' then val = val()
        if key is CKEY then children = val
        else
          # if it's an array of values, let's join with a space
          if Array.isArray val
            if dec then val = (decimals v for v in val)
            val = val.join ' '
          if dec then val = decimals val
          xml += " #{key}=\"#{val}\""
      # tack on the children
      if children then xml +=
        '>' + nl + objToXml children, { pretty: pre, indent: ind + 1 }
      # finsish the string
      if obj[elem]._? then xml += "#{nl}#{tb}</#{elem}>" else xml += '/>'
  # anything else becomes text separated by whitespace
  else xml += "#{obj} "
  # return
  xml
# export
module.exports = objToXml
