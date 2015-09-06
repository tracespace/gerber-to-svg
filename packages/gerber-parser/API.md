# gerber parser api
API documentation for gerber-parser. An understanding of the [Gerber file format specification](http://www.ucamco.com/en/guest/downloads) will help with understanding the parser API.

## create a gerber parser
``` javascript
const gerberParser = require('gerber-parser')
const parser = gerberParser(OPTIONS)
```

### usage
Use the gerber parser like you would any other [Node stream](https://github.com/substack/stream-handbook).

### options
The gerberParser function takes an options object and returns a transform stream. The options object can be used to override or certain details that would normally be parsed from the Gerber file or may be missing from the file entirely (which can happen a lot, especially with drill files).

``` javascript
const options = {
  places: [3, 5],
  zero: 'L',
  filetype: 'gerber'
}
const parser = gerberParser(options)
```

The available options are:

key      | value               | description
---------|---------------------|-------------
places   | [int, int]          | Coordinate places before / after the decimal
zero     | 'L' or 'T'          | Leading or trailing zero suppression
filetype | 'gerber' or 'drill' | Type of file

## public properties

A gerber parser has certain public properties. Any properties not listed here as public could be changed at any time.

### format

The format object `gerber.format` can be used once parsing has finished to determine any formatting decisions the parser made. Specifically, coordinate places format, zero suppression format, and filetype.

``` javascript
parser.on('end', function() {
  console.log(parser.format)
})
// could print:
// {
//   places: [2, 4],
//   zero: 'L',
//   filetype: 'gerber'
// }
```

### line

`parser.line` indicates the current line of the gerber file that the parser is processing at any given moment. After parsing is done, it will indicate one less than the number of lines the file contained (`parser.line` starts at 0).

## events

Because the gerber parser is a Node stream, it is also an event emitter. In addition to the standard stream events, it will also emit certain other events.

### warning event

A `warning` event is emitted if the parser encounters a recoverable problem while parsing the file. Typically, these warning are caused by elements that are deprecated in the current Gerber specification or missing information that will be replaced with assumptions by the parser.

``` javascript
// warning object
const exampleWarning = {message: 'warning message', line: LINE_NO_IN_GERBER}

parser.on('warning', function(w) {
  console.warn(`warning at line ${w.line}: ${w.message}`)
})
```

## transform stream objects
Given a gerber or drill file stream, the parser will emit a stream of plotter command objects. Objects are of the format:

``` javascript
{
  cmd: CMD,
  line: GERBER_LINE_NO,
  key: KEY,
  val: VAL
}
```

### done objects

Special objects that indicate the end of a Gerber file.

``` javascript
{
  cmd: 'done',
  line: GERBER_LINE_NO
}
```

### set objects

Commands used to set the state of the plotter.

``` javascript
{
  cmd: 'set',
  line: GERBER_LINE_NO,
  key: KEY,
  val: VAL
}
```

key           | val                 | description
--------------|---------------------|----------------------------------------
`mode`        | `i`, `cw`, or `ccw` | linear, CW-arc, or CCW-arc draw mode
`arc`         | `s` or `m`          | single or multi-quadrant arc mode
`region`      | `true` or `false`   | region mode on or off
`units`       | `mm` or `in`        | units
`backupUnits` | `mm` or `in`        | backup units (used if units missing)
`epsilon`     | `[Number]`          | threshold for comparing two coordinates
`nota`        | `A` or `I`          | absolute or incremental coord notation
`tool`        | `[Integer string]`  | currently used tool code

### operation objects

Commands used to move the plotter location and create image objects

``` javascript
{
  cmd: 'op',
  line: GERBER_LINE_NO,
  key: OP_TYPE,
  val: COORDINATE
}
```

where `COORDINATE` is an object of format `{x: _, y: _, i: _, j: _}` and OP_TYPE is the type of operation:

operation | description
----------|-------------------------------------------------------------------
`int`     | interpolate (draw) to `COORDINATE` based on current tool and mode
`move`    | move to `COORDINATE` without affecting the image
`flash`   | add image of current tool to the layer image at `COORDINATE`
`last`    | do whatever the last operation was (deprectated)

### level objects

Commands used to create new polarity or step-repeat image levels.

``` javascript
{
  cmd: 'level',
  line: GERBER_LINE_NO,
  key: LEVEL_TYPE,
  val: VAL
}
```

level type | val                        | description
-----------|----------------------------|------------------------------------
`polarity` | `C` or `D`                 | Clear or Dark image polarity
`stepRep`  | `{x: _, y: _, i: _, j: _}` | Steps in x and y at offsets i and j

### tool objects

Commands used to create new tools.

``` javascript
{
  cmd: 'tool',
  line: GERBER_LINE_NO,
  key: TOOL_CODE,
  val: TOOL_OBJECT
}
```

where `TOOL_CODE` is the unique tool identifier in string format and `TOOL_OBJECT` is of the format:

``` javascript
{
  shape: SHAPE,
  val: SHAPE_PARAMS_ARRAY,
  hole: HOLE_PARAMS_ARRAY
}
```

#### shapes and parameters

There are five types of shapes available

shape        | parameters
-------------|------------------------------------
`circle`     | `[DIA]`
`rect`       | `[WIDTH, HEIGHT]`
`obround`    | `[WIDTH, HEIGHT]`
`poly`       | `[DIA, N_POINTS, ROTATION_IN_DEG]`
`MACRO_NAME` | `[$1, $2, ..., $N]`

#### holes

Standard tools (i.e. not macros) may have a hole in the middle. The hole, if it exists, may be a circle or a rectangle (though rectangle holes are deprecated by the latest Gerber file specification).

hole type      | hole array        
---------------|-------------------
No hole        | `[]`              
Circle hole    | `[DIA]`        
Rectangle hole | `[WIDTH, HEIGHT]`

### macro objects

Commands used to create new tool macros.

``` javascript
{
  cmd: 'macro',
  line: GERBER_LINE_NO,
  key: MACRO_NAME,
  val: MACRO_BLOCKS_ARRAY
}
```

Where `MACRO_NAME` is the name of the macro being defined and `MACRO_BLOCKS_ARRAY` is an array of macro block objects.

#### macro blocks

A tool macro is composed of blocks. A macro block object has a `type` key that indicates the type of block.

##### variable set block

A variable set block contains a function that takes the current set of macro modifiers (variables) and returns a new, modified set to use.

``` javascript
{type: 'variable', set: (mods) => mods}
```

##### primitive blocks

A primitive adjusts the macro image. All primitive objects have an exposure key `exp` that will be `0` if the primitive erases the existing image or `1` if it adds to the existing image. Most primitive objects have a rotation in degrees key `rot` that will rotate the primitive around the macro image's origin.

All values in a primitive object will either be a `Number` or a function that takes the current modifier map and returns a number `(mods) => Number`

A **comment primitive** does nothing:

``` javascript
{type: 'commment'}
```

A **circle primitive** adds a circle to the macro image:

``` javascript
{type: 'circle', exp, dia, cx, cy}
```

A **vector primitive** adds a stroke with `width` and endpoints (`x1`, `y1`) and (`x2`, `y2`):

``` javascript
{type: 'vect', exp, width, x1, y1, x2, y2, rot}
```

A **rectangle primitive** adds a rectangle with `width` and `height` centered at (`x`, `y`):

``` javascript
{type: 'rect', exp, width, height, x, y, rot}
```

A **lower-left rectangle primitive** adds a rectangle with `width` and `height` with its lower left point at at (`x`, `y`):

``` javascript
{type: 'rectLL', exp, width, height, x, y, rot}
```

An **outline primitive** adds an outline polygon described by a `points` array of format `[x1, y1, x2, y2, ..., xN, yN]`:

``` javascript
{type: 'outline', exp, points, rot}
```

An **polygon primitive** adds a regular polygon with circumcircle diameter `dia`, number of vertices `vertices`, and a center at (`cx`, `cy`):

``` javascript
{type: 'poly', exp, vertices, cx, cy, dia, rot}
```

A **moiré primitive** adds a moiré (target) with center at (`cx`, `cy`), outer diameter `dia`, ring thickness `ringThx`, ring gap `ringGap`, maximum number of rings `maxRings`, crosshair line thickness `crossThx`, and crosshair line length `crossLen`:

``` javascript
{type: 'moire', exp, cx, cy, dia, ringThx, ringGap, maxRings, crossThx, crossLen, rot}
```

A **thermal primitive** adds a thermal with center at (`cx`, `cy`), outer diameter `outerDia`, inner diameter `innerDia`, and ring gap `gap`:

``` javascript
{type: 'thermal', exp, cx, cy, outerDia, innerDia, gap, rot}
```
