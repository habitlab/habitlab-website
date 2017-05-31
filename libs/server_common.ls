require! {
  'koa'
  'koa-static'
  'koa-router'
  'koa-bodyparser'
  'koa-jsonp'
  'mongodb'
  'getsecret'
  'koa-basic-auth'
}

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

export {cfy, cfy_node, yfy_node} = require 'cfy'

export mongourl = getsecret('MONGODB_URI') ? 'mongodb://localhost:27017/default'

export mongourl2 = getsecret('MONGODB_URI2') ? 'mongodb://localhost:27017/default'

export get_mongo_db = ->>
  try
    return await new Promise -> mongodb.MongoClient.connect mongourl, it
  catch err
    console.error 'error getting mongodb'
    console.error err
    return

export get_mongo_db2 = ->>
  try
    return await new Promise -> mongodb.MongoClient.connect mongourl2, it
  catch err
    console.error 'error getting mongodb'
    console.error err
    return

export get_collection = (collection_name) ->>
  db = await get_mongo_db()
  return [db.collection(collection_name), db]

export get_collection2 = (collection_name) ->>
  db = await get_mongo_db2()
  return [db.collection(collection_name), db]

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

export list_collections = ->>
  ndb = await get_mongo_db()
  collections_list = await new Promise -> ndb.listCollections().toArray(it)
  ndb.close()
  return collections_list.map (.name)

export list_log_collections_for_user = (userid) ->>
  all_collections = await list_collections()
  return all_collections.filter -> it.startsWith("#{userid}_")

export list_log_collections_for_logname = (logname) ->>
  all_collections = await list_collections()
  return all_collections.filter -> it.endsWith("_#{logname}")

export get_collection_for_user_and_logname = (userid, logname) ->>
  return await get_collection("#{userid}_#{logname}")

export need_query_properties = (ctx, properties_list) ->>
  for property in properties_list
    if not ctx.request.query[property]?
      ctx.body = JSON.stringify {response: 'error', error: 'Need ' + property}
      return true
  return false

export need_query_property = (ctx, property) ->>
  if not ctx.request.query[property]?
    ctx.body = JSON.stringify {response: 'error', error: 'Need ' + property}
    return true
  return false
