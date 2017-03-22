{
  app
} = require './server_common'

app.get '/ping', ->*
  this.body = 'hi'
  return

app.get '/my_ip_address', ->*
  #this.body = this.request.ip
  this.body = this.request.ip_address_fixed
  return
