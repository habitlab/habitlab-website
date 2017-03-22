{
  app
} = require './server_common'

app.get '/ping', ->*
  this.body = 'hi'
  return
