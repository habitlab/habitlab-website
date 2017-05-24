(function(){
  var app, sendgrid, btoa, helper, getsecret, sg, default_from_email, default_to_email, cloudinary, Gitter, gitter, Octokat, octo, ref$, add_noerr, cfy, upload_to_cloudinary, upload_to_cloudinary_json;
  app = require('libs/server_common').app;
  sendgrid = require('sendgrid');
  btoa = require('btoa');
  helper = sendgrid.mail;
  getsecret = require('getsecret');
  sg = sendgrid(getsecret('sendgrid_api_key'));
  default_from_email = getsecret('from_email');
  default_to_email = getsecret('to_email');
  cloudinary = require('cloudinary');
  cloudinary.config({
    cloud_name: getsecret('cloudinary_cloud_name'),
    api_key: getsecret('cloudinary_api_key'),
    api_secret: getsecret('cloudinary_api_secret')
  });
  Gitter = require('node-gitter');
  gitter = new Gitter(getsecret('gitter_api_key'));
  Octokat = require('octokat');
  octo = new Octokat({
    token: getsecret('github_api_key')
  });
  ref$ = require('cfy'), add_noerr = ref$.add_noerr, cfy = ref$.cfy;
  upload_to_cloudinary = cfy(function*(img_data_url){
    var result;
    result = (yield function(it){
      return cloudinary.v2.uploader.upload(img_data_url, {}, it);
    });
    return result.url;
  });
  upload_to_cloudinary_json = cfy(function*(json_data){
    var public_id, i, result;
    public_id = (yield* (function*(){
      var i$, results$ = [];
      for (i$ = 0; i$ < 28; ++i$) {
        i = i$;
        results$.push(Math.floor(Math.random() * 10));
      }
      return results$;
    }())).join('') + '.txt';
    result = (yield function(it){
      return cloudinary.v2.uploader.upload('data:text/plain;base64,' + btoa(JSON.stringify(json_data)), {
        public_id: public_id,
        resource_type: 'raw'
      }, it);
    });
    return result.url;
  });
  app.post('/report_bug', function*(){
    var ref$, message, screenshot, other, user_email, is_gitter, is_github, screenshot_url, extra, err, email_message, data_url, from_email, to_email, title, subject, content, mail, request, sendgrid_response, github_issue_url, github_message, github_title, new_issue, result, gitter_message, room, response_message;
    this.type = 'json';
    ref$ = this.request.body, message = ref$.message, screenshot = ref$.screenshot, other = ref$.other;
    user_email = this.request.body.email;
    is_gitter = this.request.body['gitter'];
    is_github = this.request.body['github'];
    if (message == null) {
      this.body = JSON.stringify({
        response: 'error',
        error: 'need parameter message'
      });
      return;
    }
    screenshot_url = null;
    if (other == null) {
      other = {};
    }
    if (other.extra != null) {
      extra = other.extra;
      delete other.extra;
    } else {
      extra = {};
    }
    extra.ip_address = this.request.ip;
    extra.server_timestamp = Date.now();
    extra.server_localtime = new Date().toString();
    if (screenshot != null) {
      try {
        screenshot_url = (yield upload_to_cloudinary(screenshot));
      } catch (e$) {
        err = e$;
        other.screenshot_upload_error = 'Error occurred while uploading screenshot';
        other.screenshot_upload_error_message = err.toString();
      }
    }
    email_message = message.split('\n').join('<br>');
    if (screenshot_url != null) {
      email_message += '<br><br>' + '<img src="' + screenshot_url + '"></img>';
    }
    if (other != null) {
      email_message += '<br><br><pre>' + jsyaml.safeDump(other) + '</pre>';
    }
    if (extra != null) {
      try {
        data_url = (yield upload_to_cloudinary_json(extra));
        email_message += '<br><br><a href="' + data_url + '">' + data_url + '</a><br><br>';
      } catch (e$) {
        err = e$;
        other.extra_upload_error = 'Error occurred while uploading extra data';
        other.extra_upload_error = err.toString();
      }
    }
    from_email = new helper.Email(default_from_email);
    to_email = new helper.Email(default_to_email);
    title = text_clipper(normalize_space(message), 80);
    subject = '[User Feedback] ' + title;
    content = new helper.Content('text/html', email_message);
    mail = new helper.Mail(from_email, subject, to_email, content);
    if (user_email != null && user_email.length > 0 && user_email.indexOf('@') !== -1 && user_email.indexOf('.') !== -1) {
      if (mail.personalizations == null) {
        mail.personalizations = [];
      }
      mail.personalizations[0].addCc(new helper.Email(user_email));
    }
    request = sg.emptyRequest({
      method: 'POST',
      path: '/v3/mail/send',
      body: mail.toJSON()
    });
    sendgrid_response = (yield function(it){
      return sg.API(request, it);
    });
    github_issue_url = 'https://github.com/habitlab/habitlab/issues/';
    if (is_github) {
      github_message = 'A user submitted the following via HabitLab\'s built-in Feedback form:\n\n' + message.split('\n').join('\n\n');
      if (screenshot_url != null) {
        github_message += '\n\n' + ("<img src=\"" + screenshot_url + "\"></img>");
      }
      if (other != null) {
        github_message += '\n\n```\n' + jsyaml.safeDump(other) + '\n```\n';
      }
      github_title = subject;
      new_issue = {
        title: github_title,
        body: github_message
      };
      result = (yield octo.repos('habitlab', 'habitlab').issues.create(new_issue));
      if (result.htmlUrl != null && result.htmlUrl.startsWith != null && (result.htmlUrl.startsWith('https://github.com/habitlab/habitlab/issues') || result.htmlUrl.startsWith('http://github.com/habitlab/habitlab/issues'))) {
        github_issue_url = result.htmlUrl;
      }
    }
    gitter_message = 'A user submitted the following via HabitLab\'s built-in Feedback form:';
    if (is_github) {
      gitter_message += '\n\nGitHub Issue: ' + ("[" + github_issue_url + "](" + github_issue_url + ")");
    }
    gitter_message += '\n\n' + message.split('\n').join('\n\n');
    if (screenshot_url != null) {
      gitter_message += '\n\n' + ("[" + screenshot_url + "](" + screenshot_url + ")");
    }
    if (other != null) {
      gitter_message += '\n\n```\n' + jsyaml.safeDump(other) + '\n```\n';
    }
    if (is_gitter) {
      room = (yield gitter.rooms.join('habitlab/habitlab'));
      room.send(gitter_message);
    }
    response_message = 'Your message has been sent to <a href="mailto:' + default_to_email + '" target="_blank">' + default_to_email + '</a> <br><br>';
    if (is_gitter) {
      response_message += 'It has also been posted to the support chat at <a href="https://gitter.im/habitlab/habitlab" target="_blank">https://gitter.im/habitlab/habitlab</a> <br><br>';
    } else {
      response_message += 'If you need help, try the support chat at <a href="https://gitter.im/habitlab/habitlab" target="_blank">https://gitter.im/habitlab/habitlab</a> <br><br>';
    }
    if (is_github) {
      response_message += 'You can track progress at <a href="' + github_issue_url + '" target="_blank">' + github_issue_url + '</a> <br><br>';
    }
    return this.body = {
      response: 'success',
      message: response_message
    };
  });
  /*
  app.get '/send_test_gitter', ->*
    this.type = 'json'
    img_url = yield upload_to_cloudinary(img_data_base64)
    room = yield gitter.rooms.join('habitlab/habitlab')
    room.send("""
    Here is a long message.
    And more.
    Multiline supported right?
  
    [#{img_url}](#{img_url})
    """)
    this.body = img_url
  
  # based off https://github.com/habitlab/habitlab-website/blob/master/app.ls
  app.get '/send_test_email', ->*
    this.type = 'json'
    from_email = new helper.Email(default_from_email)
    to_email = new helper.Email(default_to_email)
    subject = 'Hello World from the SendGrid Node.js Library!'
    #var img_data = 'data:image/png;base64,'
    content = new helper.Content('text/html', 'See screenshot below<br><br><img src="cid:screenshot"></img>')
    mail = new helper.Mail(from_email, subject, to_email, content)
  
    attachment = new helper.Attachment()
    attachment.setContent(img_data_base64)
    attachment.setType("image/png")
    attachment.setFilename("screenshot.png")
    attachment.setDisposition("inline")
    attachment.setContentId("screenshot")
    mail.addAttachment(attachment)
  
    request = sg.emptyRequest({
      method: 'POST',
      path: '/v3/mail/send',
      body: mail.toJSON(),
    })
  
    response = yield -> sg.API request, it
    this.body = JSON.stringify(response)
  */
}).call(this);
