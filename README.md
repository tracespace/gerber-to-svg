# tracespace

![Version][version-badge]
[![Build Status][build-badge]][build]
[![Code Coverage][coverage-badge]][coverage]
[![Code Style][code-style-badge]][code-style]

> PCB visualization tools for Node.js and the browser

tracespace is an open-source collection of tools to make looking at circuit boards on the internet easier.

## tools

*   [tracespace viewer][viewer] - Online PCB viewer powered by `pcb-stackup`
*   [pcb-stackup][] - Generate SVG renders of full PCBs
*   [pcb-stackup-core][] - Core PCB building logic for `pcb-stackup`
*   [gerber-to-svg][] - Generate SVG renders of individual Gerber and drill files
*   [gerber-parser][] - Streaming Gerber/drill file parser
*   [gerber-plotter][] - Streaming layer image plotter (consumer of `gerber-parser`)
*   [whats-that-gerber][] - Identify layer types of Gerber/drill filenames

## contributing

We'd could use your help maintaining and growing the tracespace ecosystem! Issues and pull requests are greatly appreciated.

### development setup

Most of the tracespace tools live here in this [monorepo][]. We use [lerna][] to manage this setup.

Node v8 (lts/carbon) and npm v5 are recommended.

```shell
# clone repository
git clone git@github.com:tracespace/tracespace.git
cd tracespace

# install dependencies and link packages
# postinstall script runs `lerna boostrap`
npm install
npm test
```

### tests

```shell
# run unit tests tests with coverage and linting
npm test

# run unit tests in watch mode (no coverage, no linting)
npm run test:watch

# visual integration test servers to manually verify renders in a browser
npm run integration

# simple benchmarks for gerber-parser and gerber-plotter
# records time to parse and plot real-world files
npm run bench
```

### ci

The [CI server][build] runs unit tests on:

*   Node.js v4
*   Node.js v6
*   Node.js v8
*   Node.js latest

[viewer]: http://viewer.tracespace.io
[pcb-stackup]: https://github.com/tracespace/pcb-stackup
[gerber-to-svg]: ./packages/gerber-to-svg
[pcb-stackup-core]: ./packages/pcb-stackup-core
[gerber-parser]: ./packages/gerber-parser
[gerber-plotter]: ./packages/gerber-plotter
[whats-that-gerber]: ./packages/whats-that-gerber

[monorepo]: https://github.com/babel/babel/blob/master/doc/design/monorepo.md
[lerna]: https://lernajs.io/

[version-badge]: https://img.shields.io/badge/dynamic/json.svg?style=flat-square&label=version&colorB=00bfff&query=$.version&uri=https%3A%2F%2Fraw.githubusercontent.com%2Ftracespace%2Fgerber-to-svg%2Fnext%2Flerna.json

[build]: https://travis-ci.org/tracespace/gerber-to-svg/branches
[build-badge]: http://img.shields.io/travis/tracespace/gerber-to-svg/next.svg?style=flat-square

[coverage]: https://codecov.io/gh/tracespace/gerber-to-svg/branches
[coverage-badge]: https://img.shields.io/codecov/c/github/tracespace/gerber-to-svg/next.svg?style=flat-square

[code-style]: https://standardjs.com
[code-style-badge]: https://img.shields.io/badge/code_style-standard-brightgreen.svg?style=flat-square
