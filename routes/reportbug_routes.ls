{
  app
} = require 'libs/server_common'

require! {
  'sendgrid'
  'btoa'
  'n2p'
}

jsyaml = require 'js-yaml'
normalize_space = require 'normalize-space'
text_clipper = require 'text-clipper'

helper = sendgrid.mail
getsecret = require('getsecret')
sg = sendgrid(getsecret('sendgrid_api_key'))
default_from_email = getsecret('from_email')
default_to_email = getsecret('to_email')

cloudinary = require('cloudinary')

cloudinary.config({ 
  cloud_name: getsecret('cloudinary_cloud_name')
  api_key: getsecret('cloudinary_api_key')
  api_secret: getsecret('cloudinary_api_secret')
})

Gitter = require 'node-gitter'
gitter = new Gitter getsecret('gitter_api_key')

Octokat = require 'octokat'
octo = new Octokat({token: getsecret('github_api_key')})

upload_to_cloudinary = (img_data_url) ->>
  #img_data_url = 'data:image/png;base64,' + img_data
  result = await n2p -> cloudinary.v2.uploader.upload img_data_url, {}, it
  #throw new Error('cloudinary failed')
  return result.url

upload_to_cloudinary_json = (json_data) ->>
  public_id = [Math.floor(Math.random()*10) for i from 0 til 28].join('') + '.txt'
  result = await n2p -> cloudinary.v2.uploader.upload 'data:text/plain;base64,' + btoa(JSON.stringify(json_data)), {public_id, resource_type: 'raw'}, it
  return result.url

app.post '/report_bug', (ctx) ->>
  ctx.type = 'json'
  {message, screenshot, other} = ctx.request.body
  user_email = ctx.request.body.email
  is_gitter = ctx.request.body['gitter']
  is_github = ctx.request.body['github']
  if not message?
    ctx.body = JSON.stringify {response: 'error', error: 'need parameter message'}
    return
  screenshot_url = null
  if not other?
    other = {}
  if other.extra?
    extra = other.extra
    delete other.extra
  else
    extra = {}
  extra.ip_address = ctx.request.ip
  extra.server_timestamp = Date.now()
  extra.server_localtime = new Date().toString()
  if screenshot?
    try
      screenshot_url = await upload_to_cloudinary(screenshot)
    catch err
      other.screenshot_upload_error = 'Error occurred while uploading screenshot'
      other.screenshot_upload_error_message = err.toString()

  email_message = message.split('\n').join('<br>')
  if screenshot_url?
    email_message += '<br><br>' + '<img src="' + screenshot_url + '"></img>'
  if other?
    email_message += '<br><br><pre>' + (jsyaml.safeDump(other)) + '</pre>'
  #if extra?
  #  email_message += '<br><br><pre>' + (JSON.stringify(extra)) + '</pre>'
  if extra?
    try
      data_url = await upload_to_cloudinary_json(extra)
      email_message += '<br><br><a href="' + data_url + '">' + data_url + '</a><br><br>'
    catch err
      other.extra_upload_error = 'Error occurred while uploading extra data'
      other.extra_upload_error = err.toString()

  from_email = new helper.Email(default_from_email)
  to_email = new helper.Email(default_to_email)
  title = text_clipper(normalize_space(message), 80)
  subject = '[User Feedback] ' + title
  #var img_data = 'data:image/png;base64,'
  content = new helper.Content('text/html', email_message)
  mail = new helper.Mail(from_email, subject, to_email, content)
  if user_email? and user_email.length > 0 and user_email.indexOf('@') != -1 and user_email.indexOf('.') != -1
    #mail.setReplyTo(user_email)
    if not mail.personalizations?
      mail.personalizations = []
    mail.personalizations[0].addCc(new helper.Email(user_email))

  request = sg.emptyRequest({
    method: 'POST',
    path: '/v3/mail/send',
    body: mail.toJSON(),
  })
  sendgrid_response = await n2p -> sg.API request, it

  github_issue_url = 'https://github.com/habitlab/habitlab/issues/'
  if is_github
    github_message = 'A user submitted the following via HabitLab\'s built-in Feedback form:\n\n' + (message.split('\n').join('\n\n'))
    if screenshot_url?
      github_message += '\n\n' + "<img src=\"#{screenshot_url}\"></img>"
    if other?
      github_message += '\n\n```\n' + jsyaml.safeDump(other) + '\n```\n'
    github_title = subject
    new_issue = {
      title: github_title
      body: github_message
    }
    result = await octo.repos('habitlab', 'habitlab').issues.create(new_issue)
    if result.htmlUrl? and result.htmlUrl.startsWith? and (result.htmlUrl.startsWith('https://github.com/habitlab/habitlab/issues') or result.htmlUrl.startsWith('http://github.com/habitlab/habitlab/issues'))
      github_issue_url = result.htmlUrl

  gitter_message = 'A user submitted the following via HabitLab\'s built-in Feedback form:'
  if is_github
    gitter_message += '\n\nGitHub Issue: ' + "[#{github_issue_url}](#{github_issue_url})"
  gitter_message += '\n\n' + (message.split('\n').join('\n\n'))
  if screenshot_url?
    gitter_message += '\n\n' + "[#{screenshot_url}](#{screenshot_url})"
  if other?
    gitter_message += '\n\n```\n' + jsyaml.safeDump(other) + '\n```\n'
  if is_gitter
    room = await gitter.rooms.join('habitlab/habitlab')
    room.send(gitter_message)

  response_message = 'Your message has been sent to <a href="mailto:' + default_to_email + '" target="_blank">' + default_to_email + '</a> <br><br>'
  if is_gitter
    response_message += 'It has also been posted to the support chat at <a href="https://gitter.im/habitlab/habitlab" target="_blank">https://gitter.im/habitlab/habitlab</a> <br><br>'
  else
    response_message += 'If you need help, try the support chat at <a href="https://gitter.im/habitlab/habitlab" target="_blank">https://gitter.im/habitlab/habitlab</a> <br><br>'
  if is_github
    response_message += 'You can track progress at <a href="' + github_issue_url + '" target="_blank">' + github_issue_url + '</a> <br><br>'
  #else
  #  response_message += 'You can file a bug at <a href="' + github_issue_url + '">' + github_issue_url + '</a> <br><br>'
  ctx.body = {response: 'success', message: response_message}

/*
app.get '/send_test_gitter', (ctx) ->>
  ctx.type = 'json'
  img_url = await upload_to_cloudinary(img_data_base64)
  room = await gitter.rooms.join('habitlab/habitlab')
  room.send("""
  Here is a long message.
  And more.
  Multiline supported right?

  [#{img_url}](#{img_url})
  """)
  ctx.body = img_url

# based off https://github.com/habitlab/habitlab-website/blob/master/app.ls
app.get '/send_test_email', (ctx) ->>
  ctx.type = 'json'
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

  response = await n2p -> sg.API request, it
  ctx.body = JSON.stringify(response)
*/

require('../libs/globals').add_globals(module.exports)