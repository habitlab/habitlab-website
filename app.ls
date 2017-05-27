process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

require('app-module-path').addPath(__dirname)

{
  kapp
  app
  auth
} = require 'libs/server_common'

require! {
  levn
  getsecret
  bluebird
}

fs = bluebird.promisifyAll(require('fs'))

roles_list = ['logging', 'viewdata']
if getsecret('roles')?
  roles_list = levn.parse '[String]', getsecret('roles')
roles = {}
for role in roles_list
  roles[role] = true

app.use (ctx, next) ->>
  ip_addr = ctx.request.headers["x-forwarded-for"]
  if ip_addr
    list = ip_addr.split(",")
    ip_addr = list[list.length-1]
  else
    ip_addr = ctx.request.ip
  ctx.request.ip_address_fixed = ip_addr
  await next()

if roles.https?
  app.use(require('koa-sslify')({trustProtoHeader: true}))

require('routes/common_routes')
if roles.reportbug?
  require('routes/reportbug_routes')
if roles.intervention?
  require('routes/intervention_routes')
if roles.logging?
  require('routes/logging_routes')
if roles.viewdata?
  require('routes/viewdata_routes')
  require('routes/webpage_routes')

kapp.use(app.routes())
kapp.use(app.allowedMethods())

if roles.viewdata?
  app.get '/installs', auth, ->*
    index_contents = yield fs.readFileAsync(__dirname + '/www/installs.html', 'utf-8')
    this.body = index_contents
  kapp.use(require('koa-static')(__dirname + '/www'))

port = process.env.PORT ? 5000
kapp.listen(port)
console.log "listening to port #{port} visit http://localhost:#{port}"
