# convert a decimal number or gerber/drill coordinate into an integer
# integer is identical to a gerber coordinate with leading zero suppression

# function takes in the number string to be converted and the format object
module.exports = ( numberString, format ) ->
  # first, we need to make sure we have a format
  if typeof format?.places?[0] isnt 'number' and
  typeof format?.places?[1] isnt 'number'
    return NaN
  
  # pull out the sign
  sign = '+'
  if numberString[0] is '-' or numberString[0] is '+'
    sign = numberString[0]
    numberString = numberString[1..]
  
  # check if the number has a decimal point or has been explicitely flagged
  if ('.' in numberString) or (format.zero is 'D')
    # make sure there's not more than one decimal
    subNumbers = numberString.split '.'
    if subNumbers.length > 2 then return NaN
    [before, after] = [subNumbers[0], subNumbers[1]]
    if not after? then after = []
    # truncate after to specified length
    after = after[0...-1] while after.length > format.places[1]
    # pad the after the decimal point string so
    after += '0' while after.length < format.places[1]
    # combine the before and after strings
    numberString = before + after
  # else check if it's trailing zero suppression
  else if format.zero is 'T'
    while numberString.length < format.places[0] + format.places[1]
      numberString += '0'
  # else return NaN if there was no zero format
  else if not format.zero? then return NaN
    
  # finally, parse the numberString
  parseInt(sign + numberString)
