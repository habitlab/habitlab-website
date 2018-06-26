require! {
  mongodb
  getsecret
  fs
  n2p
}

local_cache_db = null
getdb_running = false

mongourl = getsecret('MONGODB_URI_VOTING')

export get_mongo_db = ->>
  if local_cache_db?
    return local_cache_db
  if getdb_running
    while getdb_running
      await sleep(1)
    while getdb_running or local_cache_db == null
      await sleep(1)
    return local_cache_db
  getdb_running := true
  try
    local_cache_db := await n2p -> mongodb.MongoClient.connect(
      mongourl,
      {},
      it
    )
    return local_cache_db
  catch err
    console.error 'error getting mongodb'
    console.error err
    return

export get_collection = (collection_name) ->>
  db = await get_mongo_db()
  return db.collection(collection_name)

export get_collection_goal_ideas = ->>
  return await get_collection('get_collection_goal_ideas')

export get_collection_goal_idea_candidates = ->>
  return await get_collection('get_collection_goal_idea_candidates')

sleep = (time) ->>
  return new Promise ->
    setTimeout(it, time)

keep_trying = (fn) ->>
  succeeded = false
  while not succeeded
    try
      output = await n2p(fn)
      succeeded = true
    catch error
      console.log error
      await sleep(12000)
  return output

export post_idea = (goal, idea) ->>
  ideas = await get_collection_goal_ideas()
  existing_ideas = await keep_trying -> ideas.find({goal, idea}).toArray(it)
  console.log 'existing ideas'
  console.log existing_ideas
  if existing_ideas.length > 0
    return
  await keep_trying -> ideas.insert({goal, idea}, it)
  return

goal_to_ideas = {
  'facebook/spend_less_time': [
    'Remove the unread notifications icon'
    'Type out your goals for visiting Facebook'
  ],
  #'youtube/spend_less_time': [
  #  ''
  #],
}

do ->>
  for goal in Object.keys(goal_to_ideas)
    ideas = goal_to_ideas[goal]
    console.log ideas
    for idea in ideas
      await post_idea goal, idea
  process.exit()
