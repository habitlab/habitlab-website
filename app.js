(function(){
  var koa, koaStatic, koaRouter, koaLogger, koaBodyparser, koaJsonp, mongodb, getsecret, koaBasicAuth, prelude, kapp, app, auth, ref$, cfy, cfy_node, yfy_node, mongourl, get_mongo_db, get_collection, get_signups, get_installs, get_uninstalls, get_uninstall_feedback, list_collections, list_log_collections_for_user, list_log_collections_for_logname, get_collection_for_user_and_logname, port, slice$ = [].slice;
  process.on('unhandledRejection', function(reason, p){
    throw new Error(reason);
  });
  koa = require('koa');
  koaStatic = require('koa-static');
  koaRouter = require('koa-router');
  koaLogger = require('koa-logger');
  koaBodyparser = require('koa-bodyparser');
  koaJsonp = require('koa-jsonp');
  mongodb = require('mongodb');
  getsecret = require('getsecret');
  koaBasicAuth = require('koa-basic-auth');
  prelude = require('prelude-ls');
  kapp = koa();
  kapp.use(koaJsonp());
  kapp.use(koaLogger());
  kapp.use(koaBodyparser());
  app = koaRouter();
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
  auth = koaBasicAuth({
    name: getsecret('username'),
    pass: getsecret('password')
  });
  ref$ = require('cfy'), cfy = ref$.cfy, cfy_node = ref$.cfy_node, yfy_node = ref$.yfy_node;
  mongourl = (ref$ = process.env.MONGODB_URI) != null ? ref$ : 'mongodb://localhost:27017/default';
  get_mongo_db = cfy(function*(){
    var err;
    try {
      return (yield function(it){
        return mongodb.MongoClient.connect(mongourl, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error getting mongodb');
      console.log(err);
    }
  });
  get_collection = cfy(function*(collection_name){
    var db;
    db = (yield get_mongo_db());
    return [db.collection(collection_name), db];
  });
  get_signups = cfy(function*(){
    return (yield get_collection('signups'));
  });
  get_installs = cfy(function*(){
    return (yield get_collection('installs'));
  });
  get_uninstalls = cfy(function*(){
    return (yield get_collection('uninstalls'));
  });
  get_uninstall_feedback = cfy(function*(){
    return (yield get_collection('uninstall_feedback'));
  });
  list_collections = cfy(function*(){
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
  list_log_collections_for_user = cfy(function*(userid){
    var all_collections;
    all_collections = (yield list_collections());
    return all_collections.filter(function(it){
      return it.startsWith(userid + "_");
    });
  });
  list_log_collections_for_logname = cfy(function*(logname){
    var all_collections;
    all_collections = (yield list_collections());
    return all_collections.filter(function(it){
      return it.endsWith("_" + logname);
    });
  });
  get_collection_for_user_and_logname = cfy(function*(userid, logname){
    return (yield get_collection(userid + "_" + logname));
  });
  app.get('/feedback', auth, function*(){
    var feedback, collections, db, i$, len$, entry, collection, all_items, j$, len1$, item;
    feedback = [];
    collections = (yield list_collections());
    db = (yield get_mongo_db());
    for (i$ = 0, len$ = collections.length; i$ < len$; ++i$) {
      entry = collections[i$];
      if (entry.indexOf('feedback') > -1) {
        collection = db.collection(entry);
        all_items = (yield fn$);
        for (j$ = 0, len1$ = all_items.length; j$ < len1$; ++j$) {
          item = all_items[j$];
          if (item["feedback"] != null) {
            feedback.push(item["feedback"]);
          }
        }
      }
    }
    this.body = JSON.stringify(feedback);
    db.close();
    function fn$(it){
      return collection.find({}, ["feedback"]).toArray(it);
    }
  });
  app.get('/getactiveusers', auth, function*(){
    var users, users_set, now, secs_in_day, collections, db, i$, len$, entry, entry_parts, userid, logname, collection, all_items, timestamp, this$ = this;
    users = [];
    users_set = {};
    now = Date.now();
    secs_in_day = 86400000;
    collections = (yield list_collections());
    db = (yield get_mongo_db());
    for (i$ = 0, len$ = collections.length; i$ < len$; ++i$) {
      entry = collections[i$];
      if (entry.indexOf('_') === -1) {
        continue;
      }
      entry_parts = entry.split('_');
      userid = entry_parts[0];
      logname = slice$.call(entry_parts, 1).join('_');
      if (logname.startsWith('facebook:')) {
        collection = db.collection(entry);
        all_items = (yield fn$);
        timestamp = prelude.maximum(all_items.map(fn1$));
        if (now - timestamp < secs_in_day) {
          if (users_set[userid] == null) {
            users.push(userid);
            users_set[userid] = true;
          }
        }
      }
    }
    this.body = JSON.stringify(users);
    db.close();
    function fn$(it){
      return collection.find({}, ["timestamp"]).toArray(it);
    }
    function fn1$(it){
      return it.timestamp;
    }
  });
  app.get('/add_install', function*(){
    var ref$, installs, db, query, err;
    this.type = 'json';
    try {
      ref$ = (yield get_installs()), installs = ref$[0], db = ref$[1];
      query = import$({}, this.request.query);
      if (query.callback != null) {
        delete query.callback;
      }
      query.timestamp = Date.now();
      query.ip = this.request.ip;
      (yield function(it){
        return installs.insert(query, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in add_install');
      console.log(err);
    } finally {
      if (db != null) {
        db.close();
      }
    }
    return this.body = JSON.stringify({
      response: 'done',
      success: true
    });
  });
  app.post('/add_install', function*(){
    var ref$, installs, db, query, err;
    this.type = 'json';
    try {
      ref$ = (yield get_installs()), installs = ref$[0], db = ref$[1];
      query = import$({}, this.request.body);
      if (query.callback != null) {
        delete query.callback;
      }
      query.timestamp = Date.now();
      query.ip = this.request.ip;
      (yield function(it){
        return installs.insert(query, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in add_install');
      console.log(err);
    } finally {
      if (db != null) {
        db.close();
      }
    }
    return this.body = JSON.stringify({
      response: 'done',
      success: true
    });
  });
  app.get('/add_uninstall', function*(){
    var ref$, uninstalls, db, query, err;
    this.type = 'json';
    try {
      ref$ = (yield get_uninstalls()), uninstalls = ref$[0], db = ref$[1];
      query = import$({}, this.request.query);
      if (query.callback != null) {
        delete query.callback;
      }
      query.timestamp = Date.now();
      query.ip = this.request.ip;
      (yield function(it){
        return uninstalls.insert(query, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in add_uninstall');
      console.log(err);
    } finally {
      if (db != null) {
        db.close();
      }
    }
    return this.body = JSON.stringify({
      response: 'done',
      success: true
    });
  });
  app.get('/add_uninstall_feedback', function*(){
    var ref$, uninstalls, db, query, err;
    this.type = 'json';
    try {
      ref$ = (yield get_uninstall_feedback()), uninstalls = ref$[0], db = ref$[1];
      query = import$({}, this.request.query);
      if (query.callback != null) {
        delete query.callback;
      }
      query.timestamp = Date.now();
      query.ip = this.request.ip;
      (yield function(it){
        return uninstalls.insert(query, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in add_uninstall_feedback');
      console.log(err);
    } finally {
      if (db != null) {
        db.close();
      }
    }
    return this.body = JSON.stringify({
      response: 'done',
      success: true
    });
  });
  app.get('/get_installs', auth, function*(){
    var ref$, installs, db, all_results, err;
    this.type = 'json';
    try {
      ref$ = (yield get_installs()), installs = ref$[0], db = ref$[1];
      all_results = (yield function(it){
        return installs.find({}).toArray(it);
      });
      return this.body = JSON.stringify(all_results);
    } catch (e$) {
      err = e$;
      console.log('error in get_installs');
      console.log(err);
      return this.body = JSON.stringify({
        response: 'error',
        error: 'error in get_installs'
      });
    } finally {
      if (db != null) {
        db.close();
      }
    }
  });
  app.get('/get_uninstalls', auth, function*(){
    var ref$, uninstalls, db, all_results, err;
    this.type = 'json';
    try {
      ref$ = (yield get_uninstalls()), uninstalls = ref$[0], db = ref$[1];
      all_results = (yield function(it){
        return uninstalls.find({}).toArray(it);
      });
      return this.body = JSON.stringify(all_results);
    } catch (e$) {
      err = e$;
      console.log('error in get_uninstalls');
      console.log(err);
      return this.body = JSON.stringify({
        response: 'error',
        error: 'error in get_uninstalls'
      });
    } finally {
      if (db != null) {
        db.close();
      }
    }
  });
  app.get('/get_uninstall_feedback', auth, function*(){
    var ref$, uninstalls, db, all_results, err;
    this.type = 'json';
    try {
      ref$ = (yield get_uninstall_feedback()), uninstalls = ref$[0], db = ref$[1];
      all_results = (yield function(it){
        return uninstalls.find({}).toArray(it);
      });
      return this.body = JSON.stringify(all_results);
    } catch (e$) {
      err = e$;
      console.log('error in get_uninstalls');
      console.log(err);
      return this.body = JSON.stringify({
        response: 'error',
        error: 'error in get_uninstall_feedback'
      });
    } finally {
      if (db != null) {
        db.close();
      }
    }
  });
  app.get('/addsignup', function*(){
    var email, ref$, signups, db, err;
    this.type = 'json';
    email = this.request.query.email;
    if (email == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter email'
      });
      return;
    }
    try {
      ref$ = (yield get_signups()), signups = ref$[0], db = ref$[1];
      (yield function(it){
        return signups.insert(this.request.query, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in addsignup');
      console.log(err);
    } finally {
      if (db != null) {
        db.close();
      }
    }
    return this.body = JSON.stringify({
      response: 'done',
      success: true
    });
  });
  app.post('/addsignup', function*(){
    var email, ref$, signups, db, err;
    this.type = 'json';
    email = this.request.body.email;
    if (email == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter email'
      });
      return;
    }
    try {
      ref$ = (yield get_signups()), signups = ref$[0], db = ref$[1];
      (yield function(it){
        return signups.insert(this.request.body, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in addsignup');
      console.log(err);
    } finally {
      if (db != null) {
        db.close();
      }
    }
    return this.body = JSON.stringify({
      response: 'success',
      success: true
    });
  });
  app.get('/getsignups', auth, function*(){
    var ref$, signups, db, all_results, x, err;
    this.type = 'json';
    try {
      ref$ = (yield get_signups()), signups = ref$[0], db = ref$[1];
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
    } catch (e$) {
      err = e$;
      console.log('error in getsignups');
      console.log(err);
      return this.body = JSON.stringify({
        response: 'error',
        error: 'error in getsignups'
      });
    } finally {
      if (db != null) {
        db.close();
      }
    }
  });
  app.get('/list_logs_for_user', auth, function*(){
    var userid, user_collections;
    this.type = 'json';
    userid = this.request.query.userid;
    if (userid == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter userid'
      });
      return;
    }
    user_collections = (yield list_log_collections_for_user(userid));
    return this.body = JSON.stringify(user_collections);
  });
  app.get('/list_logs_for_logname', auth, function*(){
    var logname, user_collections;
    this.type = 'json';
    logname = this.request.query.logname;
    if (logname == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter logname'
      });
      return;
    }
    user_collections = (yield list_log_collections_for_logname(logname));
    return this.body = JSON.stringify(user_collections);
  });
  app.get('/printcollection', auth, function*(){
    var ref$, collection, userid, logname, collection_name, db, items, err;
    ref$ = this.request.query, collection = ref$.collection, userid = ref$.userid, logname = ref$.logname;
    if (userid != null && logname != null) {
      collection = userid + "_" + logname;
    }
    if (collection == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need paramter collection'
      });
    }
    collection_name = collection;
    try {
      ref$ = (yield get_collection(collection_name)), collection = ref$[0], db = ref$[1];
      items = (yield function(it){
        return collection.find({}).toArray(it);
      });
      return this.body = JSON.stringify(items);
    } catch (e$) {
      err = e$;
      console.log('error in printcollection');
      console.log(err);
      return this.body = JSON.stringify({
        response: 'error',
        error: 'error in printcollection'
      });
    } finally {
      if (db != null) {
        db.close();
      }
    }
  });
  app.get('/listcollections', auth, function*(){
    this.type = 'json';
    return this.body = JSON.stringify((yield list_collections()));
  });
  app.post('/sync_collection_item', function*(){
    var ref$, userid, collection, collection_name, db, err;
    this.type = 'json';
    ref$ = this.request.body, userid = ref$.userid, collection = ref$.collection;
    collection_name = collection;
    if (userid == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter userid'
      });
      return;
    }
    if (collection_name == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter collection'
      });
      return;
    }
    try {
      ref$ = (yield get_collection_for_user_and_logname(userid, 'synced:' + collection_name)), collection = ref$[0], db = ref$[1];
      (yield function(it){
        return collection.insert(this.request.body, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in sync_collection_item');
      console.log(err);
    } finally {
      if (db != null) {
        db.close();
      }
    }
    return this.body = JSON.stringify({
      response: 'success',
      success: true
    });
  });
  app.post('/addtolog', function*(){
    var ref$, userid, logname, itemid, collection, db, err;
    this.type = 'json';
    ref$ = this.request.body, userid = ref$.userid, logname = ref$.logname, itemid = ref$.itemid;
    logname = logname.split('/').join(':');
    if (userid == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter userid'
      });
      return;
    }
    if (logname == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter logname'
      });
      return;
    }
    if (itemid == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter itemid'
      });
      return;
    }
    if (itemid.length !== 24) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'itemid length needs to be 24'
      });
      return;
    }
    try {
      ref$ = (yield get_collection_for_user_and_logname(userid, logname)), collection = ref$[0], db = ref$[1];
      this.request.body._id = mongodb.ObjectId.createFromHexString(itemid);
      (yield function(it){
        return collection.insert(this.request.body, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in addtolog');
      console.log(err);
    } finally {
      if (db != null) {
        db.close();
      }
    }
    return this.body = JSON.stringify({
      response: 'success',
      success: true
    });
  });
  kapp.use(app.routes());
  kapp.use(app.allowedMethods());
  kapp.use(koaStatic(__dirname + '/www'));
  port = (ref$ = process.env.PORT) != null ? ref$ : 5000;
  kapp.listen(port);
  console.log("listening to port " + port + " visit http://localhost:" + port);
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
