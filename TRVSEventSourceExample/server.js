var http = require('http')
  , interval = 2000 
  , port = 8000
  , id = 0
  
http.createServer(function(req, res){
  res.writeHead(200, {'Transfer-Encoding': 'chunked', 'Content-Type': 'text/event-stream'})
  setInterval(function(){
    var event = 'event: message\ndata: {"id": ' + (++id) + ', "body":"' + (new Date().getTime()) + '", "author_id": 1, "conversation_id": 1}\n\n'
    res.write(event)
  }, interval)
}).listen(port)

console.log('He makes sweet music with the enameled stones,\n' +
  'Giving a gentle kiss to every sedge,\n' +
  'He overtaketh in his pilgrimage.\n\n' +
  'Streaming events on port', 8000)
