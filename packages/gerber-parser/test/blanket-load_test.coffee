# this file requires all avaliable modules so blanket includes them in coverage
matchesBlanket = (path) -> path.match /node_modules\/blanket/
runningTestCoverage = Object.keys(require.cache).filter(matchesBlanket).length
if runningTestCoverage
  require('require-dir')("#{__dirname}/../src",{recurse:true, duplicates:true})
