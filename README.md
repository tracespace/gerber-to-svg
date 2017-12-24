# tracespace

[![Build Status][build-badge]][build]

> PCB visualization tools for Node.js and the browser

tracespace is an open-source collection of tools to make looking at circuit boards on the internet easier.

## tools

*   [viewer][] - Online PCB viewer powered by `pcb-stackup`
*   [pcb-stackup][] - Generate SVG renders of full PCBs
*   [pcb-stackup-core][] - Core PCB building logic for `pcb-stackup`
*   [gerber-to-svg][] - Generate SVG renders of individual Gerber and NC drill files
*   [gerber-parser][] - Streaming Gerber/NC drill file parser
*   [gerber-plotter][] - Streaming layer image plotter (consumer of `gerber-parser`)

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

[viewer]: http://viewer.tracespace.io
[pcb-stackup]: https://github.com/tracespace/pcb-stackup
[gerber-to-svg]: ./packages/gerber-to-svg
[pcb-stackup-core]: ./packages/pcb-stackup-core
[gerber-parser]: ./packages/gerber-parser
[gerber-plotter]: ./packages/gerber-plotter

[monorepo]: https://github.com/babel/babel/blob/master/doc/design/monorepo.md
[lerna]: https://lernajs.io/

[build]: https://travis-ci.org/mcous/gerber-to-svg/branches
[build-badge]: http://img.shields.io/travis/mcous/gerber-to-svg/next.svg?style=flat-square
