{
  app
  auth
} = require './server_common'

require! {
  querystring
}

app.get '/viewlogs', auth, ->*
  {user_id, userid} = this.request.query
  userid ?= user_id
  this.response.redirect('/dashboard.html?' + querystring.stringify({userid}))
