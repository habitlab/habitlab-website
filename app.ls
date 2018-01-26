process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

require('app-module-path').addPath(__dirname)

require! {
  levn
  getsecret
  #bluebird
}

#fs = bluebird.promisifyAll(require('fs'))

roles_list = ['logging', 'viewdata']
if getsecret('roles')?
  roles_list = levn.parse '[String]', getsecret('roles')
roles = {}
for role in roles_list
  roles[role] = true

if roles.debug?
  require('libs/globals').enable_globals()
else
  require('libs/globals').disable_globals()

{
  kapp
  prelude
  app
  auth
  get_mongo_db
  get_collection
  get_signups
  get_secrets
  get_logging_states
  get_installs
  get_uninstalls
  get_uninstall_feedback
  list_collections
  list_log_collections_for_user
  list_intervention_collections_for_user
  list_log_collections_for_logname
  get_collection_for_user_and_logname
  get_user_active_dates
  need_query_property
  need_query_properties
  expose_get_auth
} = require 'libs/server_common'

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


if roles.debug?
  do ->
    console.log 'go to chrome://inspect to debug'
    # https://medium.com/@paul_irish/debugging-node-js-nightlies-with-chrome-devtools-7c4a1b95ae27
    for k,v of require('libs/globals').get_globals()
      global[k] = v
    global.printcb = (err, x) ->
      console.log err
      if x?
        console.log(x)
    setInterval ->
      # seems to be necessary so that async calls resolve in the inspector
    , 100

kapp.use(app.routes())
kapp.use(app.allowedMethods())

if roles.viewdata?
  kapp.use(require('koa-static')(__dirname + '/www'))

port = process.env.PORT ? 5000
kapp.listen(port)
console.log "listening to port #{port} visit http://localhost:#{port}"

