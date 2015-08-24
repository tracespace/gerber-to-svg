# gerber parser
In progress.

A printed circuit board Gerber and drill file parser. Implemented as a Node transform stream that takes a Gerber text stream and emits objects to be consumed by some sort of PCB plotter.

## how to

Built and tested for iojs/Node >= v3.0.0

`$ npm install gerber-parser`

``` javascript
var fs = require('fs')
var GerberParser = require('gerber-parser')

var gerberParser = new GerberParser()
gerberParser.on('warning', function(w) {
  console.warn(w.message)
})

fs.createReadStream('/path/to/gerber/file.gbr', {encoding: 'utf8'})
  .pipe(gerberParser)
  .on('data', function(obj) {
    console.log(obj)
  })
```

## developing and contributing

The code is written in ES2015 to run in "modern" versions of Node and transpiled with Babel and bundled with Browserify to run in the browser. Tests are written in Mocha and run in Node, PhantomJS, and a variety of browsers with Zuul and Sauce Labs. All PRs should be accompanied by unit tests, with ideally one feature / bugfix per PR. There is a pre-commit hook to lint all code and tests.

### build scripts

* `$ npm run bundle` - creates the browser bundle
* `$ npm run lint` - lints code with eslint
* `$ npm run test` - runs Node unit tests
* `$ npm run test-watch` - runs unit tests and re-runs on changes
* `$ npm run browser-test` - runs tests in a local browser
* `$ npm run browser-test-phantom` - runs tests in PhantomJS
* `$ npm run browser-test-sauce` - runs tests in Sauce Labs on multiple browsers
  * Sauce Labs account required
