(function(){
  var koa, koaStatic, koaRouter, koaLogger, koaBodyparser, koaJsonp, monk, kapp, app, ref$, cfy, cfy_node, yfy_node, mongourl, MongoClient, db, signups, get_native_db, list_collections, list_intervention_log_collections_for_user, list_intervention_log_collections_for_intervention, get_intervention_logs_for_user, port;
  process.on('unhandledRejection', function(reason, p){
    throw new Error(reason);
  });
  koa = require('koa');
  koaStatic = require('koa-static');
  koaRouter = require('koa-router');
  koaLogger = require('koa-logger');
  koaBodyparser = require('koa-bodyparser');
  koaJsonp = require('koa-jsonp');
  monk = require('monk');
  kapp = koa();
  kapp.use(koaJsonp());
  kapp.use(koaLogger());
  kapp.use(koaBodyparser());
  app = koaRouter();
  ref$ = require('cfy'), cfy = ref$.cfy, cfy_node = ref$.cfy_node, yfy_node = ref$.yfy_node;
  mongourl = (ref$ = process.env.MONGODB_URI) != null ? ref$ : 'mongodb://localhost:27017/default';
  MongoClient = require('mongodb').MongoClient;
  db = monk(mongourl);
  signups = db.get('signups');
  get_native_db = cfy(function*(){
    return (yield function(it){
      return MongoClient.connect(mongourl, it);
    });
  });
  list_collections = cfy(function*(){
    var ndb, collections_list, this$ = this;
    ndb = (yield get_native_db());
    collections_list = (yield function(it){
      return ndb.listCollections().toArray(it);
    });
    return collections_list.map(function(it){
      return it.name;
    });
  });
  list_intervention_log_collections_for_user = cfy(function*(userid){
    var all_collections;
    all_collections = list_collections();
    return all_collections.filter(function(it){
      return it.startsWith("interventionlog_" + userid + "_");
    });
  });
  list_intervention_log_collections_for_intervention = cfy(function*(intervention){
    var all_collections;
    all_collections = list_collections();
    return all_collections.filter(function(it){
      return it.startsWith("interventionlog_") && it.endsWith("_" + intervention_name);
    });
  });
  get_intervention_logs_for_user = function(userid, intervention_name){
    return db.get("interventionlogs_" + userid + "_" + intervention_name);
  };
  app.get('/addsignup', function*(){
    var email, result;
    this.type = 'json';
    email = this.request.query.email;
    if (email == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter email'
      });
      return;
    }
    result = (yield signups.insert(this.request.query));
    return this.body = JSON.stringify({
      response: 'done',
      success: true
    });
  });
  app.post('/addsignup', function*(){
    var email, result;
    this.type = 'json';
    email = this.request.body.email;
    if (email == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter email'
      });
      return;
    }
    result = (yield signups.insert(this.request.body));
    return this.body = JSON.stringify({
      response: 'success',
      success: true
    });
  });
  app.get('/getsignups', function*(){
    var all_results, x;
    this.type = 'json';
    all_results = (yield signups.find({}));
    return this.body = JSON.stringify((yield* (function*(){
      var i$, ref$, len$, results$ = [];
      for (i$ = 0, len$ = (ref$ = all_results).length; i$ < len$; ++i$) {
        x = ref$[i$];
        results$.push(x.email);
      }
      return results$;
    }())));
  });
  app.get('/get_logs_for_user', function*(){
    var userid, user_collections;
    this.type = 'json';
    userid = this.request.body.userid;
    if (userid == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter userid'
      });
      return;
    }
    user_collections = (yield list_intervention_log_collections_for_user(userid));
    return this.body = JSON.stringify(user_collections);
  });
  app.get('/listcollections', function*(){
    this.type = 'json';
    return this.body = JSON.stringify((yield list_collections()));
  });
  app.post('/add_intervention_log', function*(){
    var ref$, userid, intervention;
    this.type = 'json';
    ref$ = this.request.body, userid = ref$.userid, intervention = ref$.intervention;
    if (userid == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter userid'
      });
      return;
    }
    if (intervention == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter intervention'
      });
      return;
    }
    return this.body = JSON.stringify({
      response: 'error',
      error: 'not yet implemented'
    });
  });
  kapp.use(app.routes());
  kapp.use(app.allowedMethods());
  kapp.use(koaStatic(__dirname + '/www'));
  port = (ref$ = process.env.PORT) != null ? ref$ : 5000;
  kapp.listen(port);
  console.log("listening to port " + port + " visit http://localhost:" + port);
}).call(this);
