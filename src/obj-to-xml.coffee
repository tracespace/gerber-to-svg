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
  # new line
  nl = if pre then '\n' else ''
  tb = if nl then (if typeof pre is 'string' then pre else DTAB) else ''
  tb = repeat tb, ind
  # xml
  xml = ''
  if Array.isArray obj
    for o, i in obj
      xml += (if i isnt 0 then nl else '') + (objToXml o, op)
  else
    # children
    children = false
    # get the name of the element
    elem = Object.keys(obj)[0]
    if elem?
      xml = "#{tb}<#{elem}"
      # loop through keys of the object to get attributs and children
      for key, val of obj[elem]
        if key is CKEY then children = val else xml += " #{key}=\"#{val}\""
      # tack on the children
      if children then xml +=
        '>' + nl + objToXml children, { pretty: pre, indent: ind + 1 }
      # finsish the string
      if obj[elem]._? then xml += "#{nl}#{tb}</#{elem}>" else xml += '/>'
  # return
  xml
# export
module.exports = objToXml
