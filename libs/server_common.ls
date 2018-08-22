require! {
  'koa'
  'koa-static'
  'koa-router'
  'koa-bodyparser'
  'koa-jsonp'
  'mongodb'
  'getsecret'
  'koa-basic-auth'
  'n2p'
}

memoizeSingleAsync = (func) ->
  cached_promise = null
  return ->
    if cached_promise?
      return cached_promise
    result = func()
    cached_promise := result
    return result

memoizeOneArgAsync = (func) ->
  cached_promises = {}
  return (x) ->
    cached_promise = cached_promises[x]
    if cached_promise?
      return cached_promise
    result = func(x)
    cached_promises[x] = result
    return result

export mongodb
export prelude = require 'prelude-ls'

export kapp = new koa()
kapp.use(koa-jsonp())
#kapp.use(koa-logger())
kapp.use(koa-bodyparser({jsonLimit: '20mb'}))
export app = new koa-router()

if getsecret('username')? or getsecret('password')?
  # custom 401 handling
  app.use (ctx, next) ->>
    try
      await next()
    catch err
      if 401 == err.status
        ctx.status = 401
        ctx.set('WWW-Authenticate', 'Basic')
        ctx.body = 'Authentication failed'
      else
        throw err
  export auth = koa-basic-auth({name: getsecret('username'), pass: getsecret('password')})
else
  export auth = (ctx, next) ->> await next()

export mongourl = getsecret('MONGODB_URI') ? 'mongodb://localhost:27017/default'

export mongourl2 = getsecret('MONGODB_URI_VOTING') ? 'mongodb://localhost:27017/default'

export mongourl_mobile = getsecret('MONGODB_URI_MOBILE') ? 'mongodb://localhost:27017/default'

sleep = (time) ->>
  return new Promise ->
    setTimeout(it, time)

export get_mongo_db = memoizeSingleAsync ->>
  connection_options = {
    w: 0
  }
  if process.env.PORT? # on heroku
    connection_options.readPreference = mongodb.ReadPreference.PRIMARY_PREFERRED
  else # local machine
    connection_options.readPreference = mongodb.ReadPreference.SECONDARY
    connection_options.readConcern = {
      level: 'available'
    }
  try
    return await n2p -> mongodb.MongoClient.connect(
      mongourl,
      connection_options,
      it
    )
  catch err
    console.error 'error getting mongodb'
    console.error err
    return


export get_collection_share_intervention = ->>
  return await get_collection('share_intervention_repo')
export get_collection_non_share_intervention = ->>
  return await get_collection('non_share_intervention_repo')

export get_mongo_db2 = memoizeSingleAsync ->>
  connection_options = {
    w: 0
    j: false
    #readConcern: ''
  }
  if process.env.PORT? # on heroku
    connection_options.readPreference = mongodb.ReadPreference.PRIMARY_PREFERRED
  else # local machine
    connection_options.readPreference = mongodb.ReadPreference.SECONDARY
    connection_options.readConcern = {
      level: 'available'
    }
  try
    return await n2p -> mongodb.MongoClient.connect(
      mongourl2,
      connection_options,
      it
    )
  catch err
    console.error 'error getting mongodb2'
    console.error err
    return

export get_mongo_db_mobile = memoizeSingleAsync ->>
  connection_options = {
    w: 0
    j: false
    #readConcern: ''
  }
  if process.env.PORT? # on heroku
    connection_options.readPreference = mongodb.ReadPreference.PRIMARY_PREFERRED
  else # local machine
    connection_options.readPreference = mongodb.ReadPreference.SECONDARY
    connection_options.readConcern = {
      level: 'available'
    }
  try
    return await n2p -> mongodb.MongoClient.connect(
      mongourl_mobile,
      connection_options,
      it
    )
  catch err
    console.error 'error getting mongodb2'
    console.error err
    return

/*
export create_collection_indexes = ->>
  db = await get_mongo_db()
  collections = db.collection('collections')
  await n2p -> collections.ensureIndex({name: 1}, it)
  await n2p -> collections.ensureIndex({collection: 1}, {sparse: true}, it)
  await n2p -> collections.ensureIndex({userid: 1}, {sparse: true}, it)
  return
*/

export does_collection_exist = (collection_name) ->>
  db = await get_mongo_db()
  collections = db.collection('collections')
  item = await n2p -> collections.findOne({_id: collection_name}, it)
  return item?

collections_already_logged = {}

export remove_collection_exists = (collection_name) ->>
  delete collections_already_logged[collection_name]
  db = await get_mongo_db()
  collections = db.collection('collections')
  await n2p -> collections.remove({_id: collection_name}, it)
  return

export log_collection_exists = (collection_name) ->>
  if collections_already_logged[collection_name]?
    return
  collections_already_logged[collection_name] = true
  db = await get_mongo_db()
  collections = db.collection('collections')
  underscore_index = collection_name.indexOf('_')
  if underscore_index == -1
    data = {_id: collection_name}
  else
    userid = collection_name.slice(0, underscore_index)
    collection = collection_name.slice(underscore_index + 1)
    data = {
      _id: collection_name,
      userid: userid,
      collection: collection
    }
  item = await n2p -> collections.findOne({_id: collection_name}, it)
  if item == null
    await n2p -> collections.insert(data, it)
  return

export get_collection = (collection_name) ->>
  db = await get_mongo_db()
  fakedb = {
    close: ->
  }
  collection = db.collection(collection_name)
  proxy_func = (obj, methodname) ->
    orig_method = obj[methodname]
    new_method = ->
      log_collection_exists(collection_name)
      return orig_method.apply(obj, arguments)
    obj[methodname] = new_method.bind(obj)
  proxy_func(collection, 'insert')
  proxy_func(collection, 'insertMany')
  proxy_func(collection, 'insertOne')
  proxy_func(collection, 'update')
  proxy_func(collection, 'updateMany')
  proxy_func(collection, 'updateOne')
  proxy_func(collection, 'save')
  #proxy_func(collection, 'findAndModify')
  #proxy_func(collection, 'findAndUpdate')
  return [collection, fakedb]

#export get_collection = memoizeOneArgAsync(get_collection_real)

export get_collection2 = (collection_name) ->>
  db = await get_mongo_db2()
  fakedb = {
    close: ->
  }
  return [db.collection(collection_name), fakedb]

export get_collection_mobile = (collection_name) ->>
  db = await get_mongo_db_mobile()
  fakedb = {
    close: ->
  }
  return [db.collection(collection_name), fakedb]

export get_email_to_user_mobile = ->>
  return await get_collection_mobile('email_to_user')

export get_signups = ->>
  return await get_collection('signups')

export get_secrets = ->>
  return await get_collection('secrets')

export get_logging_states = ->>
  return await get_collection('logging_states')

export get_installs = ->>
  return await get_collection('installs')

export get_uninstalls = ->>
  return await get_collection('uninstalls')

export get_uninstall_feedback = ->>
  return await get_collection('uninstall_feedback')

export get_proposed_goals = ->>
  return await get_collection2('proposed_goals')

export get_contributed_interventions = ->>
  return await get_collection2('contributed_interventions')

export get_install_active_dates = ->>
  return await get_collection('install_active_dates')

export get_user_active_dates = ->>
  return await get_collection('user_active_dates')

export get_intervention_votes = ->>
  return await get_collection2('intervention_votes')

export get_intervention_votes_total = ->>
  return await get_collection2('intervention_votes_total')

export get_webvisits = ->>
  return await get_collection('webvisits')

export list_collections_real = ->>
  ndb = await get_mongo_db()
  #collections_list = await n2p -> ndb.listCollections().toArray(it)
  collections_list = await n2p -> ndb.collection('collections').find({}, {_id: 1}).toArray(it)
  #ndb.close()
  return collections_list.map (._id)

export list_collections = memoizeSingleAsync list_collections_real

export list_log_collections_for_user_real = (userid) ->>
  all_collections = await list_collections()
  return all_collections.filter -> it.startsWith("#{userid}_")

/*
export list_log_collections_for_user_real = (userid) ->>
  ndb = await get_mongo_db()
  collections_list = await n2p -> ndb.collection('collections').find({userid: userid}, {_id: 1}).toArray(it)
  return collections_list.map (._id)
*/

export list_log_collections_for_user = list_log_collections_for_user_real
#export list_log_collections_for_user = memoizeOneArgAsync list_log_collections_for_user_real

export list_intervention_collections_for_user_real = (userid) ->>
  all_collections = await list_collections()
  return all_collections.filter(-> it.startsWith("#{userid}_")).filter(->
    entry_key = it.replace("#{userid}_", '')
    return !entry_key.startsWith('synced:') and !entry_key.startsWith('logs:')
  )

/*
export list_intervention_collections_for_user_real = (userid) ->>
  all_collections = await list_log_collections_for_user(userid)
  return all_collections.filter(-> it.startsWith("#{userid}_")).filter(->
    entry_key = it.replace("#{userid}_", '')
    return !entry_key.startsWith('synced:') and !entry_key.startsWith('logs:')
  )
*/

export list_intervention_collections_for_user = list_intervention_collections_for_user_real
#export list_intervention_collections_for_user = memoizeOneArgAsync list_intervention_collections_for_user_real

export list_log_collections_for_logname_real = (logname) ->>
  all_collections = await list_collections()
  return all_collections.filter -> it.endsWith("_#{logname}")

/*
export list_log_collections_for_logname_real = (collection) ->>
  ndb = await get_mongo_db()
  collections_list = await n2p -> ndb.collection('collections').find({collection: collection}, {_id: 1}).toArray(it)
  return collections_list.map (._id)

*/

export list_log_collections_for_logname = list_log_collections_for_logname_real
#export list_log_collections_for_logname = memoizeOneArgAsync list_log_collections_for_logname_real

export get_collection_for_user_and_logname = (userid, logname) ->>
  return await get_collection("#{userid}_#{logname}")

export need_query_properties = (ctx, properties_list) ->
  for property in properties_list
    if not ctx.request.query[property]?
      ctx.body = JSON.stringify {response: 'error', error: 'Need ' + property}
      return true
  return false

export need_body_properties = (ctx, properties_list) ->
  for property in properties_list
    if not ctx.request.body[property]?
      ctx.body = JSON.stringify {response: 'error', error: 'Need ' + property}
      return true
  return false

export need_query_property = (ctx, property) ->
  if not ctx.request.query[property]?
    ctx.body = JSON.stringify {response: 'error', error: 'Need ' + property}
    return true
  return false

export need_body_property = (ctx, property) ->
  if not ctx.request.body[property]?
    ctx.body = JSON.stringify {response: 'error', error: 'Need ' + property}
    return true
  return false

export expose_get_auth = (func, ...params) ->
  request_path = '/' + func.name
  app.get request_path, auth, (ctx) ->>
    ctx.type = 'json'
    data = ctx.request.query
    for param in params
      if need_query_property(ctx, param)
        return
    data_array = [data[param] for param in params]
    results = await func(...data_array)
    ctx.body = JSON.stringify results

export fix_object = (obj) ->
  if Array.isArray(obj)
    return obj.map(fix_object)
  if typeof(obj) != 'object'
    return obj
  output = {}
  for k,v of obj
    if typeof(k) == 'string'
      if k.includes('.')
        k = k.split('.').join('\u2024')
      if k[0] == '$'
        k = '\ufe69' + k.substr(1)
    output[k] = fix_object(v)
  return output

export get_collection_goal_ideas = ->>
  return await get_collection2('get_collection_goal_ideas')

export get_collection_goal_idea_candidates = ->>
  return await get_collection2('get_collection_goal_idea_candidates')

export get_collection_goal_idea_logs = ->>
  return await get_collection2('get_collection_goal_idea_logs')

require('libs/globals').add_globals(module.exports)
