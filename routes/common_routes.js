(function(){
  var app, chromeWebStoreItemProperty, semver, appid_to_time_checked, appid_to_last_version;
  app = require('libs/server_common').app;
  chromeWebStoreItemProperty = require('chrome-web-store-item-property');
  semver = require('semver');
  app.get('/ping', function*(){
    this.body = 'hi';
  });
  appid_to_time_checked = {};
  appid_to_last_version = {};
  app.get('/app_version', function*(){
    var appid, time_checked, ref$, current_time, app_info, version;
    this.type = 'json';
    appid = this.request.query.appid;
    if (appid == null) {
      this.body = {
        response: 'error',
        error: 'need appid'
      };
      return;
    }
    if (!(appid === 'obghclocpdgcekcognpkblghkedcpdgd' || appid === 'bleifeoekkfhicamkpadfoclfhfmmina')) {
      this.body = {
        response: 'error',
        error: 'appid is not habitlab'
      };
      return;
    }
    time_checked = (ref$ = appid_to_time_checked[appid]) != null ? ref$ : 0;
    current_time = Date.now();
    if (time_checked + 1000 * 60 * 20 > current_time) {
      this.body = {
        response: 'success',
        version: appid_to_last_version[appid]
      };
      return;
    }
    appid_to_time_checked[appid] = Date.now();
    app_info = (yield chromeWebStoreItemProperty(appid));
    version = app_info != null ? app_info.version : void 8;
    if (!version) {
      console.error('got empty version in app_version');
      this.body = {
        response: 'success',
        version: appid_to_last_version[appid]
      };
      return;
    }
    if (!semver.valid(version)) {
      console.error('got invalid version in app_version');
      this.body = {
        response: 'success',
        version: appid_to_last_version[appid]
      };
      return;
    }
    appid_to_last_version[appid] = version;
    this.body = {
      response: 'success',
      version: appid_to_last_version[appid]
    };
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
