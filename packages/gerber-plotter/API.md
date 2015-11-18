# gerber plotter api

API documentation for `gerber-plotter`. An understanding of the [Gerber file format specification](http://www.ucamco.com/en/guest/downloads), the [Excellon NC drill format](http://www.excellon.com/manuals/program.htm) (as poorly defined as it is), and the [`gerber-parser` module](https://github.com/mcous/gerber-parser) will help with understanding the plotter API.

## create a gerber plotter

``` javascript
var gerberPlotter = require('gerber-plotter')
var plotter = gerberParser(OPTIONS)
```

### usage

Use the gerber plotter like you would any other [Node stream](https://github.com/substack/stream-handbook).

### options

The gerberPlotter function takes an options object and returns a transform stream. The options object can be used to override or certain details that would normally be set by the incoming command stream or may be missing from the input stream entirely (which can happen a lot, especially with drill files).

``` javascript
var options = {}
var plotter = gerberPlotter(options)
```

The available options are:

key           | value        | description
--------------|--------------|---------------------------------------------
`units`       | `mm` or `in` | PCB units
`backupUnits` | `mm` or `in` | Backup units in case units are missing
`nota`        | `A` or `I`   | Absolute or incremental coordinate notation
`backupNota`  | `A` or `I`   | Backup notation in case notation is missing

## public properties

A gerber plotter has certain public properties. Any properties not listed here as public may be changed by a patch.

### format
`plotter.format` is an object containing the units and coordinate notation the plotter used to build the image.

``` javascript
plotter.on('end', function() {
  console.log(plotter.format)
})
// could print:
// {
//   units: 'in',
//   backupUnits: 'in',
//   nota: 'A',
//   backupNota: 'A'
// }
```

## events

Because the gerber plotter is a Node stream, it is also an event emitter. In addition to the standard stream events, it can also emit:

### warning events

A `warning` event is emitted if the plotter encounters a recoverable problem while plotting the image. Typically, these warning are caused by elements that are deprecated in the current Gerber specification or missing information that will be replaced with assumptions by the plotter.

``` javascript
// warning object
var exampleWarning = {message: 'warning message', line: LINE_NO_IN_GERBER}

plotter.on('warning', function(w) {
  console.warn(`plotter warning at line ${w.line}: ${w.message}`)
})
```

## transform stream objects

The plotter will emit a stream of PCB image objects. Objects are of the format:

``` javascript
{type: IMAGE_TYPE, ...}
```

### tool shape objects

When a tool is going to be used to create a pad, the plotter will emit a shape for the tool once before the first flash:

``` javascript
{type: 'shape', tool: TOOL_CODE, shape: [SHAPE_OBJECTS...]}
```

Where `tool` is the unique tool code being used and `shape` is an array of shape objects. A tool shape object doesn't affect the overall image until that tool is used for a flash.

A tool shape has a local origin that is different from the overall image origin. Any coordinates in the shape object array are in reference to that local origin. When a tool shape is flashed, it should be translated to the flash location.

#### pad shape objects

The pad shapes array is meant to be reduced to a single symbol by the consumer of the plotter stream. A pad shape object can be one of the following:

**circle**

A filed-in circle with radius `r` centered at (`cx`, `cy`):

``` javascript
{type: 'circle', r, cx, cy}
```

**rectangle**

A filled-in rectangle with width `width`, height `height`, and corner radius `r` centered at (`cx`, `cy`):

``` javascript
{type: 'rect', width, height, r, cx, cy}
```

**polygon**

A filled-in polygon defined by a series of line-segments connecting `points`:

``` javascript
{type: 'poly', points: [[X0, Y0], [X1, Y1], ..., [XN, YN]]}
```

**ring**

A ring of radius `r` and stroke width `width` centered at (`cx`, `cy`):

``` javascript
{type: 'ring', r, width, cx, cy}
```

**clipped shape**

A special nested structure that takes an array `shape` of rectangles or polygons as defined above and clips them with `clip` (which will be a ring shape as defined above). Used for thermal primitives in macro-defined tools:

``` javascript
{type: 'clip', shape: [RECTS_OR_POLYS...], clip: CLIPPING_RING}
```

**layer polarity change**

A modifier that changes the subsequent shape polarities to `clear` or `dark`. By default, all shapes are `dark`. A dark shape creates an image, while a clear shape erases any shape that lies below it. Used for macro-defined tools and standard tools with holes. The polarity object also includes the current size of the image.

``` javascript
{type: 'layer', polarity: POLARITY, box: [X_MIN, Y_MIN, X_MAX, Y_MAX]}
```

### pad object

A pad object creates a pad with a previously defined shape for `tool`, at a location (`x`, `y`):

``` javascript
{type: 'pad', tool: TOOL_CODE, x: X_COORDINATE, y: Y_COORDINATE}
```
