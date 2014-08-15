# command line tool for gerber-to-svg
fs = require 'fs'
path = require 'path'
parseArgs = require 'minimist'
chalk = require 'chalk'
gerberToSvg = require './gerber-to-svg'

# version number
VERSION = require('../package.json').version

# TAKE A LOOK AT BANNER MICHAEL
BANNER = '''
  Usage: gerber2svg [options] path/to/gerbers
  Output:
    `gerber2svg path/to/gerber.gbr` will write the svg to stdout
    `gerber2svg -o some/dir path/to/gerber.gbr` will create some/dir/gerber.svg
    `gerber2svg -d drill.drl -o out gerb/*` will process drill.drl as a drill
      file, everything in gerb as a Gerber file, and output to out
'''

OPTIONS = [
  [ 'o', 'out', '     specify an output directory' ]
  [ 'q', 'quiet', '   do not print warnings and messages' ]
  [ 'p', 'pretty', '  align SVG output prettily' ]
  [ 'd', 'drill', '   process following file as an NC (Excellon) drill file' ]
  [ 'a', 'append', '  append .svg rather than replace the old file extension' ]
  [ 'v', 'version', ' display version information' ]
  [ 'h', 'help', '    display this help text' ]
]

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
  }
  fileList = argv._

  if argv.version then return version()
  if argv.help or (argv._.length is 0 and typeof argv.drill isnt 'string')
    return help()

  # console
  warn = (string) -> console.error chalk.bold.yellow string unless argv.quiet
  print = (string) -> console.log chalk.bold.white string unless argv.quiet

  # write to the right place
  write = (string, filename) ->
    unless argv.out then process.stdout.write string
    else
      if argv.append then newName = path.basename filename
      else newName = path.basename filename, path.extname filename
      newName = path.join argv.out, newName + '.svg'
      fs.writeFile newName, string, (error) ->
        unless error then print "#{filename} converted to #{newName}"
        else warn "Error writing to #{newName}: #{error.code}"

  # add drill file if it was included
  if argv.drill? and not argv.drill in fileList then fileList.push argv.drill
  # loop through files
  for file in fileList
    do (file) ->
      fs.readFile file, 'utf-8', (error, data) ->
        unless error
          try
            opts = { pretty: argv.pretty, drill: (file is argv.drill) }
            write gerberToSvg(data, opts), file
          catch e
            warn "could not process #{file}: #{e.message}"
        else
          warn "Error reading file #{file}: #{error.code}"

module.exports = run
