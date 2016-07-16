process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

require! {
  'koa'
  'koa-static'
  'koa-router'
  'koa-logger'
  'koa-bodyparser'
  'monk'
}

kapp = koa()
kapp.use(koa-logger())
kapp.use(koa-bodyparser())
app = koa-router()

{cfy, cfy_node, yfy_node} = require 'cfy'

mongourl = process.env.MONGODB_URI ? 'mongodb://localhost:27017/default'
db = monk(mongourl)
signups = db.get 'signups'

app.get '/addsignup', ->*
  {email} = this.request.query
  if not email?
    this.body = 'need email parameter'
    return
  result = yield signups.insert(this.request.query)
  this.body = 'done adding ' + email

app.post '/addsignup', ->*
  {email} = this.request.body
  if not email?
    this.body = 'need email parameter'
    return
  result = yield signups.insert(this.request.body)
  this.body = 'done adding ' + email

app.get '/getsignups', ->*
  all_results = yield signups.find({})
  this.body = JSON.stringify([x.email for x in all_results])

app.get '/addlog', ->*
  this.body = 'addtolog called'

kapp.use(app.routes())
kapp.use(app.allowedMethods())
kapp.use(koa-static(__dirname + '/www'))
port = process.env.PORT ? 5000
kapp.listen(port)
console.log "listening to port #{port} visit http://localhost:#{port}"