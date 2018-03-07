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
        readPreference: mongodb.ReadPreference.SECONDARY_PREFERRED,
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
        readPreference: mongodb.ReadPreference.SECONDARY_PREFERRED,
        w: 0,
      },
      it
    )
    return local_cache_db2
  catch err
    console.error 'error getting mongodb2'
    console.error err
    return

sync_all_in_collection = (collection_name, db_src, db_dst) ->>
  c_src = db_src.collection(collection_name)
  c_dst = db_dst.collection(collection_name)
  all_items_src = await n2p -> c_src.find({}).toArray(it)
  if all_items_src.length == 0
    return
  all_ids_dst = await n2p -> c_dst.find({}, {_id: 1}).toArray(it)
  all_ids_dst = all_ids_dst.map((._id)).map((.toString!))
  dst_id_set = new Set(all_ids_dst)
  all_items_which_need_to_be_inserted = all_items_src.filter((x) -> not dst_id_set.has(x._id.toString()))
  console.log 'inserting ' + all_items_which_need_to_be_inserted.length + ' items'
  if all_items_which_need_to_be_inserted.length == 0
    return
  await n2p -> c_dst.insertMany(all_items_which_need_to_be_inserted, it)

do ->>
  db_src = await get_mongo_db()
  db_dst = await get_mongo_db2()
  all_collections = JSON.parse(fs.readFileSync('listcollections', 'utf-8'))
  num_to_sync = all_collections.length
  storage.initSync()
  num_threads = 4
  start_thread = (threadnum) ->>
    for x,idx in all_collections
      if idx % num_threads != threadnum
        continue
      if storage.getItemSync(x)
        console.log '' + (idx) + '/' + num_to_sync + ' thread ' + threadnum + ' already synced ' + x
        continue
      console.log '' + (idx) + '/' + num_to_sync + ' thread ' + threadnum + ' syncing ' + x
      await sync_all_in_collection x, db_src, db_dst
      storage.setItemSync(x, true)
  for threadnum from 0 til num_threads
    start_thread threadnum
