# module that allows user to set the warning function
# for example: in CLI, this can be set to console.warn

warningFn = ->

warn = (message) -> warningFn message

setWarn = (fn) -> warningFn = fn
    
module.exports = {
  setWarn: setWarn
  warn: warn
}
