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
  get_collection_share_intervention
  get_collection_non_share_intervention
  mongodb
  need_query_property
  need_query_properties
  get_webvisits
  fix_object
} = require 'libs/server_common'

require! {
  n2p
}

app.post '/add_secret', (ctx) ->>
  ctx.type = 'json'
  try
    [secrets, db] = await get_secrets()
    query = {} <<< ctx.request.body
    if query.callback?
      delete query.callback
    {user_id, user_secret} = query
    query.timestamp = Date.now()
    query.ip = ctx.request.ip_address_fixed
    if not user_id?
      ctx.body = JSON.stringify {response: 'error', error: 'Need user_id'}
      return
    if not user_secret?
      ctx.body = JSON.stringify {response: 'error', error: 'Need user_secret'}
      return
    if (await n2p -> secrets.findOne({'user_id': user_id}, it))?
      ctx.body = JSON.stringify {response: 'error', error: 'Already have set user_secret for user_id'}
      return
    await n2p -> secrets.insert(fix_object(query), it)
  catch err
    console.error 'error in add_secret'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

app.post '/add_logging_state', (ctx) ->>
  ctx.type = 'json'
  try
    [logging_states, db] = await get_logging_states()
    query = {} <<< ctx.request.body
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = ctx.request.ip_address_fixed
    await n2p -> logging_states.insert(fix_object(query), it)
  catch err
    console.error 'error in add_logging_state'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

is_valid_collection_name = (name) ->
  if name.length > 90
    return false
  valid_collection_characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_'
  for x in name
    if valid_collection_characters.indexOf(x) == -1
      return false
  return true

app.post '/add_feature_state', (ctx) ->>
  ctx.type = 'json'
  try
    query = {} <<< ctx.request.body
    if query.callback?
      delete query.callback
    if (not query.feature?) or (not is_valid_collection_name(query.feature))
      ctx.body = JSON.stringify {response: 'need feature name', success: false}
      return
    [feature_states, db] = await get_collection('features:' + query.feature)
    query.timestamp = Date.now()
    query.ip = ctx.request.ip_address_fixed
    await n2p -> feature_states.insert(fix_object(query), it)
  catch err
    console.error 'error in add_feature_state'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

app.get '/add_install', (ctx) ->>
  ctx.type = 'json'
  try
    [installs, db] = await get_installs()
    query = {} <<< ctx.request.query
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = ctx.request.ip_address_fixed
    await n2p -> installs.insert(fix_object(query), it)
  catch err
    console.error 'error in add_install'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

app.post '/add_install', (ctx) ->>
  ctx.type = 'json'
  try
    [installs, db] = await get_installs()
    query = {} <<< ctx.request.body
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = ctx.request.ip_address_fixed
    await n2p -> installs.insert(fix_object(query), it)
  catch err
    console.error 'error in add_install'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

app.get '/add_uninstall', (ctx) ->>
  ctx.type = 'json'
  try
    [uninstalls, db] = await get_uninstalls()
    query = {} <<< ctx.request.query
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = ctx.request.ip_address_fixed
    await n2p -> uninstalls.insert(fix_object(query), it)
  catch err
    console.error 'error in add_uninstall'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

app.get '/add_uninstall_feedback', (ctx) ->>
  ctx.type = 'json'
  try
    [uninstalls, db] = await get_uninstall_feedback()
    query = {} <<< ctx.request.query
    if query.callback?
      delete query.callback
    query.timestamp = Date.now()
    query.ip = ctx.request.ip_address_fixed
    await n2p -> uninstalls.insert(fix_object(query), it)
  catch err
    console.error 'error in add_uninstall_feedback'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

app.post '/addtolog', (ctx) ->>
  ctx.type = 'json'
  {userid, logname} = ctx.request.body
  # {itemid} = ctx.request.body
  logname = logname.split('/').join(':')
  if not userid?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  if not logname?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter logname'}
    return
  #if not itemid?
  #  ctx.body = JSON.stringify {response: 'error', error: 'need parameter itemid'}
  #  return
  #if itemid.length != 24
  #  ctx.body = JSON.stringify {response: 'error', error: 'itemid length needs to be 24'}
  #  return
  try
    [collection,db] = await get_collection_for_user_and_logname(userid, logname)
    #ctx.request.body._id = mongodb.ObjectId.createFromHexString(itemid)
    if ctx.request.body.timestamp?
      ctx.request.body.timestamp_local = ctx.request.body.timestamp
    ctx.request.body.timestamp = Date.now()
    await n2p -> collection.insert(fix_object(ctx.request.body), it)
  catch err
    console.error 'error in addtolog'
    console.error err
  finally
    db?close()
  #ctx.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  ctx.body = JSON.stringify {response: 'success', success: true}

app.post '/sync_collection_item', (ctx) ->>
  ctx.type = 'json'
  {userid, collection} = ctx.request.body
  collection_name = collection
  if not userid?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  if not collection_name?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter collection'}
    return
  try
    [collection,db] = await get_collection_for_user_and_logname(userid, 'synced:' + collection_name)
    if ctx.request.body.timestamp?
      ctx.request.body.timestamp_local = ctx.request.body.timestamp
    ctx.request.body.timestamp = Date.now()
    await n2p -> collection.insert(fix_object(ctx.request.body), it)
  catch err
    console.error 'error in sync_collection_item'
    console.error err
  finally
    db?close()
  #ctx.body = JSON.stringify {response: 'error', error: 'not yet implemented'}
  ctx.body = JSON.stringify {response: 'success', success: true}

app.post '/addsignup', (ctx) ->>
  ctx.type = 'json'
  {email} = ctx.request.body
  if not email?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter email'}
    return
  try
    [signups, db] = await get_signups()
    await n2p -> signups.insert(fix_object(ctx.request.body), it)
  catch err
    console.error 'error in addsignup'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'success', success: true}

app.get '/addsignup', (ctx) ->>
  ctx.type = 'json'
  {email} = ctx.request.query
  if not email?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter email'}
    return
  try
    [signups,db] = await get_signups()
    await n2p -> signups.insert(fix_object(ctx.request.query), it)
  catch err
    console.error 'error in addsignup'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

app.get '/logwebvisit', (ctx) ->>
  ctx.type = 'json'
  {userid, domain, action} = ctx.request.query
  if need_query_properties ctx, ['userid', 'domain', 'action']
    return
  try
    [webvisits, db] = await get_webvisits()
    timestamp = Date.now()
    await n2p -> webvisits.insert(fix_object({userid, domain, action, timestamp}), it)
  catch err
    console.error 'error in logwebvisit'
    console.error err
  finally
    db?close()
  ctx.body = JSON.stringify {response: 'done', success: true}

# TODO: These routes might be consolidated with others in the future
# specifically for adding shared intervention accross users
app.post '/sharedintervention', (ctx) ->>
  ctx.type = 'json'
  # construct new sharable item
  console.log ctx.request.body
  # the user generated unique id will be the key to retrieve code
  {author_email, author_id, description, 
  goals, name, code, is_sharing, preview, 
  key, sitename, numusers, stars, comments,
  displayname, domain, matches, sitename_printable} = ctx.request.body
  # validate the input
  if not author_id? or not author_email? or not key?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter user info'}
    return
  if not goals? or not name? or not sitename?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter goals'}
    return
  if not code?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter code'}
    return

  # TODO: we are saving these blank fields
  numusers ?= 0
  stars ?= 0
  comments ?= []
  new_share_item = {author_email, author_id, description, 
  goals, name, code, preview, key, sitename, numusers, stars, comments,
  displayname, domain, matches, sitename_printable}
  # inject into database
  if is_sharing
    # sharable
    try
      [collection,db] = await get_collection_share_intervention()
      await n2p -> collection.insert(fix_object(new_share_item), it)
      ctx.body = JSON.stringify {response: 'success', success: true}
    catch err
      console.error 'error in get_collection_share_intervention'
      console.error err
      ctx.body = JSON.stringify {response: 'failure', success: false}
    finally
      db?close()
  else
    # non-sharable
    try
      [collection,db] = await get_collection_non_share_intervention()
      await n2p -> collection.insert(fix_object(new_share_item), it)
      ctx.body = JSON.stringify {response: 'success', success: true}
    catch err
      console.error 'error in get_collection_non_share_intervention'
      console.error err
      ctx.body = JSON.stringify {response: 'failure', success: false}
    finally
      db?close()
  ctx.body = JSON.stringify {response: 'success', success: true}

# TODO: These routes might be consolidated with others in the future
app.get '/get_sharedinterventions_for_site', (ctx) ->>
  ctx.type = 'json'
  {website} = ctx.request.query
  if need_query_property ctx, 'website'
    return
  [collection, db] = await get_collection_share_intervention()/*Find these functions*/
  all_results = await n2p -> collection.find({sitename: website}).toArray(it)
  #console.log "Here are the shared results for " + website
  #console.log all_results
  ctx.body = JSON.stringify(all_results)
  db?close()

# TODO: These routes might be consolidated with others in the future
app.get '/delete_shared_intervention', (ctx) ->>
  ctx.type = 'json'
  {key} = ctx.request.query
  if need_query_property ctx, 'key'
    ctx.body = JSON.stringify {response: 'failure', success: false}
    return
  [collection, db] = await get_collection_share_intervention()/*Find these functions*/
  # all_results = await n2p -> collection.find({sitename: website}).toArray(it)
  await n2p -> collection.remove({key: key}, it)
  ctx.body = JSON.stringify {response: 'success', success: true}
db?close()

require('libs/globals').add_globals(module.exports)
