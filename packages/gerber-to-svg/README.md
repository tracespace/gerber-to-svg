# gerber-to-svg
Javascript Gerber file to SVG converter for Node and the browser.

## usage
### command line (with Node already installed)
1. `$ npm install -g gerber-to-svg`
2. `$ gerber2svg /path/to/gerber` (writes to stdout)
  * `$ gerber2svg /path/to/gerber > file.svg` will write to a file

### api (with Node or in the Browser with Browserify)
1. `$ npm install --save(-dev) gerber-to-svg`

Use in your app with:
``` javascript
var gerberToSvg = require(gerber-to-svg);
var svgString = gerberToSvg(gerberString);
```
Where `gerberString` is the gerber file (e.g. from fs.readFile encoded with UTF-8 or FileReader.readAsText).

## what you get
Not a whole lot, for now. This converter uses RS-274X and strives to be true to the [latest format specification](http://www.ucamco.com/files/downloads/file/81/the_gerber_file_format_specification.pdf?d69271f6602e26ab2474ad625fe40c97). Most all of the Gerber file features are there.

The returned SVG is going to be black, but you can specify `color` either in the XML or with CSS to change it.

## things to watch out for
Step and repeat is very much a work in progress. If your Gerber file is only one polarity (i.e %LPC*% doesn't appear anywhere in your file), you should be fine. But otherwise, don't trust whatever it returns (if it doesn't throw).

Arcs should work, but they've tended to give me trouble. If you see something circular and weird, that could be why.

## if it messes up
Open up an issue and attach your Gerber, if you can. I appreciate files to test on.
