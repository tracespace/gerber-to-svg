(function() {
  var generateUniqueId, id;

  id = 1000;

  generateUniqueId = function() {
    return id++;
  };

  module.exports = generateUniqueId;

}).call(this);
