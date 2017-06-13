{
  app
  auth
} = require 'libs/server_common'

require! {
  querystring
  glob
}

do ->
  for let filepath in glob.sync('www/*.html')
    filename = filepath.replace('www', '')
    filenamebase = filename.replace('.html', '')
    app.get filenamebase, auth, (ctx) ->>
      query = ctx.request.query
      if Object.keys(query).length > 0
        ctx.response.redirect filename + '?' + querystring.stringify(query)
      else
        ctx.response.redirect filename

#app.get '/viewlogs', auth, (ctx) ->>
#  {user_id, userid} = ctx.request.query
#  userid ?= user_id
#  ctx.response.redirect('/dashboard.html?' + querystring.stringify({userid}))

#app.get '/installs', auth, (ctx) ->>
#  ctx.response.redirect('/installs.html')

#app.get '/installs', auth, (ctx) ->>
#  index_contents = await fs.readFileAsync(__dirname + '/www/installs.html', 'utf-8')
#  ctx.body = index_contents