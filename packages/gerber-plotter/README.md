# gerber plotter

A printed circuit board Gerber and drill file plotter. Implemented as a Node transform stream that consumes plotter command objects (for example, those output by [mcous/gerber-parser](https://github.com/mcous/gerber-parser)) and outputs PCB image objects.

## how to

`$ npm install gerber-plotter`

``` javascript
var fs = require('fs')
var gerberParser = require('gerber-parser')
var gerberPlotter = require('gerber-plotter')

var parser = gerberParser()
var plotter = gerberPlotter()

plotter.on('warning', function(w) {
  console.warn('plotter warning at line ' + w.line + ': ' + w.message)
})

plotter.once('error', function(e) {
  console.error('plotter error: ' + e.message)
})

fs.createReadStream('/path/to/gerber/file.gbr', {encoding: 'utf8'})
  .pipe(parser)
  .pipe(plotter)
  .on('data', function(obj) {
    console.log(JSON.stringify(obj))
  })
```

To run in this module in the browser, it should be bundled with a tool like [browserify](http://browserify.org/) or [webpack](http://webpack.github.io/).

## api

See [API.md](./API.md)
