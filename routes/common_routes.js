(function(){
  var app;
  app = require('libs/server_common').app;
  app.get('/ping', function*(){
    this.body = 'hi';
  });
  app.get('/my_ip_address', function*(){
    this.body = this.request.ip_address_fixed;
  });
  app.get('/log_error', function*(){
    console.error('an error should be logged');
    this.body = 'hi';
  });
  app.get('/throw_error', function*(){
    throw new Error('stuff is broken');
    this.body = 'hi';
  });
}).call(this);
