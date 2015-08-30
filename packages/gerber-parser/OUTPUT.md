# gerber parser output

The gerber parser will emit a stream of plotter command objects. Objects are of the format:

``` javascript
{
  cmd: CMD,
  line: GERBER_LINE_NO,
  key: KEY,
  val: VAL
}
```

## done objects

Special objects that indicates the end of a Gerber file.

``` javascript
{cmd: 'done'}
```

## set objects

These are used to set the state of the plotter.

``` javascript
{
  cmd: 'set',
  line: GERBER_LINE_NO,
  key: KEY,
  val: VAL
}
```

 key           | val                 | description
---------------|---------------------|----------------------------------------
 `mode`        | `i`, `cw`, or `ccw` | linear, CW-arc, or CCW-arc draw mode
 `arc`         | `s`, `m`            | single or multi-quadrant arc mode
 `region`      | `true` or `false`   | region mode on or off
 `units`       | `mm` or `in`        | units
 `backupUnits` | `mm` or `in`        | backup units (used if units missing)
 `epsilon`     | `[Number]`          | threshold for comparing two coordinates
 `nota`        | `A` or `I`          | absolute or incremental coord notation
 `tool`        | `[Integer string]`  | currently used tool code
