(function(){
  var ref$, prelude, app, auth, get_mongo_db, get_collection, get_signups, get_secrets, get_logging_states, get_installs, get_uninstalls, get_uninstall_feedback, list_collections, list_log_collections_for_user, list_log_collections_for_logname, get_collection_for_user_and_logname, slice$ = [].slice;
  ref$ = require('./server_common'), prelude = ref$.prelude, app = ref$.app, auth = ref$.auth, get_mongo_db = ref$.get_mongo_db, get_collection = ref$.get_collection, get_signups = ref$.get_signups, get_secrets = ref$.get_secrets, get_logging_states = ref$.get_logging_states, get_installs = ref$.get_installs, get_uninstalls = ref$.get_uninstalls, get_uninstall_feedback = ref$.get_uninstall_feedback, list_collections = ref$.list_collections, list_log_collections_for_user = ref$.list_log_collections_for_user, list_log_collections_for_logname = ref$.list_log_collections_for_logname, get_collection_for_user_and_logname = ref$.get_collection_for_user_and_logname;
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
  app.get('/get_secrets', auth, function*(){
    var ref$, secrets, db, all_results, err;
    this.type = 'json';
    try {
      ref$ = (yield get_secrets()), secrets = ref$[0], db = ref$[1];
      all_results = (yield function(it){
        return secrets.find({}).toArray(it);
      });
      return this.body = JSON.stringify(all_results);
    } catch (e$) {
      err = e$;
      console.log('error in get_secrets');
      console.log(err);
      return this.body = JSON.stringify({
        response: 'error',
        error: 'error in get_secrets'
      });
    } finally {
      if (db != null) {
        db.close();
      }
    }
  });
  app.get('/get_logging_states', auth, function*(){
    var ref$, logging_states, db, all_results, err;
    this.type = 'json';
    try {
      ref$ = (yield get_logging_states()), logging_states = ref$[0], db = ref$[1];
      all_results = (yield function(it){
        return logging_states.find({}).toArray(it);
      });
      return this.body = JSON.stringify(all_results);
    } catch (e$) {
      err = e$;
      console.log('error in get_logging_states');
      console.log(err);
      return this.body = JSON.stringify({
        response: 'error',
        error: 'error in get_logging_states'
      });
    } finally {
      if (db != null) {
        db.close();
      }
    }
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
}).call(this);
