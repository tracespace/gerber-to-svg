# gerber plotter api

API documentation for `gerber-plotter`. An understanding of the [Gerber file format specification](http://www.ucamco.com/en/guest/downloads), the [Excellon NC drill format](http://www.excellon.com/manuals/program.htm) (as poorly defined as it is), and the [`gerber-parser` module](https://github.com/mcous/gerber-parser) will help with understanding the plotter API.

## create a gerber plotter

``` javascript
const gerberPlotter = require('gerber-plotter')
const plotter = gerberParser(OPTIONS)
```

### usage

Use the gerber plotter like you would any other [Node stream](https://github.com/substack/stream-handbook).

### options

The gerberPlotter function takes an options object and returns a transform stream. The options object can be used to override or certain details that would normally be set by the incoming command stream or may be missing from the input stream entirely (which can happen a lot, especially with drill files).

``` javascript
const options = {}
const plotter = gerberPlotter(options)
```

The available options are:

key     | value        | description
--------|--------------|---------------------------------------------
`units` | `mm` or `in` | PCB units
`nota`  | `A` or `I`   | Absolute or incremental coordinate notation

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
//   nota: 'A'
// }
```

## events

Because the gerber plotter is a Node stream, it is also an event emitter. In addition to the standard stream events, it can also emit:

### warning events

A `warning` event is emitted if the plotter encounters a recoverable problem while plotting the image. Typically, these warning are caused by elements that are deprecated in the current Gerber specification or missing information that will be replaced with assumptions by the plotter.

``` javascript
// warning object
const exampleWarning = {message: 'warning message', line: LINE_NO_IN_GERBER}

plotter.on('warning', function(w) {
  console.warn(`plotter warning at line ${w.line}: ${w.message}`)
})
```

## transform stream objects

The plotter will emit a stream of PCB image objects. Objects are of the format:

``` javascript
{}
```
