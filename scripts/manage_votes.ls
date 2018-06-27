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

export get_collection_goal_idea_vote_logs = ->>
  return await get_collection('get_collection_goal_idea_vote_logs')

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
  await keep_trying -> ideas.insert({goal, idea, vote: 0, lostvote: 0}, it)
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

initialize = ->>
  for goal in Object.keys(goal_to_ideas)
    ideas = goal_to_ideas[goal]
    console.log ideas
    for idea in ideas
      await post_idea goal, idea
  return

clearvotes = ->>
  ideas = await get_collection_goal_ideas()
  await keep_trying -> ideas.updateMany({}, {$set: {vote: 0, lostvote: 0}}, it)
  return

clearvotelogs = ->>
  votelogs = await get_collection_goal_idea_vote_logs()
  await votelogs.remove({})
  return

do ->>
  argv = require('yargs')
  .option('initialize', {
    describe: 'post initial set of ideas'
    default: false
  })
  .option('clearvotes', {
    describe: 'resets the existing set of votes'
    default: false
  })
  .option('clearvotelogs', {
    describe: 'clears the existing set of vote logs'
    default: false
  })
  #.option('fresh', {
  #  describe: 'perform a fresh sync (deleting the listcio )'
  #})
  .strict()
  .argv
  if argv.initialize
    await initialize()
  else if argv.clearvotes
    await clearvotes()
  else
    console.log('no command was provided')
  process.exit()
