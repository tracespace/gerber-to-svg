# gerber-to-svg [![Build Status](http://img.shields.io/travis/mcous/gerber-to-svg.svg?style=flat)](https://travis-ci.org/mcous/gerber-to-svg) [![Version](http://img.shields.io/npm/v/gerber-to-svg.svg?style=flat)](https://www.npmjs.org/package/gerber-to-svg)
Gerber file to SVG converter for Node and the browser.

## usage
### command line (with Node already installed)
1. `$ npm install -g gerber-to-svg`
2. `$ gerber2svg /path/to/gerber` (writes to stdout)
  * `$ gerber2svg /path/to/gerber > file.svg` will write to a file

### api (node and browser)

For Node and Browserify:

1. `$ npm install --save(-dev) gerber-to-svg`
2. Add `var gerberToSvg = require(gerber-to-svg);` to your JavaScript

If you'd rather not manage your packages:

1. Download the standalone [library](https://github.com/mcous/gerber-to-svg/releases/download/v0.0.10-alpha/gerber-to-svg.js) or [minified library](https://github.com/mcous/gerber-to-svg/releases/download/v0.0.10-alpha/gerber-to-svg.min.js)
2. Add `<script src="path/to/gerber-to-svg.js"></script>` to your HTML before your application

Use in your app with:
``` javascript
var svgString = gerberToSvg(gerberString);
```
Where `gerberString` is the gerber file (e.g. from fs.readFile encoded with UTF-8 or FileReader.readAsText).

## what you get
Not a whole lot, for now. This converter uses RS-274X and strives to be true to the [latest format specification](http://www.ucamco.com/files/downloads/file/81/the_gerber_file_format_specification.pdf?d69271f6602e26ab2474ad625fe40c97). Most all of the Gerber file features are there.

The returned SVG is going to be black, but you can specify `color` either in the XML or with CSS to change it.

## things to watch out for
Step and repeat is very much a work in progress. If your Gerber file uses step and repeat (i.e. contains at least one %SRX_Y_I_J_*% where one or both of the numbers after X and Y are **not** 1) and is only one polarity (i.e %LPC*% doesn't appear anywhere in your file), you should be fine. If you have both step and repeat and clear layers, though, don't necessarily trust whatever it returns (if it doesn't throw).

Arcs should work, but they've tended to give me trouble. If you see something circular and weird, that could be why.

If it messes up, open up an issue and attach your Gerber, if you can. I appreciate files to test on.

## building from source

1. `$ git clone https://github.com/mcous/gerber-to-svg.git`
2. `$ npm install && gulp`

Library files for Node and Browserify live in lib/, standalone library files live in dist/, and the command line utility lives in bin/.

### unit testing
This module uses mocha and shouldjs for unit testing. To run the tests once, run `$ gulp test`. To run the tests in watch mode, run `$ gulp testwatch`.

There's also a visual test suite. Run `$ gulp testvisual` and point your browser to http://localhost.com:4242 to take a look.
