(function(){
  var express, MongoClient, ref$, cfy, cfy_node, yfy_node, getDb, getSignupsCollection, app, port;
  process.on('unhandledRejection', function(reason, p){
    throw new Error(reason);
  });
  express = require('express');
  MongoClient = require('mongodb').MongoClient;
  ref$ = require('cfy'), cfy = ref$.cfy, cfy_node = ref$.cfy_node, yfy_node = ref$.yfy_node;
  getDb = cfy(function*(){
    var mongourl, ref$, db;
    mongourl = (ref$ = process.env.MONGODB_URI) != null ? ref$ : 'mongodb://localhost:27017/default';
    db = (yield yfy_node(MongoClient.connect)(mongourl));
    return db;
  });
  getSignupsCollection = cfy(function*(){
    var db;
    db = (yield getDb());
    return db.collection('signups');
  });
  app = express();
  port = (ref$ = process.env.PORT) != null ? ref$ : 5000;
  app.use(express['static'](__dirname + '/www'));
  app.set('port', port);
  app.get('/addsignup', function(req, res){
    var email;
    email = req.query.email;
    if (email == null) {
      res.send('need email parameter');
      return;
    }
    return getSignupsCollection(function(signups){
      return signups.insertOne(req.query, {}, function(err, result){
        res.send('done adding ' + email);
      });
    });
  });
  app.post('/addsignup', function(req, res){
    var email;
    email = req.body.email;
    if (email == null) {
      res.send('need email parameter');
      return;
    }
    return getSignupsCollection(function(signups){
      return signups.insertOne(req.body, {}, function(err, result){
        res.send('done adding ' + email);
      });
    });
  });
  app.get('/getsignups', cfy(function*(req, res, next){
    return getSignupsCollection(function(signups){
      return signups.find({}).toArray(function(err, all_results){
        var x;
        res.send(JSON.stringify((function(){
          var i$, ref$, len$, results$ = [];
          for (i$ = 0, len$ = (ref$ = all_results).length; i$ < len$; ++i$) {
            x = ref$[i$];
            results$.push(x.email);
          }
          return results$;
        }())));
      });
    });
  }));
  app.get('/addlog', cfy(function*(req, res, next){
    res.send('addtolog called');
  }));
  app.listen(app.get('port'));
  console.log("running on port " + port + " visit http://localhost:" + port);
}).call(this);
