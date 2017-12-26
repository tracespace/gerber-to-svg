# what's that gerber?

> Identify the probable PCB layer type of a Gerber or drill file by filename

## install

```shell
npm install --save whats-that-gerber
```

## usage

``` javascript
var whatsThatGerber = require('whats-that-gerber')

var filename = 'my-board-F_Cu.gbr'
var layerType = whatsThatGerber(filename)              // 'tcu'
var layerName = whatsThatGerber.getFullName(layerType) // 'top copper'
```

### layer types and names

There are 12 available layer types. You can get an array of all types with:

``` javascript
var whatsThatGerber = require('whats-that-gerber')
var allLayerTypes = whatsThatGerber.getAllTypes() // ['drw', 'tcu', ...]
```

 type | full name (en)
----- | -------------------
 drw  | gerber drawing
 tcu  | top copper
 tsm  | top soldermask
 tss  | top silkscreen
 tsp  | top solderpaste
 bcu  | bottom copper
 bsm  | bottom soldermask
 bss  | bottom silkscreen
 bsp  | bottom solderpaste
 icu  | inner copper
 out  | board outline
 drl  | drill hits

#### checking if a layer type is valid

You can check if any given string is a valid layer type with:

``` js
var whatsThatGerber = require('whats-that-gerber')
var isValidType = whatsThatGerber.isValidType

var type1 = 'tsm'
var type2 = 'hello'

console.log(isValidType(type1)) // true
console.log(isValidType(type2)) // false
```

### full name locales

The full name method takes a locale string as its second parameter, which defaults to 'en':

``` javascript
var fullName = whatsThatGerber.getFullName('tcu', 'en')
```

Currently, no other locales are supported (because I don't know any!); contributions are greatly appreciated. If the type or locale is unrecognized, the result will be an empty string. Locale additions will be considered patch-level upgrades.

### supported cad programs

We should be able to identify files output by the following programs:

*   KiCad
*   Eagle
*   Altium
*   Orcad
*   gEDA PCB

## contributing

If adding / modifying a filetype matcher, please remember to add / modify an example filename in [test/filenames-by-cad.json](test/filenames-by-cad.json).
