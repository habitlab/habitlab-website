(function(){
  var express, app, port, ref$;
  express = require('express');
  app = express();
  port = (ref$ = process.env.PORT) != null ? ref$ : 5000;
  app.use(express['static'](__dirname + '/www'));
  app.set('port', port);
  app.listen(app.get('port'));
  console.log("running on port " + port + " visit http://localhost:" + port);
}).call(this);
