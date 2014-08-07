# command line tool for gerber-to-svg
fs = require 'fs'
gerberToSvg = require './gerber-to-svg'

run = () ->
  args = process.argv.slice(2);
  file = args[args.length-1]

  fs.readFile file, 'utf-8', (e, d) ->
    if e then throw e else process.stdout.write gerberToSvg d
    process.exit(0)

module.exports = run
