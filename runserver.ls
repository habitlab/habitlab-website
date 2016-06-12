require! {
  fs
  os
  path
}

{exec, which} = require 'shelljs'

for command in ['gulp', 'node-dev'] # 'pouchdb-server'
  if not which command
    console.log "missing #{command} command. please run the following command:"
    console.log "npm install -g #{command}"
    process.exit()

exec 'gulp', {async: true}
exec 'node-dev app.ls', {async: true}
