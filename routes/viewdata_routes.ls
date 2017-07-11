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
  list_intervention_collections_for_user
  list_log_collections_for_logname
  get_collection_for_user_and_logname
  get_user_active_dates
  need_query_property
  need_query_properties
  expose_get_auth
} = require 'libs/server_common'

require! {
  n2p
  moment
  semver
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

app.get '/getactiveusers_withversion', auth, (ctx) ->>
  ctx.type = 'json'
  user_to_version = {}
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
      all_items = await n2p -> collection.find({}, {sort: {'timestamp': -1}, limit: 1, fields: {'timestamp': 1, 'habitlab_version': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, {sort: {'_id': -1}, limit: 1, fields: {'timestamp': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, {skip: num_items - 1, limit: 1, fields: {'timestamp': 1}}).toArray(it)
      #all_items = await n2p -> collection.find({}, ["timestamp"]).toArray(it)
      for item in all_items
        timestamp = item.timestamp
        if timestamp > now - secs_in_day
          if item.habitlab_version?
            version = item.habitlab_version
            if not user_to_version[userid]?
              user_to_version[userid] = version
            if semver.gt version, user_to_version[userid]
              user_to_version[userid] = version
  ctx.body = JSON.stringify user_to_version
  db.close()
  return

app.get '/get_version_for_user', auth, (ctx) ->>
  ctx.type = 'json'
  {userid} = ctx.request.query
  if not userid?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  user_to_version = {}
  now = Date.now()
  secs_in_day = 86400000
  user_collections = await list_log_collections_for_user(userid)
  db = await get_mongo_db()
  for entry in user_collections
    if entry.indexOf('_') == -1
      continue
    entry_parts = entry.split('_')
    userid = entry_parts[0]
    logname = entry_parts[1 to].join('_')
    if logname.startsWith('facebook:') or logname.startsWith('youtube:') or logname.startsWith('logs:') or logname.startsWith('synced:')
      collection = db.collection(entry)
      all_items = await n2p -> collection.find({}, {sort: {'timestamp': -1}, limit: 1, fields: {'timestamp': 1, 'habitlab_version': 1}}).toArray(it)
      for item in all_items
        timestamp = item.timestamp
        if timestamp > now - secs_in_day
          if item.habitlab_version?
            version = item.habitlab_version
            if not user_to_version[userid]?
              user_to_version[userid] = version
            if semver.gt version, user_to_version[userid]
              user_to_version[userid] = version
  ctx.body = user_to_version[userid]
  db.close()

app.get '/getactiveusers', auth, (ctx) ->>
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

app.get '/get_time_last_log_was_sent_for_user', auth, (ctx) ->>
  ctx.type = 'json'
  {userid} = ctx.request.query
  if not userid?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter userid'}
    return
  user_to_version = {}
  now = Date.now()
  user_collections = await list_log_collections_for_user(userid)
  db = await get_mongo_db()
  latest_timestamp = -1
  for entry in user_collections
    if entry.indexOf('_') == -1
      continue
    entry_parts = entry.split('_')
    userid = entry_parts[0]
    logname = entry_parts[1 to].join('_')
    if logname.startsWith('facebook:') or logname.startsWith('youtube:') or logname.startsWith('logs:') or logname.startsWith('synced:')
      collection = db.collection(entry)
      all_items = await n2p -> collection.find({}, {sort: {'timestamp': -1}, limit: 1, fields: {'timestamp': 1, 'habitlab_version': 1}}).toArray(it)
      for item in all_items
        timestamp = item.timestamp
        if timestamp > latest_timestamp
          latest_timestamp = timestamp
  ctx.body = latest_timestamp
  db.close()

export get_intervention_to_time_most_recently_seen = (user_id) ->>
  collections = await list_intervention_collections_for_user(user_id)
  db = await get_mongo_db()
  output = {}
  for entry in collections
    entry_key = entry.replace(user_id + '_', '')
    collection = db.collection(entry)
    all_items = await n2p -> collection.find({}, {fields: {'timestamp': 1}}).toArray(it)
    timestamp = prelude.maximum all_items.map (.timestamp)
    output[entry_key] = timestamp
  db.close()
  return output

expose_get_auth get_intervention_to_time_most_recently_seen, 'userid'

export get_last_intervention_seen = (user_id) ->>
  intervention_to_time_seen = await get_intervention_to_time_most_recently_seen(user_id)
  last_intervention_seen = null
  time_last_intervention_seen = null
  for intervention_name,time_seen of intervention_to_time_seen
    if not last_intervention_seen?
      last_intervention_seen = intervention_name
      time_last_intervention_seen = time_seen
    else
      if time_seen > time_last_intervention_seen
        last_intervention_seen = intervention_name
        time_last_intervention_seen = time_seen
  return last_intervention_seen

expose_get_auth get_last_intervention_seen, 'userid'

export get_intervention_to_num_times_seen = (user_id) ->>
  collections = await list_intervention_collections_for_user(user_id)
  db = await get_mongo_db()
  output = {}
  for entry in collections
    entry_key = entry.replace(user_id + '_', '')
    collection = db.collection(entry)
    num_items = await n2p -> collection.find({type: 'impression'}).count(it)
    output[entry_key] = num_items
  return output

expose_get_auth get_intervention_to_num_times_seen, 'userid'

export get_last_intervention_seen_and_time = (user_id) ->>
  intervention_to_time_seen = await get_intervention_to_time_most_recently_seen(user_id)
  last_intervention_seen = null
  time_last_intervention_seen = null
  for intervention_name,time_seen of intervention_to_time_seen
    if not last_intervention_seen?
      last_intervention_seen = intervention_name
      time_last_intervention_seen = time_seen
    else
      if time_seen > time_last_intervention_seen
        last_intervention_seen = intervention_name
        time_last_intervention_seen = time_seen
  return {time: time_last_intervention_seen, intervention: last_intervention_seen}

expose_get_auth get_last_intervention_seen_and_time, 'userid'

export get_time_intervention_was_most_recently_seen = (user_id, intervention_name) ->>
  [collection, db] = await get_collection_for_user_and_logname(user_id, intervention_name)
  all_items = await n2p -> collection.find({}).toArray(it)
  highest_timestamp = -1
  for item in all_items
    if item.timestamp > highest_timestamp
      highest_timestamp = item.timestamp
  #ctx.body = JSON.stringify all_items
  db.close()
  return highest_timestamp

export get_is_logging_enabled_for_user = (user_id) ->>
  [collection, db] = await get_logging_states()
  results = await n2p -> collection.find({user_id}, {sort: {timestamp: -1}}).toArray(it)
  db.close()
  return results[0]

expose_get_auth get_is_logging_enabled_for_user, 'userid'

export get_user_to_is_logging_enabled = ->>
  [collection, db] = await get_logging_states()
  results = await n2p -> collection.find({}).toArray(it)
  db.close()
  user_to_is_logging_enabled = {}
  user_to_latest_timestamp = {}
  for item in results
    {user_id, timestamp, logging_enabled} = item
    if not user_to_latest_timestamp[user_id]?
      user_to_latest_timestamp[user_id] = timestamp
      user_to_is_logging_enabled[user_id] = logging_enabled
    if timestamp > user_to_latest_timestamp[user_id]
      user_to_latest_timestamp[user_id] = timestamp
      user_to_is_logging_enabled[user_id] = logging_enabled
  return user_to_is_logging_enabled

expose_get_auth get_user_to_is_logging_enabled

export get_interventions_disabled_for_user = (user_id) ->>
  [collection, db] = await get_collection_for_user_and_logname(user_id, 'synced:interventions_currently_disabled')
  output = {}
  results = await n2p -> collection.find({}).toArray(it)
  # we assume that results is chronologically ordered, will need to sort by .timestamp if not
  for item in results
    intervention_name = item.key
    is_disabled = item.val
    output[intervention_name] = is_disabled
  return output

expose_get_auth get_interventions_disabled_for_user, 'userid'

export get_last_interventions_for_former_users = ->>
  output = {}
  former_users = await get_users_with_logs_who_are_no_longer_active()
  for user_id in former_users
    last_intervention = await get_last_intervention_seen(user_id)
    if not output[last_intervention]?
      output[last_intervention] = 1
    else
      output[last_intervention] += 1
  return output

expose_get_auth get_last_interventions_for_former_users

export get_users_with_logs_who_are_no_longer_active = ->>
  user_to_is_logging_enabled = await get_user_to_is_logging_enabled()
  active_users = await list_active_users_week()
  active_users_set = {}
  for user_id in active_users
    active_users_set[user_id] = true
  output = []
  for user_id in Object.keys(user_to_is_logging_enabled)
    logging_enabled = user_to_is_logging_enabled[user_id]
    if not logging_enabled
      continue
    if active_users_set[user_id]
      continue
    output.push(user_id)
  output.sort()
  return output

expose_get_auth get_users_with_logs_who_are_no_longer_active

export get_last_interventions_and_num_impressions_for_former_users = ->>
  intervention_to_num_last = {}
  intervention_to_total_impressions = {}
  former_users = await get_users_with_logs_who_are_no_longer_active()
  for user_id in former_users
    last_intervention = await get_last_intervention_seen(user_id)
    intervention_to_num_impressions = await get_intervention_to_num_times_seen(user_id)
    for intervention_name in Object.keys(intervention_to_num_impressions)
      if not intervention_to_total_impressions[intervention_name]?
        intervention_to_total_impressions[intervention_name] = 0
      intervention_to_total_impressions[intervention_name] += intervention_to_num_impressions[intervention_name]
    if not intervention_to_num_last[last_intervention]?
      intervention_to_num_last[last_intervention] = 1
    else
      intervention_to_num_last[last_intervention] += 1
  output = {}
  for intervention_name in Object.keys(intervention_to_total_impressions)
    num_last = intervention_to_num_last[intervention_name]
    if not num_last?
      num_last = 0
    total_impressions = intervention_to_total_impressions[intervention_name]
    uninstall_fraction = num_last / total_impressions
    output[intervention_name] = {
      num_last: num_last,
      total_impressions: total_impressions,
      uninstall_fraction: uninstall_fraction
    }
  return output

expose_get_auth get_last_interventions_and_num_impressions_for_former_users

export get_web_visit_actions = ->>
  [webvisits, db] = await get_webvisits()
  all_results = await n2p -> webvisits.find({}).toArray(it)
  db.close()
  return all_results

expose_get_auth get_web_visit_actions

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

app.get '/get_user_to_dates_active', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [user_active_dates, db] = await get_user_active_dates()
    all_results = await n2p -> user_active_dates.find({}).toArray(it)
    output = {}
    for {day, user} in all_results
      if not output[user]?
        output[user] = []
      output[user].push day
    ctx.body = JSON.stringify output
  catch err
    console.log 'error in get_user_active_dates'
    console.log err
  finally
    db?close()

app.get '/get_dates_active_for_user', auth, (ctx) ->>
  ctx.type = 'json'
  {userid} = ctx.request.query
  if need_query_property(ctx, 'userid')
    return
  try
    [user_active_dates, db] = await get_user_active_dates()
    all_results = await n2p -> user_active_dates.find({user: userid}).toArray(it)
    output = []
    for {day} in all_results
      output.push(day)
    ctx.body = JSON.stringify output
  catch err
    console.log 'error in get_user_active_dates'
    console.log err
  finally
    db?close()

app.get '/get_dates_to_users_active', auth, (ctx) ->>
  ctx.type = 'json'
  try
    [user_active_dates, db] = await get_user_active_dates()
    all_results = await n2p -> user_active_dates.find({}).toArray(it)
    output = {}
    for {day, user} in all_results
      if not output[day]?
        output[day] = []
      output[day].push user
    ctx.body = JSON.stringify output
  catch err
    console.log 'error in get_user_active_dates'
    console.log err
  finally
    db?close()

export list_active_users_week = ->>
  [user_active_dates, db] = await get_user_active_dates()
  all_results = await n2p -> user_active_dates.find({}).toArray(it)
  db.close()
  active_users_set = {}
  active_users_list = []
  past_seven_days = [moment().subtract(daynum, 'days').format('YYYYMMDD') for daynum from 0 til 7]
  for {day, user} in all_results
    if active_users_set[user]?
      continue
    if not past_seven_days.includes(day)
      continue
    active_users_set[user] = true
    active_users_list.push(user)
  return active_users_list

app.get '/getactiveusers_week', auth, (ctx) ->>
  ctx.type = 'json'
  output = await list_active_users_week()
  ctx.body = JSON.stringify output

app.get '/get_daily_active_counts', auth, (ctx) ->>
  ctx.type = 'json'
  users = []
  users_set = {}
  now = Date.now()
  secs_in_day = 86400000
  collections = await list_collections()
  db = await get_mongo_db()
  user_to_days_active = {}
  for entry in collections
    if entry.indexOf('_') == -1
      continue
    entry_parts = entry.split('_')
    userid = entry_parts[0]
    if not user_to_days_active[userid]?
      user_to_days_active[userid] = {}
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
        date = moment(timestamp).format('YYYYMMDD')
        user_to_days_active[userid][date] = true
      #timestamp = prelude.maximum all_items.map (.timestamp)
      #if now - timestamp < secs_in_day
      #  if not users_set[userid]?
      #    users.push userid
      #    users_set[userid] = true
  day_to_users_active = {}
  for userid,days_active of user_to_days_active
    for date in Object.keys(days_active)
      if not day_to_users_active[date]?
        day_to_users_active[date] = 0
      day_to_users_active[date] += 1
  ctx.body = JSON.stringify day_to_users_active
  db.close()
  return

require('libs/globals').add_globals(module.exports)