# TRVSEventSource

Server-sent events EventSource API client library. 

## Local test server

Run the following to have a local server streaming events named `message`:

`node ./TRVSEventSourceExample/server.js`

```
❯ curl 127.0.0.1:8000
event: message
data: {"id": 1, "body":"1381466575460", "author_id": 1, "conversation_id": 1}

event: message
data: {"id": 2, "body":"1381466577463", "author_id": 1, "conversation_id": 1}
```
