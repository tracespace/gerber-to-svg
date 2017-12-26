# gerber parser

> Streaming Gerber / NC drill file parser

A printed circuit board Gerber and drill file parser implemented as a Node transform stream. Takes a Gerber text stream and emits objects to be consumed by some sort of PCB plotter, like [gerber-plotter](../gerber-plotter).

## install

```shell
npm install --save gerber-parser
```

`gerber-plotter` is a peer dependency, so you probably want to install it too:

```shell
npm install --save gerber-plotter
```

## example

```js
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
