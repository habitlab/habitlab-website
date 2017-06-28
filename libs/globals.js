var myglobals = {}
var globals_enabled = false

module.exports.enable_globals = function() {
  globals_enabled = true
}

module.exports.disable_globals = function() {
  globals_enabled = true
}

module.exports.add_globals = function(dict) {
  if (globals_enabled) {
    for (let key of Object.keys(dict)) {
      myglobals[key] = dict[key]
    }
  }
}

module.exports.get_globals = function() {
  return myglobals
}
