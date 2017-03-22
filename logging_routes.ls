{
  app
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
  mongodb
} = require './server_common'

app.post '/add_secret', ->*
  this.type = 'json'
  try
    [secrets, db] = yield get_secrets()
    query = {} <<< this.request.body
    if query.callback?
      delete query.callback
    {user_id, user_secret} = query
    query.timestamp = Date.now()
    query.ip = this.request.ip_address_fixed
    if not user_id?
      this.body = JSON.stringify {response: 'error', error: 'Need user_id'}
      return
    if not user_secret?
      this.body = JSON.stringify {response: 'error', error: 'Need user_secret'}
      return
    if (yield secrets.findOne({'user_id': user_id}))?
      this.body = JSON.stringify {response: 'error', error: 'Already have set user_secret for user_id'}
      return
    yield -> secrets.insert(query, it)
  catch err
    console.error 'error in add_secret'
    console.error err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}

app.post '/add_logging_state', ->*
  this.type = 'json'
  try
    [logging_states, db] = yield get_logging_states()
    query = {} <<< this.request.body
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = this.request.ip_address_fixed
    yield -> logging_states.insert(query, it)
  catch err
    console.error 'error in add_logging_state'
    console.error err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}

app.get '/add_install', ->*
  this.type = 'json'
  try
    [installs, db] = yield get_installs()
    query = {} <<< this.request.query
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = this.request.ip_address_fixed
    yield -> installs.insert(query, it)
  catch err
    console.error 'error in add_install'
    console.error err
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
    query.ip = this.request.ip_address_fixed
    yield -> installs.insert(query, it)
  catch err
    console.error 'error in add_install'
    console.error err
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
    query.ip = this.request.ip_address_fixed
    yield -> uninstalls.insert(query, it)
  catch err
    console.error 'error in add_uninstall'
    console.error err
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
    query.ip = this.request.ip_address_fixed
    yield -> uninstalls.insert(query, it)
  catch err
    console.error 'error in add_uninstall_feedback'
    console.error err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}

app.post '/addtolog', ->*
  this.type = 'json'
  {userid, logname} = this.request.body
  # {itemid} = this.request.body
  logname = logname.split('/').join(':')
  if not userid?
    this.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  if not logname?
    this.body = JSON.stringify {response: 'error', error: 'need parameter logname'}
    return
  #if not itemid?
  #  this.body = JSON.stringify {response: 'error', error: 'need parameter itemid'}
  #  return
  #if itemid.length != 24
  #  this.body = JSON.stringify {response: 'error', error: 'itemid length needs to be 24'}
  #  return
  try
    [collection,db] = yield get_collection_for_user_and_logname(userid, logname)
    #this.request.body._id = mongodb.ObjectId.createFromHexString(itemid)
    yield -> collection.insert(this.request.body, it)
  catch err
    console.error 'error in addtolog'
    console.error err
  finally
    db?close()
  #this.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  this.body = JSON.stringify {response: 'success', success: true}

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
    console.error 'error in sync_collection_item'
    console.error err
  finally
    db?close()
  #this.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  this.body = JSON.stringify {response: 'success', success: true}

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
    console.error 'error in addsignup'
    console.error err
  finally
    db?close()
  this.body = JSON.stringify {response: 'success', success: true}

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
    console.error 'error in addsignup'
    console.error err
  finally
    db?close()
  this.body = JSON.stringify {response: 'done', success: true}
