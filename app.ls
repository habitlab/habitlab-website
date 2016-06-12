require! {
  express
}

app = express()
port = process.env.PORT ? 5000
app.use express.static(__dirname + '/www')
app.set 'port', port

app.listen(app.get('port'))
console.log "running on port #{port} visit http://localhost:#{port}"
