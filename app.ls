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

list_log_collections_for_user = cfy (userid) ->*
  all_collections = yield list_collections()
  return all_collections.filter -> it.startsWith("#{userid}_")

list_log_collections_for_logname = cfy (logname) ->*
  all_collections = yield list_collections()
  return all_collections.filter -> it.endsWith("_#{logname}")

get_collection_for_user_and_logname = (userid, logname) ->
  return db.get "#{userid}_#{logname}"

app.get '/addsignup', ->*
  this.type = 'json'
  {email} = this.request.query
  if not email?
    this.body = JSON.stringify {response: 'error', error: 'need parameter email'}
    return
  result = yield signups.insert(this.request.query)
  this.body = JSON.stringify {response: 'done', success: true}

app.get '/hello' ->*
  users = []
  collections = yield list_collections()
  for entry in collections
    if entry.indexOf("logs/interventions") !== -1 #filter to check if data gotten today
      #see if intervention latest timestamp was today
      collection = db.get entry
      timestamp = yield collection.find().limit(1).sort({$natural:-1})
      users.push timestamp
    this.body = JSON.stringify users
    
  return

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

app.get '/list_logs_for_user', ->*
  this.type = 'json'
  {userid} = this.request.query
  if not userid?
    this.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  user_collections = yield list_log_collections_for_user(userid)
  this.body = JSON.stringify user_collections

app.get '/list_logs_for_logname', ->*
  this.type = 'json'
  {logname} = this.request.query
  if not logname?
    this.body = JSON.stringify {response: 'error', error: 'need parameter logname'}
    return
  user_collections = yield list_log_collections_for_logname(logname)
  this.body = JSON.stringify user_collections

app.get '/printcollection', ->*
  {collection, userid, logname} = this.request.query
  if userid? and logname?
    collection = "#{userid}_#{logname}"
  if not collection?
    this.body = JSON.stringify {response: 'error', error: 'need paramter collection'}
  collection_name = collection
  collection = db.get collection_name
  items = yield collection.find({})
  this.body = JSON.stringify items

app.get '/listcollections', ->*
  this.type = 'json'
  this.body = JSON.stringify yield list_collections()

app.post '/sync_collection_item', ->*
  this.type = 'json'
  {userid, collection} = this.request.body
  collection_name = collection
  if not userid?
    this.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  if not collection_name?
    this.body = JSON.stringify {response: 'error', error: 'need parameter collection'}
    return
  collection = get_collection_for_user_and_logname(userid, 'synced/' + collection_name)
  yield collection.insert this.request.body
  #this.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  this.body = JSON.stringify {response: 'success', success: true}

app.post '/addtolog', ->*
  this.type = 'json'
  {userid, logname, itemid} = this.request.body
  if not userid?
    this.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  if not logname?
    this.body = JSON.stringify {response: 'error', error: 'need parameter logname'}
    return
  if not itemid?
    this.body = JSON.stringify {response: 'error', error: 'need parameter itemid'}
    return
  if itemid.length != 24
    this.body = JSON.stringify {response: 'error', error: 'itemid length needs to be 24'}
    return
  collection = get_collection_for_user_and_logname(userid, logname)
  this.request.body._id = monk.id itemid
  yield collection.insert this.request.body
  #this.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  this.body = JSON.stringify {response: 'success', success: true}

kapp.use(app.routes())
kapp.use(app.allowedMethods())
kapp.use(koa-static(__dirname + '/www'))
port = process.env.PORT ? 5000
kapp.listen(port)
console.log "listening to port #{port} visit http://localhost:#{port}"
