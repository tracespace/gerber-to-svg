// test suite for gerber-to-svg
'use strict'

var events = require('events')
var sinon = require('sinon')
var chai = require('chai')
var sinonChai = require('sinon-chai')
var proxyquire = require('proxyquire')
var assign = require('lodash.assign')
var values = require('lodash.values')

var expect = chai.expect
chai.use(sinonChai)

var fakeParser = new events.EventEmitter()
assign(fakeParser, {
  pipe: sinon.stub().returnsArg(0),
  write: sinon.spy(),
  end: sinon.spy()
})
var fakePlotter = new events.EventEmitter()
assign(fakePlotter, {
  pipe: sinon.stub().returnsArg(0),
  write: sinon.spy()
})
var fakeConverter = new events.EventEmitter()
assign(fakeConverter, {
  pipe: sinon.stub().returnsArg(0),
  write: sinon.spy()
})

var parserStub = sinon.stub()
var plotterStub = sinon.stub()
var converterStub = sinon.stub()
var gerberToSvg = proxyquire('../lib/gerber-to-svg', {
  'gerber-parser': parserStub,
  'gerber-plotter': plotterStub,
  './plotter-to-svg': converterStub
})

describe('gerber to svg', function() {
  beforeEach(function() {
    parserStub.reset()
    plotterStub.reset()
    converterStub.reset()

    // console.log(fakeParser)
    values(fakeParser)
      .filter(function(spy) {
        return ((spy != null) && (spy.reset != null))
      })
      .forEach(function(spy) {
        spy.reset()
      })

    values(fakePlotter)
      .filter(function(spy) {
        return ((spy != null) && (spy.reset != null))
      })
      .forEach(function(spy) {
        spy.reset()
      })

    values(fakeConverter)
      .filter(function(spy) {
        return ((spy != null) && (spy.reset != null))
      })
      .forEach(function(spy) {
        spy.reset()
      })

    parserStub.returns(fakeParser)
    plotterStub.returns(fakePlotter)
    converterStub.returns(fakeConverter)
  })

  afterEach(function() {
    fakeParser.removeAllListeners()
    fakePlotter.removeAllListeners()
    fakeConverter.removeAllListeners()
  })

  it('should return a the converter transform stream', function() {
    var converter1 = gerberToSvg('', 'test-id')
    expect(converter1).to.equal(fakeConverter)
    var converter2 = gerberToSvg('', 'test-id', function() {})
    expect(converter2).to.equal(fakeConverter)

    expect(converterStub).to.have.been.always.calledWithNew
    expect(converterStub).to.have.been.calledTwice
  })

  it('should pipe a stream input into the parser', function() {
    var input = {pipe: sinon.spy(), setEncoding: sinon.spy()}
    gerberToSvg(input, 'test-id')

    expect(input.pipe).to.have.been.calledWith(fakeParser)
    expect(fakeParser.pipe).to.have.been.calledWith(fakePlotter)
    expect(fakePlotter.pipe).to.have.been.calledWith(fakeConverter)
    expect(input.setEncoding).to.have.been.calledWith('utf8')
  })

  it('should write string input into the parser', function(done) {
    var input = 'G04 empty gerber*\nM02*\n'
    gerberToSvg(input, 'test-id')

    setTimeout(function() {
      expect(fakeParser.write).to.have.been.calledWith(input)
      expect(fakeParser.end).to.have.been.calledOnce
      done()
    }, 10)
  })

  it('should pass the id to plotter-to-svg when it is a string', function() {
    gerberToSvg('', 'foo')
    expect(converterStub).to.have.been.calledWith('foo')
  })

  it('should pass the id in an object', function() {
    gerberToSvg('', {id: 'bar'})
    expect(converterStub).to.have.been.calledWith('bar')
  })

  it('should throw an error if id is missing', function() {
    expect(function() {gerberToSvg('', {})}).to.throw(/id required/)
  })

  it('should pass the class option', function() {
    gerberToSvg('', {id: 'foo', class: 'bar'})
    expect(converterStub).to.have.been.calledWith('foo', 'bar')
  })

  it('should pass the color option', function() {
    gerberToSvg('', {id: 'foo', color: 'red'})
    expect(converterStub).to.have.been.calledWith('foo', '', 'red')
  })

  describe('passing along warnings', function() {
    it('should emit warnings from the parser', function(done) {
      var converter = gerberToSvg('foobar*\n', 'foobar')
      var warning = {}

      converter.once('warning', function(w) {
        expect(w).to.equal(warning)
        done()
      })
      fakeParser.emit('warning', warning)
    })

    it('should emit warnings from the plotter', function(done) {
      var converter = gerberToSvg('foobar*\n', 'foobar')
      var warning = {}

      converter.once('warning', function(w) {
        expect(w).to.equal(warning)
        done()
      })
      fakePlotter.emit('warning', warning)
    })
  })

  describe('passing along errors', function() {
    it('should emit errors from the parser', function(done) {
      var converter = gerberToSvg('foobar*\n', 'foobar')
      var error = {}

      converter.once('error', function(e) {
        expect(e).to.equal(error)
        done()
      })
      fakeParser.emit('error', error)
    })

    it('should emit errors from the plotter', function(done) {
      var converter = gerberToSvg('foobar*\n', 'foobar')
      var error = {}

      converter.once('error', function(e) {
        expect(e).to.equal(error)
        done()
      })
      fakePlotter.emit('error', error)
    })
  })

  it('should take the filetype format from the parser', function() {
    var parser = new events.EventEmitter
    assign(parser, fakeParser, {format: {filetype: 'foobar'}})
    parserStub.returns(parser)

    var converter = gerberToSvg('G04 a gerber file*\n', 'gbr')
    expect(converter.filetype).to.be.falsey

    parser.emit('end')
    expect(converter.filetype).to.equal('foobar')
  })
})
