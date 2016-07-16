process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

require! {
  express
}

{MongoClient} = require 'mongodb'
{cfy, cfy_node, yfy_node} = require 'cfy'

getDb = cfy ->*
  mongourl = process.env.MONGODB_URI ? 'mongodb://localhost:27017/default'
  #return mongojs(mongourl, ['signups'])
  db = yield yfy_node(MongoClient.connect) mongourl
  return db

getSignupsCollection = cfy ->*
  db = yield getDb()
  return db.collection('signups')

app = express()
port = process.env.PORT ? 5000
app.use express.static(__dirname + '/www')
app.set 'port', port

app.get '/addsignup', (req, res) ->
  {email} = req.query
  if not email?
    res.send 'need email parameter'
    return
  signups <- getSignupsCollection()
  err,result <- signups.insertOne req.query, {}
  res.send('done adding ' + email)
  return

app.post '/addsignup', (req, res) ->
  {email} = req.body
  if not email?
    res.send 'need email parameter'
    return
  signups <- getSignupsCollection()
  err,result <- signups.insertOne req.body, {}
  res.send('done adding ' + email)
  return

app.get '/getsignups', cfy (req, res, next) ->*
  signups <- getSignupsCollection()
  err,all_results <- signups.find({}).toArray()
  res.send JSON.stringify([x.email for x in all_results])
  return

app.get '/addlog', cfy (req, res, next) ->*
  res.send 'addtolog called'
  return

app.listen(app.get('port'))
console.log "running on port #{port} visit http://localhost:#{port}"
