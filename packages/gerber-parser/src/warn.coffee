# module that allows user to set the warning function
# for example: in CLI, this can be set to console.warn

warn = ->

setWarn = (stream) ->
  warn = stream
    
module.exports = {
  setWarn: setWarn
  warn: warn
}
