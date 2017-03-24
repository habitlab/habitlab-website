(function(){
  var ref$, app, auth, querystring;
  ref$ = require('libs/server_common'), app = ref$.app, auth = ref$.auth;
  querystring = require('querystring');
  app.get('/viewlogs', auth, function*(){
    var ref$, user_id, userid;
    ref$ = this.request.query, user_id = ref$.user_id, userid = ref$.userid;
    userid == null && (userid = user_id);
    return this.response.redirect('/dashboard.html?' + querystring.stringify({
      userid: userid
    }));
  });
}).call(this);
