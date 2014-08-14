# register the coffee coverage function
require('coffee-coverage').register {
  path: 'relative'
  basePath: require('path').join __dirname, '..'
  exclude: ['test', 'lib', 'dist', 'bin', 'node_modules', '.git']
  initAll: true
}
