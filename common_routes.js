(function(){
  var app;
  app = require('./server_common').app;
  app.get('/ping', function*(){
    this.body = 'hi';
  });
}).call(this);
