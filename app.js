(function(){
  var koa, koaStatic, koaRouter, koaLogger, koaBodyparser, kapp, app, MongoClient, ref$, cfy, cfy_node, yfy_node, get_db, get_signups_collection, port;
  process.on('unhandledRejection', function(reason, p){
    throw new Error(reason);
  });
  koa = require('koa');
  koaStatic = require('koa-static');
  koaRouter = require('koa-router');
  koaLogger = require('koa-logger');
  koaBodyparser = require('koa-bodyparser');
  kapp = koa();
  kapp.use(koaLogger());
  kapp.use(koaBodyparser());
  app = koaRouter();
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
  app.get('/addsignup', function*(){
    var email, signups, result;
    email = this.request.query.email;
    if (email == null) {
      this.body = 'need email parameter';
      return;
    }
    signups = (yield get_signups_collection());
    result = (yield function(it){
      return signups.insertOne(this.request.query, {}, it);
    });
    return this.body = 'done adding ' + email;
  });
  app.post('/addsignup', function*(){
    var email, signups, result;
    email = this.request.body.email;
    if (email == null) {
      this.body = 'need email parameter';
      return;
    }
    signups = (yield get_signups_collection());
    result = (yield function(it){
      return signups.insertOne(this.request.body, {}, it);
    });
    return this.body = 'done adding ' + email;
  });
  app.get('/getsignups', function*(){
    var signups, all_results, x;
    signups = (yield get_signups_collection());
    all_results = (yield function(it){
      return signups.find({}).toArray(it);
    });
    return this.body = JSON.stringify((yield* (function*(){
      var i$, ref$, len$, results$ = [];
      for (i$ = 0, len$ = (ref$ = all_results).length; i$ < len$; ++i$) {
        x = ref$[i$];
        results$.push(x.email);
      }
      return results$;
    }())));
  });
  app.get('/addlog', function*(){
    return this.body = 'addtolog called';
  });
  kapp.use(app.routes());
  kapp.use(app.allowedMethods());
  kapp.use(koaStatic(__dirname + '/www'));
  port = (ref$ = process.env.PORT) != null ? ref$ : 5000;
  kapp.listen(port);
  console.log("listening to port " + port + " visit http://localhost:" + port);
}).call(this);
