(function(){
  var koa, koaStatic, koaRouter, koaLogger, koaBodyparser, monk, kapp, app, ref$, cfy, cfy_node, yfy_node, mongourl, db, signups, port;
  process.on('unhandledRejection', function(reason, p){
    throw new Error(reason);
  });
  koa = require('koa');
  koaStatic = require('koa-static');
  koaRouter = require('koa-router');
  koaLogger = require('koa-logger');
  koaBodyparser = require('koa-bodyparser');
  monk = require('monk');
  kapp = koa();
  kapp.use(koaLogger());
  kapp.use(koaBodyparser());
  app = koaRouter();
  ref$ = require('cfy'), cfy = ref$.cfy, cfy_node = ref$.cfy_node, yfy_node = ref$.yfy_node;
  mongourl = (ref$ = process.env.MONGODB_URI) != null ? ref$ : 'mongodb://localhost:27017/default';
  db = monk(mongourl);
  signups = db.get('signups');
  app.get('/addsignup', function*(){
    var email, result;
    email = this.request.query.email;
    if (email == null) {
      this.body = 'need email parameter';
      return;
    }
    result = (yield signups.insert(this.request.query));
    return this.body = 'done adding ' + email;
  });
  app.post('/addsignup', function*(){
    var email, result;
    email = this.request.body.email;
    if (email == null) {
      this.body = 'need email parameter';
      return;
    }
    result = (yield signups.insert(this.request.body));
    return this.body = 'done adding ' + email;
  });
  app.get('/getsignups', function*(){
    var all_results, x;
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
