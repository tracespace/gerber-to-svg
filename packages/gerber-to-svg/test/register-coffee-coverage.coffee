# register the coffee coverage function
require('coffee-coverage').register {
  path: 'abbr'
  basePath: require('path').join __dirname, '..'
  exclude: ['test', 'lib', 'dist', 'bin', 'node_modules', '.git']
  initAll: true
}
