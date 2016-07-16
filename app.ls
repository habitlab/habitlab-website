process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

require! {
  'koa'
  'koa-static'
  'koa-router'
  'koa-logger'
  'koa-bodyparser'
}

kapp = koa()
kapp.use(koa-logger())
kapp.use(koa-bodyparser())
app = koa-router()


{MongoClient} = require 'mongodb'
{cfy, cfy_node, yfy_node} = require 'cfy'

get_db = cfy ->*
  mongourl = process.env.MONGODB_URI ? 'mongodb://localhost:27017/default'
  db = yield -> MongoClient.connect mongourl, it
  return db

get_signups_collection = cfy ->*
  db = yield get_db()
  return db.collection('signups')

app.get '/addsignup', ->*
  {email} = this.request.query
  if not email?
    this.body = 'need email parameter'
    return
  signups = yield get_signups_collection()
  result = yield -> signups.insertOne(this.request.query, {}, it)
  this.body = 'done adding ' + email

app.post '/addsignup', ->*
  {email} = this.request.body
  if not email?
    this.body = 'need email parameter'
    return
  signups = yield get_signups_collection()
  result = yield -> signups.insertOne(this.request.body, {}, it)
  this.body = 'done adding ' + email

app.get '/getsignups', ->*
  signups = yield get_signups_collection()
  all_results = yield -> signups.find({}).toArray(it)
  this.body = JSON.stringify([x.email for x in all_results])

app.get '/addlog', ->*
  this.body = 'addtolog called'

kapp.use(app.routes())
kapp.use(app.allowedMethods())
kapp.use(koa-static(__dirname + '/www'))
port = process.env.PORT ? 5000
kapp.listen(port)
console.log "listening to port #{port} visit http://localhost:#{port}"