{
  app
} = require 'libs/server_common'

require! {
  'chrome-web-store-item-property'
  semver
}

app.get '/ping', ->*
  this.body = 'hi'
  return

appid_to_time_checked = {}
appid_to_last_version = {}

app.get '/app_version', ->*
  this.type = 'json'
  {appid} = this.request.query
  if not appid?
    this.body = {response: 'error', error: 'need appid'}
    return
  if not (appid == 'obghclocpdgcekcognpkblghkedcpdgd' or appid == 'bleifeoekkfhicamkpadfoclfhfmmina')
    this.body = {response: 'error', error: 'appid is not habitlab'}
    return
  time_checked = appid_to_time_checked[appid] ? 0
  current_time = Date.now()
  if time_checked + 1000*60*20 > current_time # within the past 20 minutes
    this.body = {response: 'success', version: appid_to_last_version[appid]}
    return
  appid_to_time_checked[appid] = Date.now()
  app_info = yield chrome-web-store-item-property(appid)
  version = app_info?version
  if not version
    console.error 'got empty version in app_version'
    this.body = {response: 'success', version: appid_to_last_version[appid]}
    return
  if not semver.valid(version)
    console.error 'got invalid version in app_version'
    this.body = {response: 'success', version: appid_to_last_version[appid]}
    return
  appid_to_last_version[appid] = version
  this.body = {response: 'success', version: appid_to_last_version[appid]}
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
