{
  app
} = require 'libs/server_common'

app.get '/ping', ->*
  this.body = 'hi'
  return

app.get '/my_ip_address', ->*
  #this.body = this.request.ip
  this.body = this.request.ip_address_fixed
  return

app.get '/log_error', ->*
  console.error 'an error should be logged'
  this.body = 'hi'
  return

app.get '/throw_error', ->*
  throw new Error('stuff is broken')
  this.body = 'hi'
  return
