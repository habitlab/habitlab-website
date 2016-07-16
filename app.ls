process.on 'unhandledRejection', (reason, p) ->
  throw new Error(reason)

require! {
  express
}

{MongoClient} = require 'mongodb'
{cfy, cfy_node, yfy_node} = require 'cfy'

get_db = cfy ->*
  mongourl = process.env.MONGODB_URI ? 'mongodb://localhost:27017/default'
  db = yield -> MongoClient.connect mongourl, it
  return db

get_signups_collection = cfy ->*
  db = yield get_db()
  return db.collection('signups')

app = express()
port = process.env.PORT ? 5000
app.use express.static(__dirname + '/www')
app.set 'port', port

app.get '/addsignup', cfy (req, res, next) ->*
  {email} = req.query
  if not email?
    res.send 'need email parameter'
    return
  signups = yield get_signups_collection()
  result = yield -> signups.insertOne(req.query, {}, it)
  res.send('done adding ' + email)

app.post '/addsignup', cfy (req, res, next) ->*
  {email} = req.body
  if not email?
    res.send 'need email parameter'
    return
  signups = yield get_signups_collection()
  result = yield -> signups.insertOne(req.body, {}, it)
  res.send('done adding ' + email)

app.get '/getsignups', cfy (req, res, next) ->*
  signups = yield get_signups_collection()
  all_results = yield -> signups.find({}).toArray(it)
  res.send JSON.stringify([x.email for x in all_results])

app.get '/addlog', cfy (req, res, next) ->*
  res.send 'addtolog called'

app.listen(app.get('port'))
console.log "running on port #{port} visit http://localhost:#{port}"
