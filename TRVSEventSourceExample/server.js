var http = require('http')
  , interval = 2000 
  , port = 8000
  
http.createServer(function(req, res){
  res.writeHead(200, {'Transfer-Encoding': 'chunked', 'Content-Type': 'text/event-stream'})
  setInterval(function(){
    var event = 'event: test\ndata: {"text":"' + (new Date().getTime()) + '"}\n\n'
    res.write(event)
  }, interval)
}).listen(port)
