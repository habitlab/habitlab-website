require! {
  mongodb
  getsecret
  fs
  n2p
}

storage = require('node-persist')

mongourl = getsecret('MONGODB_SRC')
mongourl2 = getsecret('MONGODB_DST')

local_cache_db = null
getdb_running = false

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
      {
        readPreference: mongodb.ReadPreference.SECONDARY,
        w: 0,
      },
      it
    )
    return local_cache_db
  catch err
    console.error 'error getting mongodb'
    console.error err
    return

local_cache_db2 = null
getdb_running2 = false

export get_mongo_db2 = ->>
  if local_cache_db2?
    return local_cache_db2
  if getdb_running2
    while getdb_running2
      await sleep(1)
    while getdb_running2 or local_cache_db2 == null
      await sleep(1)
    return local_cache_db2
  getdb_running2 := true
  try
    local_cache_db2 := await n2p -> mongodb.MongoClient.connect(
      mongourl2,
      {
        readPreference: mongodb.ReadPreference.SECONDARY,
        w: 0,
      },
      it
    )
    return local_cache_db2
  catch err
    console.error 'error getting mongodb2'
    console.error err
    return

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

sync_all_in_collection = (collection_name, db_src, db_dst) ->>
  c_src = db_src.collection(collection_name)
  c_dst = db_dst.collection(collection_name)
  all_ids_src = await keep_trying -> c_src.find({}, {_id: 1}).toArray(it)
  all_ids_src = all_ids_src.map((._id)) # can be string or object
  #all_ids_src = all_ids_src.map((._id)).map((.toString!))
  if all_ids_src.length == 0
    return
  all_ids_dst = await keep_trying -> c_dst.find({}, {_id: 1}).toArray(it)
  #all_ids_dst = all_ids_dst.map((._id)).map((.toString!))
  all_ids_dst = all_ids_dst.map((._id)) # can be string or object
  all_ids_dst_str = all_ids_dst.map((.toString!))
  dst_id_set = new Set(all_ids_dst_str)
  all_ids_which_need_to_be_inserted = all_ids_src.filter((x) -> not dst_id_set.has(x.toString!)) # can be string or object
  if all_ids_which_need_to_be_inserted.length == 0
    return
  console.log 'incrementally inserting ' + all_ids_which_need_to_be_inserted.length + ' items'
  for idname in all_ids_which_need_to_be_inserted
    item_src = await keep_trying -> c_src.find({_id: idname}).toArray(it)
    if not item_src? # should never happen
      console.log 'could not find item with id ' + idname + ' in collection ' + collection_name
      process.exit()
    await keep_trying -> c_dst.insert(item_src, it)
  return
  /*
  all_items_src = await keep_trying -> c_src.find({}).toArray(it)
  if all_items_src.length == 0
    return
  all_items_which_need_to_be_inserted = all_items_src.filter((x) -> not dst_id_set.has(x._id.toString()))
  if all_items_which_need_to_be_inserted.length == 0
    return
  console.log 'incrementally inserting ' + all_items_which_need_to_be_inserted.length + ' items'
  await keep_trying -> c_dst.insertMany(all_items_which_need_to_be_inserted, it)
  */

sync_all_in_collection_fresh = (collection_name, db_src, db_dst) ->>
  c_src = db_src.collection(collection_name)
  c_dst = db_dst.collection(collection_name)
  all_items_src = await keep_trying -> c_src.find({}).toArray(it)
  if all_items_src.length == 0
    return
  console.log 'freshly inserting ' + all_items_src.length + ' items'
  await keep_trying -> c_dst.insertMany(all_items_src, it)

list_collections = (db_src) ->>
  collections_src = db_src.collection('collections')
  all_items_src = await keep_trying -> collections_src.find({}).toArray(it)
  return all_items_src.map (._id)

do ->>
  db_src = await get_mongo_db()
  db_dst = await get_mongo_db2()
  if not fs.existsSync('listcollections')
    all_collections = await list_collections(db_src)
    fs.writeFileSync('listcollections', JSON.stringify(all_collections), 'utf-8')
  else
    all_collections = JSON.parse(fs.readFileSync('listcollections', 'utf-8'))
  dst_collections = await list_collections(db_dst)
  dst_collections_set = new Set(dst_collections)
  num_to_sync = all_collections.length
  num_threads = 1
  resumable = true
  if resumable
    storage.initSync()
  start_thread = (threadnum) ->>
    for x,idx in all_collections
      if idx % num_threads != threadnum
        continue
      if resumable and storage.getItemSync(x)
        console.log '' + (idx) + '/' + num_to_sync + ' thread ' + threadnum + ' already synced ' + x
        continue
      console.log '' + (idx) + '/' + num_to_sync + ' thread ' + threadnum + ' syncing ' + x
      is_incremental = dst_collections_set.has(x)
      if is_incremental
        await sync_all_in_collection x, db_src, db_dst
      else
        await sync_all_in_collection_fresh x, db_src, db_dst
      if resumable
        storage.setItemSync(x, true)
  for threadnum from 0 til num_threads
    start_thread threadnum
