(function(){
  var fs, os, path, getsecret, ref$, exec, which, i$, len$, command;
  fs = require('fs');
  os = require('os');
  path = require('path');
  getsecret = require('getsecret');
  ref$ = require('shelljs'), exec = ref$.exec, which = ref$.which;
  for (i$ = 0, len$ = (ref$ = ['gulp', 'node-dev', 'mongosrv']).length; i$ < len$; ++i$) {
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
  if (getsecret('MONGODB_URI') == null) {
    exec('mongosrv', {
      async: true
    });
  }
  exec('node-dev app.js', {
    async: true
  });
}).call(this);
