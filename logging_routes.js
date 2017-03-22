(function(){
  var ref$, app, get_collection, get_signups, get_secrets, get_logging_states, get_installs, get_uninstalls, get_uninstall_feedback, list_collections, list_log_collections_for_user, list_log_collections_for_logname, get_collection_for_user_and_logname;
  ref$ = require('./server_common'), app = ref$.app, get_collection = ref$.get_collection, get_signups = ref$.get_signups, get_secrets = ref$.get_secrets, get_logging_states = ref$.get_logging_states, get_installs = ref$.get_installs, get_uninstalls = ref$.get_uninstalls, get_uninstall_feedback = ref$.get_uninstall_feedback, list_collections = ref$.list_collections, list_log_collections_for_user = ref$.list_log_collections_for_user, list_log_collections_for_logname = ref$.list_log_collections_for_logname, get_collection_for_user_and_logname = ref$.get_collection_for_user_and_logname;
  app.post('/add_secret', function*(){
    var ref$, secrets, db, query, user_id, user_secret, err;
    this.type = 'json';
    try {
      ref$ = (yield get_secrets()), secrets = ref$[0], db = ref$[1];
      query = import$({}, this.request.body);
      if (query.callback != null) {
        delete query.callback;
      }
      user_id = query.user_id, user_secret = query.user_secret;
      query.timestamp = Date.now();
      query.ip = this.request.ip;
      if (user_id == null) {
        this.body = JSON.stringify({
          response: 'error',
          error: 'Need user_id'
        });
        return;
      }
      if (user_secret == null) {
        this.body = JSON.stringify({
          response: 'error',
          error: 'Need user_secret'
        });
        return;
      }
      if ((yield secrets.findOne({
        'user_id': user_id
      })) != null) {
        this.body = JSON.stringify({
          response: 'error',
          error: 'Already have set user_secret for user_id'
        });
        return;
      }
      (yield function(it){
        return secrets.insert(query, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in add_secret');
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
  app.post('/add_logging_state', function*(){
    var ref$, logging_states, db, query, err;
    this.type = 'json';
    try {
      ref$ = (yield get_logging_states()), logging_states = ref$[0], db = ref$[1];
      query = import$({}, this.request.body);
      if (query.callback != null) {
        delete query.callback;
      }
      query.timestamp = Date.now();
      query.ip = this.request.ip;
      (yield function(it){
        return logging_states.insert(query, it);
      });
    } catch (e$) {
      err = e$;
      console.log('error in add_logging_state');
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
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
