//
//  TRVSEventSourceManager.h
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRVSEventSourceDelegate.h"
#import "TRVSServerSentEvent.h"

@class TRVSServerSentEvent;

typedef void (^TRVSEventSourceEventHandler)(TRVSServerSentEvent *event, NSError *error);

@interface TRVSEventSource : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>

// The URL that the event source receives events from.
@property (nonatomic, strong, readonly) NSURL *URL;
// The managed session.
@property (nonatomic, strong, readonly) NSURLSession *URLSession;
// The task used to connect to the URL and receive event data.
@property (nonatomic, strong, readonly) NSURLSessionTask *URLSessionTask;
// The operation queue on which delegate callbacks are run.
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
// The delegate you're using that's responsible for what to do when the event source state changes or receives events.
@property (nonatomic, weak) id<TRVSEventSourceDelegate> delegate;

// @name connection state

- (BOOL)isConnecting;
- (BOOL)isOpen;
- (BOOL)isClosed;
- (BOOL)isClosing;

// @name initializing an event source

- (instancetype)initWithURL:(NSURL *)URL;

// @name opening and closing an event source

- (void)open;
- (void)close;

// @name listening for events

- (NSUInteger)addListenerForEvent:(NSString *)event
                usingEventHandler:(TRVSEventSourceEventHandler)eventHandler;

@end
