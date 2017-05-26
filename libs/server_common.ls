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

export kapp = koa()
kapp.use(koa-jsonp())
#kapp.use(koa-logger())
kapp.use(koa-bodyparser({jsonLimit: '20mb'}))
export app = koa-router()

if getsecret('username')? or getsecret('password')?
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
  export auth = koa-basic-auth({name: getsecret('username'), pass: getsecret('password')})
else
  export auth = (next) ->* yield next

export {cfy, cfy_node, yfy_node} = require 'cfy'

export mongourl = getsecret('MONGODB_URI') ? 'mongodb://localhost:27017/default'

export mongourl2 = getsecret('MONGODB_URI2') ? 'mongodb://localhost:27017/default'

export get_mongo_db = cfy ->*
  try
    return yield -> mongodb.MongoClient.connect mongourl, it
  catch err
    console.error 'error getting mongodb'
    console.error err
    return

export get_mongo_db2 = cfy ->*
  try
    return yield -> mongodb.MongoClient.connect mongourl2, it
  catch err
    console.error 'error getting mongodb'
    console.error err
    return

export get_collection = cfy (collection_name) ->*
  db = yield get_mongo_db()
  return [db.collection(collection_name), db]

export get_collection2 = cfy (collection_name) ->*
  db = yield get_mongo_db2()
  return [db.collection(collection_name), db]

export get_signups = cfy ->*
  return yield get_collection('signups')

export get_secrets = cfy ->*
  return yield get_collection('secrets')

export get_logging_states = cfy ->*
  return yield get_collection('logging_states')

export get_installs = cfy ->*
  return yield get_collection('installs')

export get_uninstalls = cfy ->*
  return yield get_collection('uninstalls')

export get_uninstall_feedback = cfy ->*
  return yield get_collection('uninstall_feedback')

export get_proposed_goals = cfy ->*
  return yield get_collection2('proposed_goals')

export get_contributed_interventions = cfy ->*
  return yield get_collection2('contributed_interventions')

export list_collections = cfy ->*
  ndb = yield get_mongo_db()
  collections_list = yield -> ndb.listCollections().toArray(it)
  ndb.close()
  return collections_list.map (.name)

export list_log_collections_for_user = cfy (userid) ->*
  all_collections = yield list_collections()
  return all_collections.filter -> it.startsWith("#{userid}_")

export list_log_collections_for_logname = cfy (logname) ->*
  all_collections = yield list_collections()
  return all_collections.filter -> it.endsWith("_#{logname}")

export get_collection_for_user_and_logname = cfy (userid, logname) ->*
  return yield get_collection("#{userid}_#{logname}")

export need_query_properties = (ctx, properties_list) ->*
  for property in properties_list
    if not ctx.request.query[property]?
      ctx.body = JSON.stringify {response: 'error', error: 'Need ' + property}
      return true
  return false

export need_query_property = (ctx, property) ->*
  if not ctx.request.query[property]?
    ctx.body = JSON.stringify {response: 'error', error: 'Need ' + property}
    return true
  return false
