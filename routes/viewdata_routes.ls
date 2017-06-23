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

require! {
  n2p
}

app.get '/feedback', auth, (ctx) ->>
  feedback = []
  collections = await list_collections()
  db = await get_mongo_db()
  for entry in collections
    if entry.indexOf('feedback') > -1
      collection = db.collection(entry)
      all_items = await n2p -> collection.find({}, ["feedback"]).toArray(it)
      for item in all_items
        feedback.push item["feedback"] if item["feedback"]?
  ctx.body = JSON.stringify feedback
  db.close()
  return

app.get '/getactiveusers', auth, (ctx) ->>
  users = []
  users_set = {}
  now = Date.now()
  secs_in_day = 86400000
  collections = await list_collections()
  db = await get_mongo_db()
  for entry in collections
    if entry.indexOf('_') == -1
      continue
    entry_parts = entry.split('_')
    userid = entry_parts[0]
    logname = entry_parts[1 to].join('_')
    if logname.startsWith('facebook:') or logname.startsWith('youtube:') or logname.startsWith('logs:') or logname.startsWith('synced:')
    #if entry.indexOf("logs/interventions") > -1 #filter to check if data gotten today
    #if logname.startsWith('logs:') != -1
    #see if intervention latest timestamp was today
      collection = db.collection(entry)
      #num_items = await n2p -> collection.count({}, it)
      all_items = await n2p -> collection.find({}, {sort: {'timestamp': -1}, limit: 1, fields: {'timestamp': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, {sort: {'_id': -1}, limit: 1, fields: {'timestamp': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, {skip: num_items - 1, limit: 1, fields: {'timestamp': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, ["timestamp"]).toArray(it)
      timestamp = prelude.maximum all_items.map (.timestamp)
      if now - timestamp < secs_in_day
        if not users_set[userid]?
          users.push userid
          users_set[userid] = true
  ctx.body = JSON.stringify users
  db.close()
  return

app.get '/get_secrets', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [secrets, db] = await get_secrets()
    all_results = await n2p -> secrets.find({}).toArray(it)
    ctx.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_secrets'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in get_secrets'}
  finally
    db?close()

app.get '/get_logging_states', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [logging_states, db] = await get_logging_states()
    all_results = await n2p -> logging_states.find({}).toArray(it)
    ctx.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_logging_states'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in get_logging_states'}
  finally
    db?close()

app.get '/get_installs', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [installs, db] = await get_installs()
    all_results = await n2p -> installs.find({}).toArray(it)
    ctx.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_installs'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in get_installs'}
  finally
    db?close()

app.get '/get_uninstalls', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [uninstalls, db] = await get_uninstalls()
    all_results = await n2p -> uninstalls.find({}).toArray(it)
    ctx.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_uninstalls'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in get_uninstalls'}
  finally
    db?close()

app.get '/get_uninstall_feedback', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [uninstalls, db] = await get_uninstall_feedback()
    all_results = await n2p -> uninstalls.find({}).toArray(it)
    ctx.body = JSON.stringify(all_results)
  catch err
    console.log 'error in get_uninstalls'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in get_uninstall_feedback'}
  finally
    db?close()

app.get '/getsignups', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [signups, db] = await get_signups()
    all_results = await n2p -> signups.find({}).toArray(it)
    ctx.body = JSON.stringify([x.email for x in all_results])
  catch err
    console.log 'error in getsignups'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in getsignups'}
  finally
    db?close()

app.get '/list_logs_for_user', auth, (ctx) ->>
  ctx.type = 'json'
  {userid} = ctx.request.query
  if not userid?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  user_collections = await list_log_collections_for_user(userid)
  ctx.body = JSON.stringify user_collections

app.get '/list_logs_for_logname', auth, (ctx) ->>
  ctx.type = 'json'
  {logname} = ctx.request.query
  if not logname?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter logname'}
    return
  user_collections = await list_log_collections_for_logname(logname)
  ctx.body = JSON.stringify user_collections

app.get '/printcollection', auth, (ctx) ->>
  {collection, userid, logname} = ctx.request.query
  if userid? and logname?
    collection = "#{userid}_#{logname}"
  if not collection?
    ctx.body = JSON.stringify {response: 'error', error: 'need paramter collection'}
  collection_name = collection
  try
    [collection, db] = await get_collection(collection_name)
    items = await n2p -> collection.find({}).toArray(it)
    ctx.body = JSON.stringify items
  catch err
    console.log 'error in printcollection'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in printcollection'}
  finally
    db?close()

app.get '/listcollections', auth, (ctx) ->>
  ctx.type = 'json'
  ctx.body = JSON.stringify await list_collections()

app.get '/get_user_to_install_times', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [installs, db] = await get_installs()
    all_results = await n2p -> installs.find({}).toArray(it)
    output = {}
    for install_info in all_results
      output[install_info.user_id] = install_info.timestamp
    ctx.body = JSON.stringify(output)
  catch err
    console.log 'error in get_user_to_install_times'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in get_user_to_install_times'}
  finally
    db?close()

app.get '/get_user_to_uninstall_times', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [uninstalls, db] = await get_uninstalls()
    all_results = await n2p -> uninstalls.find({}).toArray(it)
    output = {}
    for uninstall_info in all_results
      output[uninstall_info.u] = uninstall_info.timestamp
    ctx.body = JSON.stringify(output)
  catch err
    console.log 'error in get_user_to_uninstall_times'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in get_user_to_uninstall_times'}
  finally
    db?close()

app.get '/get_user_to_duration_kept_installed', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [uninstalls, db] = await get_uninstalls()
    all_uninstalls = await n2p -> uninstalls.find({}).toArray(it)
    [installs, db2] = await get_installs()
    all_installs = await n2p -> installs.find({}).toArray(it)
    output = {}
    user_to_install_info = {}
    user_to_uninstall_info = {}
    for install_info in all_installs
      user_to_install_info[install_info.user_id] = install_info
    for uninstall_info in all_uninstalls
      user_to_uninstall_info[uninstall_info.u] = uninstall_info
    for user_id,install_info of user_to_install_info
      install_time = install_info.timestamp
      uninstall_info = user_to_uninstall_info[user_id]
      time_installed_until = Date.now()
      if uninstall_info?
        time_installed_until = uninstall_info.timestamp
      days_kept_installed = (time_installed_until - install_time) / (1000*3600*24)
      output[user_id] = days_kept_installed
    ctx.body = JSON.stringify(output)
  catch err
    console.log 'error in get_user_to_duration_kept_installed'
    console.log err
    ctx.body = JSON.stringify {response: 'error', error: 'error in get_user_to_duration_kept_installed'}
  finally
    db?close()
    db2?close()

/*
app.get '/get_daily_active_counts', auth, (ctx) ->>
  ctx.type = 'json'
  users = []
  users_set = {}
  now = Date.now()
  secs_in_day = 86400000
  collections = await list_collections()
  db = await get_mongo_db()
  for entry in collections
    if entry.indexOf('_') == -1
      continue
    entry_parts = entry.split('_')
    userid = entry_parts[0]
    logname = entry_parts[1 to].join('_')
    if logname.startsWith('facebook:') or logname.startsWith('youtube:') or logname.startsWith('logs:') or logname.startsWith('synced:')
    #if entry.indexOf("logs/interventions") > -1 #filter to check if data gotten today
    #if logname.startsWith('logs:') != -1
    #see if intervention latest timestamp was today
      collection = db.collection(entry)
      #num_items = await n2p -> collection.count({}, it)
      all_items = await n2p -> collection.find({}, {fields: {'timestamp': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, {sort: {'_id': -1}, limit: 1, fields: {'timestamp': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, {skip: num_items - 1, limit: 1, fields: {'timestamp': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, ["timestamp"]).toArray(it)
      timestamps = all_items.map (.timestamp)
      for timestamp in timestamps
        
      timestamp = prelude.maximum all_items.map (.timestamp)
      if now - timestamp < secs_in_day
        if not users_set[userid]?
          users.push userid
          users_set[userid] = true
  ctx.body = JSON.stringify users
  db.close()
  return
*/