process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

require! {
  'koa'
  'koa-static'
  'koa-router'
  'koa-logger'
  'koa-bodyparser'
  'koa-jsonp'
  'monk'
}

kapp = koa()
kapp.use(koa-jsonp())
kapp.use(koa-logger())
kapp.use(koa-bodyparser())
app = koa-router()

{cfy, cfy_node, yfy_node} = require 'cfy'

mongourl = process.env.MONGODB_URI ? 'mongodb://localhost:27017/default'
{MongoClient} = require 'mongodb'
db = monk(mongourl)
signups = db.get 'signups'

get_native_db = cfy ->*
  yield -> MongoClient.connect mongourl, it

list_collections = cfy ->*
  ndb = yield get_native_db()
  collections_list = yield -> ndb.listCollections().toArray(it)
  return collections_list.map (.name)

list_intervention_log_collections_for_user = cfy (userid) ->*
  all_collections = list_collections()
  return all_collections.filter -> it.startsWith("interventionlog_#{userid}_")

list_intervention_log_collections_for_intervention = cfy (intervention) ->*
  all_collections = list_collections()
  return all_collections.filter -> it.startsWith("interventionlog_") and it.endsWith("_#{intervention_name}")

get_intervention_logs_for_user = (userid, intervention_name) ->
  return db.get "interventionlogs_#{userid}_#{intervention_name}"

app.get '/addsignup', ->*
  this.type = 'json'
  {email} = this.request.query
  if not email?
    this.body = JSON.stringify {response: 'error', error: 'need parameter email'}
    return
  result = yield signups.insert(this.request.query)
  this.body = JSON.stringify {response: 'done', success: true}

app.post '/addsignup', ->*
  this.type = 'json'
  {email} = this.request.body
  if not email?
    this.body = JSON.stringify {response: 'error', error: 'need parameter email'}
    return
  result = yield signups.insert(this.request.body)
  this.body = JSON.stringify {response: 'success', success: true}

app.get '/getsignups', ->*
  this.type = 'json'
  all_results = yield signups.find({})
  this.body = JSON.stringify([x.email for x in all_results])

app.get '/get_logs_for_user', ->*
  this.type = 'json'
  {userid} = this.request.body
  if not userid?
    this.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  user_collections = yield list_intervention_log_collections_for_user(userid)
  this.body = JSON.stringify user_collections

app.get '/listcollections', ->*
  this.type = 'json'
  this.body = JSON.stringify yield list_collections()

app.post '/add_intervention_log', ->*
  this.type = 'json'
  {userid, intervention} = this.request.body
  if not userid?
    this.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  if not intervention?
    this.body = JSON.stringify {response: 'error', error: 'need parameter intervention'}
    return
  this.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  #this.body = JSON.stringify {response: 'success', success: true}

kapp.use(app.routes())
kapp.use(app.allowedMethods())
kapp.use(koa-static(__dirname + '/www'))
port = process.env.PORT ? 5000
kapp.listen(port)
console.log "listening to port #{port} visit http://localhost:#{port}"
