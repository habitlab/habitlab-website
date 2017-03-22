process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

{
  kapp
  app
} = require './server_common'

require! {
  levn
  getsecret
}

roles_list = ['logging', 'viewdata']
if getsecret('roles')?
  roles_list = levn.parse '[String]', getsecret('roles')
roles = {}
for role in roles_list
  roles[role] = true

app.use (next) ->*
  ip_addr = this.request.headers["x-forwarded-for"]
  if ip_addr
    list = ip_addr.split(",")
    ip_addr = list[list.length-1]
  else
    ip_addr = this.request.ip
  this.request.ip_address_fixed = ip_addr
  yield next

if roles.https?
  app.use(require('koa-sslify')({trustProtoHeader: true}))

require('./common_routes')
if roles.logging?
  require('./logging_routes')
if roles.viewdata?
  require('./viewdata_routes')

kapp.use(app.routes())
kapp.use(app.allowedMethods())

require! {
  'koa-static'
}

kapp.use(koa-static(__dirname + '/www'))
port = process.env.PORT ? 5000
kapp.listen(port)
console.log "listening to port #{port} visit http://localhost:#{port}"
