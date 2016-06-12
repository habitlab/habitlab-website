(function(){
  var fs, os, path, ref$, exec, which, i$, len$, command;
  fs = require('fs');
  os = require('os');
  path = require('path');
  ref$ = require('shelljs'), exec = ref$.exec, which = ref$.which;
  for (i$ = 0, len$ = (ref$ = ['gulp', 'node-dev']).length; i$ < len$; ++i$) {
    command = ref$[i$];
    if (!which(command)) {
      console.log("missing " + command + " command. please run the following command:");
      console.log("npm install -g " + command);
      process.exit();
    }
  }
  exec('gulp', {
    async: true
  });
  exec('node-dev app.ls', {
    async: true
  });
}).call(this);
