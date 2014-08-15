# gerber-to-svg [![Build Status](http://img.shields.io/travis/mcous/gerber-to-svg.svg?style=flat)](https://travis-ci.org/mcous/gerber-to-svg) [![Coverage](http://img.shields.io/coveralls/mcous/gerber-to-svg.svg?style=flat)](https://coveralls.io/r/mcous/gerber-to-svg) [![Version](http://img.shields.io/npm/v/gerber-to-svg.svg?style=flat)](https://www.npmjs.org/package/gerber-to-svg)

Gerber and NC drill file to SVG converter for Node and the browser.

Got some Gerbers and want to try this out right now? Go to [svgerber](http://svgerber.cousins.io) and watch the magic.

![svg'ed gerber](./examples/clockblock-pcb-F_Cu.svg)

## usage

### command line
1. `$ npm install -g gerber-to-svg`
2. `$ gerber2svg [options] path/to/gerbers`

#### options

switch             | how it rolls
-------------------|-----------------------------------
`-o, --out`        | specify an output directory
`-q, --quiet`      | do not print warnings and messages
`-p, --pretty`     | prettily align SVG output
`-d, --drill`      | process following file as an NC (Excellon) drill file
`-a, --append-ext` | append .svg rather than replace the old file extension
`-v, --version`    | display version information
`-h, --help`       | display help text

#### examples:
* `gerber2svg path/to/gerber.gbr` will write the SVG to stdout
* `gerber2svg -o some/dir path/to/gerber.gbr` will create some/dir/gerber.svg
* `gerber2svg -d drill.drl -o out gerb/*` will process drill.drl as a drill file, everything in gerb as a Gerber file, and output to out

### api (node and browser)

For Node and Browserify:

`$ npm install --save gerber-to-svg`

If you'd rather not manage your packages:

1. Download the standalone [library](https://github.com/mcous/gerber-to-svg/releases/download/v0.0.13-alpha/gerber-to-svg.js) or [minified library](https://github.com/mcous/gerber-to-svg/releases/download/v0.0.13-alpha/gerber-to-svg.min.js)
2. Add `<script src="path/to/gerber-to-svg.js"></script>` to your HTML

Use in your app with:
``` javascript
var svgString = gerberToSvg(gerberString, opts);
```
Where `gerberString` is the gerber file (e.g. from fs.readFile encoded with UTF-8) or an SVG object previously outputted by the function.

#### options

key      | default | how it be
---------|---------|--------------------------------------------------------------
`drill`  | false   | process the string as an NC drill file rather than a Gerber
`pretty` | false   | output the SVG XML string with line-breaks and two-space tabs
`object` | false   | return an XML object instead of a the default XML string

The object will have the format:
` { node: { attr1: val, attr2: val, _: [ { childNode: { attr: val } } ] } }`

#### examples

Output an SVG to the console

``` javascript
// require gerber-to-svg library
var gerberToSvg = require('gerber-to-svg')
// read a gerber file in as a string and convert it
var gerberFile = require('fs').readFileSync('./path/to/file.gbr', 'utf-8')
var svgString = gerberToSvg(gerberFile, { pretty: true } )
// outputs pretty printed SVG
console.log(svgString)
```

Use the object output to align layers before getting the strings

``` coffeescript
# get the layer object
frontObj = gerberToSvg gerberFront, { object: true }
backObj  = gerberToSvg gerberBack, { object: true }
drillObj = gerberToSvg drillFile, { object: true, drill: true}
# pull the origina out of the viewbox
offsetFront = frontObj.svg.viewbox[0..1]
offsetBack  = backObj.svg.viewbox[0..1]
offsetDrill = drillObj.svg.viewbox[0..1]
# pass the objets back in to get the svg strings
frontString = gerberToSvg frontObj
backString  = gerberToSvg backObj
drillString = gerberToSvg drillObj
```

## what you get
Since Gerber is just an image format, this library does not attempt to identify nor infer anything about what the file represents (e.g. a copper layer, a silkscreen layer, etc.) It just takes in a Gerber and spits out an SVG. This converter uses RS-274X and strives to be true to the [latest format specification](http://www.ucamco.com/files/downloads/file/81/the_gerber_file_format_specification.pdf?d69271f6602e26ab2474ad625fe40c97). Most of the Gerber file features are there.

Everywhere that is "dark" or "exposed" in the Gerber (think a copper trace
or a line on the silkscreen) will be "currentColor" in the SVG. You can set this
with the "color" CSS property or the "color" attribute in the svg node itself.

Everywhere that is "clear" (anywhere that was never drawn on or was drawn on but
cleared later) will be transparent. This is accomplished though judicious use of
SVG masks and groups.

The bounding box is carefully calculated as the Gerber's being converted, so the `width` and `height` of the resulting SVG should be nearly (if not exactly) the real world size of the Gerber image. The SVG's `viewBox` is in Gerber units, so its `min-x` and `min-y` values can be used to align SVGs generated from different board layers.

## things to watch out for
Step and repeat is very much a work in progress. If your Gerber file uses step
and repeat (i.e. contains at least one %SRX_Y_I_J_\*% where one or both of the
numbers after X and Y are **not** 1) and is only one polarity (i.e. %LPC*%
doesn't appear anywhere in your file), you should be fine. If you have both step
and repeat and clear layers, though, don't necessarily trust whatever it returns
(if it doesn't throw).

Arcs should work, but they've tended to give me trouble. If you see something
circular and weird, that could be why.

If it messes up, open up an issue and attach your Gerber, if you can. I
appreciate files to test on.

## building from source

1. `$ git clone https://github.com/mcous/gerber-to-svg.git`
2. `$ npm install && gulp build`
3. `$ gulp build` or `$ gulp watch` to rebuild or rebuild on source changes

Library files for Node live in lib/, standalone library files
live in dist/, and the command line utility lives in bin/.

### unit testing
This module uses mocha and shouldjs for unit testing. To run the tests once, run
`$ gulp test`. To run the tests automatically when source or tests change, run `$ gulp testwatch`.

There's also a visual test suite. Run `$ gulp testvisual` and point your browser
to http://localhost.com:4242 to take a look. This will also run the build watcher
