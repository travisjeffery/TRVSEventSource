//
//  TRVSEventSourceManager.h
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRVSServerSentEvent.h"
#import "TRVSEventSourceDelegate.h"

extern NSString *const TRVSEventSourceErrorDomain;
extern const NSInteger TRVSEventSourceErrorSourceClosed;

@class TRVSServerSentEvent;

typedef void (^TRVSEventSourceEventHandler)(TRVSServerSentEvent *event, NSError *error);

@interface TRVSEventSource : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) NSURLSession *URLSession;
@property (nonatomic, strong, readonly) NSURLSessionTask *URLSessionTask;
@property (nonatomic, copy, readonly) TRVSEventSourceEventHandler eventHandler;
@property (nonatomic, weak) id<TRVSEventSourceDelegate> delegate;

// @name connection state

@property (nonatomic, getter=isConnecting) BOOL connecting;
@property (nonatomic, getter=isOpen) BOOL open;
@property (nonatomic, getter=isClosed) BOOL closed;

// @name initializing an event source

- (instancetype)initWithURL:(NSURL *)URL;

// @name opening and closing an event source

- (BOOL)open:(NSError * __autoreleasing *)error;
- (BOOL)close:(NSError * __autoreleasing *)error;

// @name listening for events

- (NSUInteger)addListenerForEvent:(NSString *)event
                usingEventHandler:(TRVSEventSourceEventHandler)eventHandler;

@end
