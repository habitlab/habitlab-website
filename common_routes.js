(function(){
  var app;
  app = require('./server_common').app;
  app.get('/ping', function*(){
    this.body = 'hi';
  });
  app.get('/my_ip_address', function*(){
    this.body = this.request.ip_address_fixed;
  });
}).call(this);
