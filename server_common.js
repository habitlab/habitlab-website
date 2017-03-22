(function(){
  var koa, koaStatic, koaRouter, koaLogger, koaBodyparser, koaJsonp, mongodb, getsecret, koaBasicAuth, prelude, kapp, app, auth, ref$, cfy, cfy_node, yfy_node, mongourl, get_mongo_db, get_collection, get_signups, get_secrets, get_logging_states, get_installs, get_uninstalls, get_uninstall_feedback, list_collections, list_log_collections_for_user, list_log_collections_for_logname, get_collection_for_user_and_logname, out$ = typeof exports != 'undefined' && exports || this;
  koa = require('koa');
  koaStatic = require('koa-static');
  koaRouter = require('koa-router');
  koaLogger = require('koa-logger');
  koaBodyparser = require('koa-bodyparser');
  koaJsonp = require('koa-jsonp');
  mongodb = require('mongodb');
  getsecret = require('getsecret');
  koaBasicAuth = require('koa-basic-auth');
  out$.mongodb = mongodb;
  out$.prelude = prelude = require('prelude-ls');
  out$.kapp = kapp = koa();
  kapp.use(koaJsonp());
  kapp.use(koaLogger());
  kapp.use(koaBodyparser());
  out$.app = app = koaRouter();
  if (getsecret('username') != null || getsecret('password') != null) {
    app.use(function*(next){
      var err;
      try {
        return (yield next);
      } catch (e$) {
        err = e$;
        if (401 === err.status) {
          this.status = 401;
          this.set('WWW-Authenticate', 'Basic');
          return this.body = 'Authentication failed';
        } else {
          throw err;
        }
      }
    });
    out$.auth = auth = koaBasicAuth({
      name: getsecret('username'),
      pass: getsecret('password')
    });
  } else {
    out$.auth = auth = function*(next){
      return (yield next);
    };
  }
  import$(out$, (ref$ = require('cfy'), cfy = ref$.cfy, cfy_node = ref$.cfy_node, yfy_node = ref$.yfy_node, ref$));
  out$.mongourl = mongourl = (ref$ = getsecret('MONGODB_URI')) != null ? ref$ : 'mongodb://localhost:27017/default';
  out$.get_mongo_db = get_mongo_db = cfy(function*(){
    var err;
    try {
      return (yield function(it){
        return mongodb.MongoClient.connect(mongourl, it);
      });
    } catch (e$) {
      err = e$;
      console.error('error getting mongodb');
      console.error(err);
    }
  });
  out$.get_collection = get_collection = cfy(function*(collection_name){
    var db;
    db = (yield get_mongo_db());
    return [db.collection(collection_name), db];
  });
  out$.get_signups = get_signups = cfy(function*(){
    return (yield get_collection('signups'));
  });
  out$.get_secrets = get_secrets = cfy(function*(){
    return (yield get_collection('secrets'));
  });
  out$.get_logging_states = get_logging_states = cfy(function*(){
    return (yield get_collection('logging_states'));
  });
  out$.get_installs = get_installs = cfy(function*(){
    return (yield get_collection('installs'));
  });
  out$.get_uninstalls = get_uninstalls = cfy(function*(){
    return (yield get_collection('uninstalls'));
  });
  out$.get_uninstall_feedback = get_uninstall_feedback = cfy(function*(){
    return (yield get_collection('uninstall_feedback'));
  });
  out$.list_collections = list_collections = cfy(function*(){
    var ndb, collections_list, this$ = this;
    ndb = (yield get_mongo_db());
    collections_list = (yield function(it){
      return ndb.listCollections().toArray(it);
    });
    ndb.close();
    return collections_list.map(function(it){
      return it.name;
    });
  });
  out$.list_log_collections_for_user = list_log_collections_for_user = cfy(function*(userid){
    var all_collections;
    all_collections = (yield list_collections());
    return all_collections.filter(function(it){
      return it.startsWith(userid + "_");
    });
  });
  out$.list_log_collections_for_logname = list_log_collections_for_logname = cfy(function*(logname){
    var all_collections;
    all_collections = (yield list_collections());
    return all_collections.filter(function(it){
      return it.endsWith("_" + logname);
    });
  });
  out$.get_collection_for_user_and_logname = get_collection_for_user_and_logname = cfy(function*(userid, logname){
    return (yield get_collection(userid + "_" + logname));
  });
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
