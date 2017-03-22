(function(){
  var ref$, kapp, app, levn, getsecret, roles_list, roles, i$, len$, role, koaStatic, port;
  process.on('unhandledRejection', function(reason, p){
    throw new Error(reason);
  });
  ref$ = require('./server_common'), kapp = ref$.kapp, app = ref$.app;
  levn = require('levn');
  getsecret = require('getsecret');
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
  require('./common_routes');
  if (roles.logging != null) {
    require('./logging_routes');
  }
  if (roles.viewdata != null) {
    require('./viewdata_routes');
  }
  kapp.use(app.routes());
  kapp.use(app.allowedMethods());
  koaStatic = require('koa-static');
  kapp.use(koaStatic(__dirname + '/www'));
  port = (ref$ = process.env.PORT) != null ? ref$ : 5000;
  kapp.listen(port);
  console.log("listening to port " + port + " visit http://localhost:" + port);
}).call(this);
