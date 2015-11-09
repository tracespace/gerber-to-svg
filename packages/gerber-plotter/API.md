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
{type: 'shape', tool: TOOL_CODE, shape: [PRIMITIVE_OBJECTS...]}
```

Where `TOOL_CODE` is the unique tool code being used and `PRIMITIVE_OBJECTS` are a collection of simple shapes that make up the pad. A tool shape object doesn't affect the overall image until that tool is used for a flash.

A tool shape has a local origin that is different from the overall image origin. Any coordinates in the shape object array are in reference to that local origin. When a tool shape is flashed, it should be translated to the flash location.

#### primitive shape objects

The primitive shapes array is meant to be reduced to a single symbol by the consumer of the plotter stream. A primitive shape object can be one of the following:

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

A modifier that changes the subsequent shape polarities to `clear` or `dark`. By default, all shapes are `dark`. A dark shape creates an image, while a clear shape erases any shape that lies below it (in that pad). Used for macro-defined tools and standard tools with holes:

``` javascript
{type: 'layer', polarity: 'clear' OR 'dark'}
```

### pad object

A pad object creates a pad with a previously defined shape for `tool`, at a location (`x`, `y`):

``` javascript
{type: 'pad', tool: TOOL_CODE, x: X_COORDINATE, y: Y_COORDINATE}
```

### stroke and fill objects

A stroke object is a series of segments defined by `path` with a stroke-width `width`. `SEGMENTS` are one of two segment objects as defined below. A stroke has round line-ends and round line-joins.

A fill object is a filled in region bounded by `path`. The bounding path does not have a stroke width.

Regardless of the order they appear in the gerber file itself, this library will try to ensure that any segments from a given tool until the region mode is changed will be places adjacently in `path`. For example, if the Gerber file says `MOVE TO (1, 1); LINE TO (2, 1); MOVE TO (2, 2); LINE TO (2, 1)`, the library will convert that to `LINE FROM (1, 1) TO (2, 1); LINE FROM (2, 1) TO (2, 2)`

``` javascript
{type: 'stroke', width: WIDTH, path: [SEGMENTS...]}
{type: 'fill', path: [SEGMENTS...]}
```

#### line segments

A line segment is a path from `start` to `end`

``` javascript
{type: 'line', start: [X0, Y0], end: [X1, Y1]}
```

#### arc segments

A arc segment is a circular arc from `start` to `end` with radius `radius`, center: `center`, direction `dir` (`'cw'` or `'ccw'`), and arc angle `sweep`. All angles are in radians.

``` javascript
{
  type: 'arc',
  start: [X0, Y0, ANGLE0],
  end: [X1, Y1, ANGLE1],
  center: [XC, YC],
  sweep: ARC_ANGLE,
  radius: R,
  dir: DIRECTION
}
```

### layer polarity objects

A layer polarity object changes the polarity of subsequent image objects until the polarity is changed again. A polarity of 'dark' is the default, and adds to the overall image. A polarity of 'clear' subtracts from the overall image. The polarity object also includes `box`: the bounding box of the existing overall image.

``` javascript
{type: 'polarity', polarity: POLARITY, box: [X_MIN, Y_MIN, X_MAX, Y_MAX]}
```

### layer repeat objects

A layer repeat object means all following objects will be repeated at `offsets`. For example, if a circle pad is flashed at (0, 0) and `offsets = [[1, 0], [0, 1], [1, 1]]`, that circle pad should appear at (0, 0), (1, 0), (0, 1), and (1, 1). Like the layer polarity object, the layer repeat object includes the current image's bounding box. The repeat is in effect until another repeat object is pushed. A repeat object with a zero-length `offsets` array means repeating has been turned off.

Note that, according to the Gerber specification, if a clearing image appears in a repeated block and overlaps a previous block, it will clear the image in both blocks.

``` javascript
{type: 'repeat', offsets: [OFFSET_LOCATIONS...], box: [X_MIN, Y_MIN, X_MAX, Y_MAX]}
```

### end of stream

At the end of the stream, the plotter will push out one last object. This object of type `size` contains the size and the units of the overall image.

A box of `[Infinity, Infinity, -Infinity, -Infinity]` means there is no image.

``` javascript
{type: 'size', box: [X_MIN, Y_MIN, X_MAX, Y_MAX], units: UNITS}
```
