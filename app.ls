process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

require! {
  'koa'
  'koa-static'
  'koa-router'
  'koa-logger'
  'koa-bodyparser'
  'koa-jsonp'
  'mongodb'
  'getsecret'
  'koa-basic-auth'
}

prelude = require 'prelude-ls'

kapp = koa()
kapp.use(koa-jsonp())
kapp.use(koa-logger())
kapp.use(koa-bodyparser())
app = koa-router()

# custom 401 handling

app.use (next) ->*
  try
    yield next
  catch err
    if 401 == err.status
      this.status = 401
      this.set('WWW-Authenticate', 'Basic')
      this.body = 'Authentication failed'
    else
      throw err

auth = koa-basic-auth({name: getsecret('username'), pass: getsecret('password')})

{cfy, cfy_node, yfy_node} = require 'cfy'

mongourl = process.env.MONGODB_URI ? 'mongodb://localhost:27017/default'

get_mongo_db = cfy ->*
  try
    return yield -> mongodb.MongoClient.connect mongourl, it
  catch err
    console.log 'error getting mongodb'
    console.log err
    return

get_collection = cfy (collection_name) ->*
  db = yield get_mongo_db()
  return [db.collection(collection_name), db]

get_signups = cfy ->*
  return yield get_collection('signups')

get_installs = cfy ->*
  return yield get_collection('installs')

get_uninstalls = cfy ->*
  return yield get_collection('uninstalls')

get_uninstall_feedback = cfy ->*
  return yield get_collection('uninstall_feedback')

list_collections = cfy ->*
  ndb = yield get_mongo_db()
  collections_list = yield -> ndb.listCollections().toArray(it)
  ndb.close()
  return collections_list.map (.name)

list_log_collections_for_user = cfy (userid) ->*
  all_collections = yield list_collections()
  return all_collections.filter -> it.startsWith("#{userid}_")

list_log_collections_for_logname = cfy (logname) ->*
  all_collections = yield list_collections()
  return all_collections.filter -> it.endsWith("_#{logname}")

get_collection_for_user_and_logname = cfy (userid, logname) ->*
  return yield get_collection("#{userid}_#{logname}")

app.get '/feedback', auth, ->*
  feedback = []
  collections = yield list_collections()
  db = yield get_mongo_db()
  for entry in collections
    if entry.indexOf('feedback') > -1
      collection = db.collection(entry)
      all_items = yield -> collection.find({}, ["feedback"]).toArray(it)
      for item in all_items
        feedback.push item["feedback"] if item["feedback"]?
  this.body = JSON.stringify feedback
  db.close()
  return    

app.get '/getactiveusers', auth, ->*
  users = []
  users_set = {}
  now = Date.now()
  secs_in_day = 86400000
  collections = yield list_collections()
  db = yield get_mongo_db()
  for entry in collections
    if entry.indexOf('_') == -1
      continue
    entry_parts = entry.split('_')
    userid = entry_parts[0]
    logname = entry_parts[1 to].join('_')
    if logname.startsWith('facebook:')
    #if entry.indexOf("logs/interventions") > -1 #filter to check if data gotten today
    #see if intervention latest timestamp was today
      collection = db.collection(entry)
      all_items = yield -> collection.find({}, ["timestamp"]).toArray(it)
      timestamp = prelude.maximum all_items.map (.timestamp)
      if now - timestamp < secs_in_day
        if not users_set[userid]?
          users.push userid
          users_set[userid] = true
  this.body = JSON.stringify users
  db.close()
  return

app.get '/add_install', ->*
  this.type = 'json'
  try
    [installs, db] = yield get_installs()
    query = {} <<< this.request.query
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = this.request.ip
    yield -> installs.insert(query, it)
  catch err
    console.log 'error in add_install'
    console.log err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}

app.post '/add_install', ->*
  this.type = 'json'
  try
    [installs, db] = yield get_installs()
    query = {} <<< this.request.body
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = this.request.ip
    yield -> installs.insert(query, it)
  catch err
    console.log 'error in add_install'
    console.log err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}

app.get '/add_uninstall', ->*
  this.type = 'json'
  try
    [uninstalls, db] = yield get_uninstalls()
    query = {} <<< this.request.query
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = this.request.ip
    yield -> uninstalls.insert(query, it)
  catch err
    console.log 'error in add_uninstall'
    console.log err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}

app.get '/add_uninstall_feedback', ->*
  this.type = 'json'
  try
    [uninstalls, db] = yield get_uninstall_feedback()
    query = {} <<< this.request.query
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = this.request.ip
    yield -> uninstalls.insert(query, it)
  catch err
    console.log 'error in add_uninstall_feedback'
    console.log err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}

app.get '/get_installs', auth, ->*
  this.type = 'json'
  try
    [installs, db] = yield get_installs()
    all_results = yield -> installs.find({}).toArray(it)
    this.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_installs'
    console.log err
    this.body = JSON.stringify {response: 'error', error: 'error in get_installs'}
  finally
    db?close()

app.get '/get_uninstalls', auth, ->*
  this.type = 'json'
  try
    [uninstalls, db] = yield get_uninstalls()
    all_results = yield -> uninstalls.find({}).toArray(it)
    this.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_uninstalls'
    console.log err
    this.body = JSON.stringify {response: 'error', error: 'error in get_uninstalls'}
  finally
    db?close()

app.get '/get_uninstall_feedback', auth, ->*
  this.type = 'json'
  try
    [uninstalls, db] = yield get_uninstall_feedback()
    all_results = yield -> uninstalls.find({}).toArray(it)
    this.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_uninstalls'
    console.log err
    this.body = JSON.stringify {response: 'error', error: 'error in get_uninstall_feedback'}
  finally
    db?close()

app.get '/addsignup', ->*
  this.type = 'json'
  {email} = this.request.query
  if not email?
    this.body = JSON.stringify {response: 'error', error: 'need parameter email'}
    return
  try
    [signups,db] = yield get_signups()
    yield -> signups.insert(this.request.query, it)
  catch err
    console.log 'error in addsignup'
    console.log err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}

app.post '/addsignup', ->*
  this.type = 'json'
  {email} = this.request.body
  if not email?
    this.body = JSON.stringify {response: 'error', error: 'need parameter email'}
    return
  try
    [signups, db] = yield get_signups()
    yield -> signups.insert(this.request.body, it)
  catch err
    console.log 'error in addsignup'
    console.log err
  finally
    db?close()
  this.body = JSON.stringify {response: 'success', success: true}

app.get '/getsignups', auth, ->*
  this.type = 'json'
  try
    [signups, db] = yield get_signups()
    all_results = yield -> signups.find({}).toArray(it)
    this.body = JSON.stringify([x.email for x in all_results])
  catch err
    console.log 'error in getsignups'
    console.log err
    this.body = JSON.stringify {response: 'error', error: 'error in getsignups'}
  finally
    db?close()

app.get '/list_logs_for_user', auth, ->*
  this.type = 'json'
  {userid} = this.request.query
  if not userid?
    this.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  user_collections = yield list_log_collections_for_user(userid)
  this.body = JSON.stringify user_collections

app.get '/list_logs_for_logname', auth, ->*
  this.type = 'json'
  {logname} = this.request.query
  if not logname?
    this.body = JSON.stringify {response: 'error', error: 'need parameter logname'}
    return
  user_collections = yield list_log_collections_for_logname(logname)
  this.body = JSON.stringify user_collections

app.get '/printcollection', auth, ->*
  {collection, userid, logname} = this.request.query
  if userid? and logname?
    collection = "#{userid}_#{logname}"
  if not collection?
    this.body = JSON.stringify {response: 'error', error: 'need paramter collection'}
  collection_name = collection
  try
    [collection, db] = yield get_collection(collection_name)
    items = yield -> collection.find({}).toArray(it)
    this.body = JSON.stringify items
  catch err
    console.log 'error in printcollection'
    console.log err
    this.body = JSON.stringify {response: 'error', error: 'error in printcollection'}
  finally
    db?close()

app.get '/listcollections', auth, ->*
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
  try
    [collection,db] = yield get_collection_for_user_and_logname(userid, 'synced:' + collection_name)
    yield -> collection.insert(this.request.body, it)
  catch err
    console.log 'error in sync_collection_item'
    console.log err
  finally
    db?close()
  #this.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  this.body = JSON.stringify {response: 'success', success: true}

app.post '/addtolog', ->*
  this.type = 'json'
  {userid, logname, itemid} = this.request.body
  logname = logname.split('/').join(':')
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
  try
    [collection,db] = yield get_collection_for_user_and_logname(userid, logname)
    this.request.body._id = mongodb.ObjectId.createFromHexString(itemid)
    yield -> collection.insert(this.request.body, it)
  catch err
    console.log 'error in addtolog'
    console.log err
  finally
    db?close()
  #this.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  this.body = JSON.stringify {response: 'success', success: true}

kapp.use(app.routes())
kapp.use(app.allowedMethods())

kapp.use(koa-static(__dirname + '/www'))
port = process.env.PORT ? 5000
kapp.listen(port)
console.log "listening to port #{port} visit http://localhost:#{port}"
