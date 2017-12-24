# gerber parser

A printed circuit board Gerber and drill file parser. Implemented as a Node transform stream that takes a Gerber text stream and emits objects to be consumed by some sort of PCB plotter.

## how to

`$ npm install gerber-parser`

``` javascript
var fs = require('fs')
var gerberParser = require('gerber-parser')

var parser = gerberParser()
parser.on('warning', function(w) {
  console.warn('warning at line ' + w.line + ': ' + w.message)
})

fs.createReadStream('/path/to/gerber/file.gbr')
  .pipe(parser)
  .on('data', function(obj) {
    console.log(JSON.stringify(obj))
  })
```

To run in the browser, this module should be bundled with a tool like [browserify](http://browserify.org/) or [webpack](http://webpack.github.io/).

## api

See [API.md](./API.md)
