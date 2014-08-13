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
    `gerber2svg path/to/gerber.gbr -o some/dir` will create some/dir/gerber.svg
'''

OPTIONS = [
  [ 'o', 'out', '     specify an output directory' ]
  [ 'q', 'quiet', '   run quietly (does not include svg output)' ]
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

  return version() if argv.version
  return help() if argv.help or argv._.length is 0

  # console
  warn = (string) -> console.error chalk.bold.yellow string unless argv.quiet
  print = (string) -> console.log chalk.bold.white string unless argv.quiet

  # write to the right place
  write = (string, filename) ->
    unless argv.out then process.stdout.write string
    else
      newName = path.basename(filename, path.extname filename) + '.svg'
      newName = path.join argv.out, newName
      fs.writeFile newName, string, (error) ->
        unless error then print "#{filename} converted to #{newName}"
        else warn "Error writing to #{newName}: #{error.code}"

  # loop through files
  for file in argv._
    do (file) ->
      fs.readFile file, 'utf-8', (error, data) ->
        unless error then write gerberToSvg(data), file
        else warn "Error reading file #{file}: #{error.code}"

module.exports = run
