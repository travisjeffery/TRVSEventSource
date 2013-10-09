//
//  TRVSEventSourceManager.h
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRVSServerSentEvent.h"

extern NSString *const TRVSEventSourceErrorDomain;
extern const NSInteger TRVSEventSourceErrorSourceClosed;

@class TRVSServerSentEvent;

typedef void (^TRVSDidReceiveEventHandler)(TRVSServerSentEvent *event, NSError *error);

@interface TRVSEventSourceSessionManager : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSURLSession *URLSession;
@property (nonatomic, copy, readonly) TRVSDidReceiveEventHandler eventHandler;

- (instancetype)initWithURL:(NSURL *)URL eventHandler:(TRVSDidReceiveEventHandler)eventHandler;

@end
