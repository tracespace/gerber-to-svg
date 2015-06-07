# convert a decimal number or gerber/drill coordinate into an svg coordinate
# coordinate is 1000x the gerber unit

# svg coordinate scaling factor and power of ten exponent
SVG_COORD_E = 3

# function takes in the number string to be converted and the format object
getSvgCoord = (numberString, format) ->
  # make sure we're dealing with a string
  if numberString? then numberString = "#{numberString}" else return NaN

  # pull out the sign and get the before and after segments ready
  before = ''
  after = ''
  sign = '+'
  if numberString[0] is '-' or numberString[0] is '+'
    sign = numberString[0]
    numberString = numberString[1..]

  # check if the number has a decimal point or has been explicitely flagged
  if ('.' in numberString) or (not format.zero?)
    # make sure there's not more than one decimal
    subNumbers = numberString.split '.'
    if subNumbers.length > 2 then return NaN
    [before, after] = [subNumbers[0], subNumbers[1] ? '']

  else
    # otherwise we're going to need a number format
    if typeof format?.places?[0] isnt 'number' or
    typeof format?.places?[1] isnt 'number'
      return NaN
    # split according to traling zero suppression or leading zero suppression
    if format.zero is 'T'
      for c, i in numberString
        if i < format.places[0] then before += c else after += c
      # pad any missing zeros
      before += '0' while before.length < format.places[0]
    else if format.zero is 'L'
      for c, i in numberString
        if numberString.length - i <= format.places[1]
          after += c
        else
          before += c
      # pad any missing zeros
      after = ('0' + after) while after.length < format.places[1]
    else
      return NaN

  # pad after so we've got enough digits
  after += '0' while after.length < SVG_COORD_E
  # throw in a decimal point
  before = before + after[0...SVG_COORD_E]
  after = if after.length > SVG_COORD_E then ".#{after[SVG_COORD_E..]}" else ''

  # finally, parse the numberString
  Number(sign + before + after)

# export
module.exports = { get: getSvgCoord, factor: 10 ** SVG_COORD_E }
