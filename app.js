(function(){
  var ref$, kapp, app, auth, levn, getsecret, bluebird, fs, roles_list, roles, i$, len$, role, port;
  process.on('unhandledRejection', function(reason, p){
    throw new Error(reason);
  });
  require('app-module-path').addPath(__dirname);
  ref$ = require('libs/server_common'), kapp = ref$.kapp, app = ref$.app, auth = ref$.auth;
  levn = require('levn');
  getsecret = require('getsecret');
  bluebird = require('bluebird');
  fs = bluebird.promisifyAll(require('fs'));
  roles_list = ['logging', 'viewdata'];
  if (getsecret('roles') != null) {
    roles_list = levn.parse('[String]', getsecret('roles'));
  }
  roles = {};
  for (i$ = 0, len$ = roles_list.length; i$ < len$; ++i$) {
    role = roles_list[i$];
    roles[role] = true;
  }
  app.use(function*(next){
    var ip_addr, list;
    ip_addr = this.request.headers["x-forwarded-for"];
    if (ip_addr) {
      list = ip_addr.split(",");
      ip_addr = list[list.length - 1];
    } else {
      ip_addr = this.request.ip;
    }
    this.request.ip_address_fixed = ip_addr;
    return (yield next);
  });
  if (roles.https != null) {
    app.use(require('koa-sslify')({
      trustProtoHeader: true
    }));
  }
  require('routes/common_routes');
  require('routes/intervention_routes');
  if (roles.logging != null) {
    require('routes/logging_routes');
  }
  if (roles.viewdata != null) {
    require('routes/viewdata_routes');
    require('routes/webpage_routes');
  }
  kapp.use(app.routes());
  kapp.use(app.allowedMethods());
  if (roles.viewdata != null) {
    app.get('/installs', auth, function*(){
      var index_contents;
      index_contents = (yield fs.readFileAsync(__dirname + '/www/installs.html', 'utf-8'));
      return this.body = index_contents;
    });
    kapp.use(require('koa-static')(__dirname + '/www'));
  }
  port = (ref$ = process.env.PORT) != null ? ref$ : 5000;
  kapp.listen(port);
  console.log("listening to port " + port + " visit http://localhost:" + port);
}).call(this);
