(function(){
  var express, MongoClient, ref$, cfy, cfy_node, yfy_node, get_db, get_signups_collection, app, port;
  process.on('unhandledRejection', function(reason, p){
    throw new Error(reason);
  });
  express = require('express');
  MongoClient = require('mongodb').MongoClient;
  ref$ = require('cfy'), cfy = ref$.cfy, cfy_node = ref$.cfy_node, yfy_node = ref$.yfy_node;
  get_db = cfy(function*(){
    var mongourl, ref$, db;
    mongourl = (ref$ = process.env.MONGODB_URI) != null ? ref$ : 'mongodb://localhost:27017/default';
    db = (yield function(it){
      return MongoClient.connect(mongourl, it);
    });
    return db;
  });
  get_signups_collection = cfy(function*(){
    var db;
    db = (yield get_db());
    return db.collection('signups');
  });
  app = express();
  port = (ref$ = process.env.PORT) != null ? ref$ : 5000;
  app.use(express['static'](__dirname + '/www'));
  app.set('port', port);
  app.get('/addsignup', cfy(function*(req, res, next){
    var email, signups, result;
    email = req.query.email;
    if (email == null) {
      res.send('need email parameter');
      return;
    }
    signups = (yield get_signups_collection());
    result = (yield function(it){
      return signups.insertOne(req.query, {}, it);
    });
    return res.send('done adding ' + email);
  }));
  app.post('/addsignup', cfy(function*(req, res, next){
    var email, signups, result;
    email = req.body.email;
    if (email == null) {
      res.send('need email parameter');
      return;
    }
    signups = (yield get_signups_collection());
    result = (yield function(it){
      return signups.insertOne(req.body, {}, it);
    });
    return res.send('done adding ' + email);
  }));
  app.get('/getsignups', cfy(function*(req, res, next){
    var signups, all_results, x;
    signups = (yield get_signups_collection());
    all_results = (yield function(it){
      return signups.find({}).toArray(it);
    });
    return res.send(JSON.stringify((yield* (function*(){
      var i$, ref$, len$, results$ = [];
      for (i$ = 0, len$ = (ref$ = all_results).length; i$ < len$; ++i$) {
        x = ref$[i$];
        results$.push(x.email);
      }
      return results$;
    }()))));
  }));
  app.get('/addlog', cfy(function*(req, res, next){
    return res.send('addtolog called');
  }));
  app.listen(app.get('port'));
  console.log("running on port " + port + " visit http://localhost:" + port);
}).call(this);
