# gerber-to-svg

> Render Gerber and NC drill files as SVGs in Node and the browser

`gerber-to-svg` is a library and CLI tool for converting [Gerber][gerber] and [NC drill][nc-drill] files (manufacturing files for printed circuit boards) into [SVG][svg] files for the web.

## install

```shell
npm install --save gerber-to-svg
```

## usage

```js
var gerberToSvg = require('gerber-to-svg')
var converter = gerberToSvg(input, options, [callback])
```

See [the API documentation](./API.md) for full details.

### command line

`gerber-to-svg` also ships with a command-line utility.

1.  `npm install -g gerber-to-svg`
2.  `gerber-to-svg [options]  -- gerber_files`

#### options

 switch             | type    | what it does
------------------- | ------- | ------------------------
 `-o, --out`        | string  | specify an output directory
 `-q, --quiet`      | boolean | do not print warnings and messages
 `-p, --pretty`     | int     | indent output with this length tabs (2 if unspecified)
 `-c, --color`      | color   | give the layer this color (defaults to "currentColor")
 `-a, --append-ext` | boolean | append .svg rather than replacing the existing extension
 `-f, --format`     | array\[int] | override coordinate decimal places format with '\[INT,DEC]'
 `-z, --zero`       | string  | override zero suppression with 'L' or 'T'
 `-u, --units`      | string  | set backup units to 'mm' or 'in'
 `-n, --notation`   | boolean | set backup absolute/incremental notation with 'A' or 'I'
 `-z, --optimize-paths` | boolean | rearrange trace paths by to occur in physical order
 `-b, --plot-as-outline` | boolean/number | optimize paths and fill gaps smaller than 0.00011 (or specified number) in layer units
 `-v, --version`    | boolean | display version information
 `-h, --help`       | boolean | display this help text

#### examples:

*   `gerber-to-svg gerber.gbr` - convert gerber.gbr and output to stdout
*   `gerber-to-svg -o out gerber.gbr` - convert and output to out/gerber.svg
*   `gerber-to-svg -o out -a gerber.gbr` - output to out/gerber.gbr.svg

## background

Since Gerber is just a vector image format, this library takes in a Gerber file and spits it out in a different vector format, namely SVG. This converter uses RS-274X and strives to be true to the [latest format specification](http://www.ucamco.com/downloads).

Everywhere that is "dark" or "exposed" in the Gerber (think a copper trace or a line on the silkscreen) will be `currentColor` in the SVG. You can set this with the `color` CSS property or the `color` attribute in the SVG node itself.

Everywhere that is "clear" (anywhere that was never drawn on or was drawn on but cleared later) will be transparent. This is accomplished though judicious use of SVG masks and groups.

The bounding box is carefully calculated as the file is being converted, so the `width` and `height` of the resulting SVG should be nearly (if not exactly) the real world size of the Gerber image. The SVG's `viewBox` is in 1000x Gerber units, so its `min-x` and `min-y` values can be used to align SVGs generated from different board layers.

Excellon / NC drill files do not have a completely clearly defined spec, so drill file parsing is lenient in its attempt to generate an image. It should auto-detect when a drill file has been entered. You may need to override parsing settings (see [API.md](./API.md)) to get drill files to render properly if they do not adhere to certain assumptions. The library must make these assumptions because Excellon does not define commands for certain formatting decisions.

[gerber]: https://en.wikipedia.org/wiki/Gerber_format
[nc-drill]: https://en.wikipedia.org/wiki/Excellon_format
[svg]: https://en.wikipedia.org/wiki/Scalable_Vector_Graphics
