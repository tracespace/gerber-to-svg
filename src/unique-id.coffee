# unique number generator for id
# needed for masks and such
# let's hope this dead simple thing works without any coliisions

id = 1000

generateUniqueId = ->
  id++

module.exports = generateUniqueId
