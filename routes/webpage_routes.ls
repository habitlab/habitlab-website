{
  app
  auth
} = require 'libs/server_common'

require! {
  querystring
}

app.get '/viewlogs', auth, (ctx) ->>
  {user_id, userid} = ctx.request.query
  userid ?= user_id
  ctx.response.redirect('/dashboard.html?' + querystring.stringify({userid}))
