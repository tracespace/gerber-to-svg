# stream capture for testing
# from http://stackoverflow.com/a/18543419/3826558

root = window ? global
if not root.console? then root.console = {}
oldWarn = null
buf = ''

hook = ->
  buf = ''
  oldWarn = root.console?.warn
  root.console.warn = (chunk) -> buf += chunk.toString()
unhook = ->
  root.console.warn = oldWarn
  # return what was captured
  buf

module.exports = {
    hook: hook
    unhook: unhook
  }
