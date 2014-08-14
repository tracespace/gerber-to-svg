# gerber-to-svg [![Build Status](http://img.shields.io/travis/mcous/gerber-to-svg.svg?style=flat)](https://travis-ci.org/mcous/gerber-to-svg) [![Coverage](http://img.shields.io/coveralls/mcous/gerber-to-svg.svg?style=flat)](https://coveralls.io/r/mcous/gerber-to-svg) [![Version](http://img.shields.io/npm/v/gerber-to-svg.svg?style=flat)](https://www.npmjs.org/package/gerber-to-svg)

Gerber file to SVG converter for Node and the browser.

## usage
### command line
1. `$ npm install -g gerber-to-svg`
2. `$ gerber2svg path/to/gerber` (writes to stdout)
  * `$ gerber2svg path/to/gerber.gbr > file.svg` will write to a specific file
  * `$ gerber2svg --out dir path/to/gerbers/*` will create an svg in `dir` for
  every file in `path/to/gerbers` it can plot

### api (node and browser)

For Node and Browserify:

1. `$ npm install --save gerber-to-svg`
2. Add `var gerberToSvg = require(gerber-to-svg);` to your JavaScript

If you'd rather not manage your packages:

1. Download the standalone [library](https://github.com/mcous/gerber-to-svg/releases/download/v0.0.11-alpha/gerber-to-svg.js)
or
[minified library](https://github.com/mcous/gerber-to-svg/releases/download/v0.0.11-alpha/gerber-to-svg.min.js)
2. Add `<script src="path/to/gerber-to-svg.js"></script>` to your HTML

Use in your app with:
``` javascript
var svgString = gerberToSvg(gerberString);
```
Where `gerberString` is the gerber file (e.g. from fs.readFile encoded with
UTF-8 or FileReader.readAsText).

## what you get
Not a whole lot, for now. This converter uses RS-274X and strives to be true to
the [latest format specification](http://www.ucamco.com/files/downloads/file/81/the_gerber_file_format_specification.pdf?d69271f6602e26ab2474ad625fe40c97).
Most of the Gerber file features are there. Since Gerber is just an image
format, this library does not attempt to identify
nor infer anything about what the file represents (e.g. a copper layer, a
silkscreen layer, etc.) It just converts it from Gerber to SVG.

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
