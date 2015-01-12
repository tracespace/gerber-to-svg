# command line tool for gerber-to-svg
fs = require 'fs'
path = require 'path'

parseArgs = require 'minimist'
chalk = require 'chalk'

gerberToSvg = require './gerber-to-svg'

# stream capture
streamCapture = (stream) ->
  oldWrite = stream.write
  buf = ''
  stream.write = (chunk, encoding, callback) -> buf += chunk.toString()
  return {
    unhook: -> stream.write = oldWrite
    captured: -> buf
  }
stderr = -> streamCapture(process.stderr)

# version number
VERSION = require('../package.json').version

# TAKE A LOOK AT BANNER MICHAEL
BANNER = '''
  Usage: gerber2svg [options] path/to/gerbers
  Examples:
    `$ gerber2svg path/to/gerber.gbr` will write the svg to stdout
    `$ gerber2svg -o some/dir path/to/gerb.gbr` will create some/dir/gerb.svg
    `$ gerber2svg -d drill.drl -o out gerb/*` will process drill.drl as a drill
      file, everything in gerb as a Gerber file, and output to out
'''

OPTIONS = [
  ['o', 'out', '        specify an output directory']
  ['q', 'quiet', '      do not print warnings and messages']
  ['p', 'pretty', '     align SVG output prettily']
  ['d', 'drill', '      process following file as an NC (Excellon) drill file']
  ['f', 'format', "     override coordinate format with '[n_int,n_dec]'"]
  ['z', 'zero', "       override zero suppression with 'L' or 'T'"]
  ['u', 'units', "      override (without converting) units with 'mm' or 'in'"]
  ['n', 'notation', "   override absolute/incremental notation with 'A' or 'I'"]
  ['a', 'append-ext', ' append .svg rather than replace the extension']
  ['j', 'json', '       output json rather than an xml string']
  ['v', 'version', '    display version information']
  ['h', 'help', '       display this help text']
]
STRING_OPTS  = ['out', 'drill', 'format', 'zero', 'units', 'notation']
BOOLEAN_OPTS = ['quiet', 'pretty', 'append-ext', 'json', 'version', 'help']

printOptions = ->
  console.log 'Options:'
  console.log "  -#{o[0]}, --#{o[1]} #{o[2]}" for o in OPTIONS

getOptions = ->
  alias = {}
  alias[o[0]] = o[1] for o in OPTIONS
  alias

version = -> console.log "gerber-to-svg version #{VERSION}"
help = ->
  version()
  console.log BANNER
  printOptions()

run = ->
  argv = parseArgs process.argv.slice(2), {
    alias: getOptions()
    string: STRING_OPTS
    boolean: BOOLEAN_OPTS
  }
  fileList = argv._

  if argv.version then return version()
  if argv.help or (argv._.length is 0 and typeof argv.drill isnt 'string')
    return help()

  # console
  err = (string) -> console.error chalk.bold.red string
  warn = (string) -> console.warn chalk.bold.yellow string unless argv.quiet
  print = (string) -> console.log chalk.bold.white string unless argv.quiet

  # write to the right place
  write = (string, filename) ->
    if typeof string is 'object'
      string = JSON.stringify string, null, (if argv.pretty then '  ' else '')
    unless argv.out
      process.stdout.write string
    else
      if argv['append-ext']
        newName = path.basename filename
      else
        newName = path.basename filename, path.extname filename
      newName = path.join argv.out, newName + '.svg'
      fs.writeFile newName, string, (error) ->
        unless error
          print "#{filename} converted to #{newName}"
        else
          "Error writing to #{newName}: #{error.code}"

  # process processing override options
  # coordinate format
  if argv.format?
    try
      places = JSON.parse argv.format
      if places.length isnt 2 or
      typeof places[0] isnt 'number' or
      typeof places[1] isnt 'number'
        throw new Error()
    catch e
      err "format must be specified as '[n_int,n_dec]'"
      return help()
    argv.format = places
  # zero suppression
  if argv.zero? and argv.zero isnt 'L' and argv.zero isnt 'T'
    err "zero suppression must be either 'L' for leading or 'T' for trailing"
    return help()
  # units
  if argv.units? and argv.units isnt 'mm' and argv.units isnt 'in'
    err "units must be either 'mm' for millimeters or 'in' for inches"
    return help()
  # notation
  if argv.notation? and argv.notation isnt 'A' and argv.notation isnt 'I'
    err "notation must be either 'A' for absolute or 'I' for incremental"
    return help()

  # add drill file if it was included
  if argv.drill? and argv.drill not in fileList then fileList.push argv.drill

  # loop through files
  for file in fileList
    do (file) ->
      fs.readFile file, 'utf-8', (error, data) ->
        unless error
          try
            hook = stderr()
            opts = {
              pretty: argv.pretty
              drill: (file is argv.drill)
              object: argv.json
              places: argv.format
              zero: argv.zero
              units: argv.units
              notation: argv.notation
            }
            write gerberToSvg(data, opts), file
          catch e
            warn "could not process #{file}: #{e.message}"
          finally
            warnings = hook.captured()
            hook.unhook()
            if warnings then warn """
              #{file} produced the following warnings:
              #{warnings}
            """
        else
          warn "Error reading file #{file}: #{error.code}"

module.exports = run
