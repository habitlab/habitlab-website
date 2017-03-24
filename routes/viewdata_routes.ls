{
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
  list_log_collections_for_logname
  get_collection_for_user_and_logname
} = require 'libs/server_common'

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

app.get '/get_secrets', auth, ->*
  this.type = 'json'
  try
    [secrets, db] = yield get_secrets()
    all_results = yield -> secrets.find({}).toArray(it)
    this.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_secrets'
    console.log err
    this.body = JSON.stringify {response: 'error', error: 'error in get_secrets'}
  finally
    db?close()

app.get '/get_logging_states', auth, ->*
  this.type = 'json'
  try
    [logging_states, db] = yield get_logging_states()
    all_results = yield -> logging_states.find({}).toArray(it)
    this.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_logging_states'
    console.log err
    this.body = JSON.stringify {response: 'error', error: 'error in get_logging_states'}
  finally
    db?close()

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
