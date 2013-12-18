# TRVSEventSource

Server-sent events EventSource implementation in ObjC for iOS and OS X using NSURLSession.

## Usage

``` objc
TRVSEventSource *eventSource = [[TRVSEventSource alloc] initWithURL:URL];
eventSource.delegate = self;

[eventSource addListenerForEvent:@"message" usingEventHandler:^(TRVSServerSentEvent *event, NSError *error) {
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:event.data options:0 error:NULL];
    Message *message = [Message messageWithJSON:JSON];
}];

[eventSource open];
```

## Local test server

Run the following to have a local server streaming events named `message`:

`node TRVSEventSourceTests/server.js`

```
❯ curl 127.0.0.1:8000
event: message
data: {"id": 1, "body":"1381466575460", "author_id": 1, "conversation_id": 1}

event: message
data: {"id": 2, "body":"1381466577463", "author_id": 1, "conversation_id": 1}
```
