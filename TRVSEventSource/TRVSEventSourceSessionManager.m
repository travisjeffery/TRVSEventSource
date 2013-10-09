//
//  TRVSEventSourceManager.m
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import "TRVSEventSourceSessionManager.h"
#import "TRVSServerSentEvent.h"

NSString *const TRVSEventSourceErrorDomain = @"com.travisjeffery.TRVSEventSourceSessionManager";
const NSInteger TRVSEventSourceErrorSourceClosed = 666;

@interface TRVSEventSourceSessionManager ()

@property (nonatomic, copy, readwrite) TRVSDidReceiveEventHandler eventHandler;
@property (nonatomic, strong, readwrite) NSURLSession *URLSession;

@end

@implementation TRVSEventSourceSessionManager

- (instancetype)initWithURL:(NSURL *)URL eventHandler:(TRVSDidReceiveEventHandler)eventHandler {
    self = [self init];
    if (self) {
        self.eventHandler = eventHandler;
        self.URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                        delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionDataTask *task = [self.URLSession dataTaskWithURL:URL];
        [task resume];
    }
    return self;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    TRVSServerSentEvent *event = [TRVSServerSentEvent eventFromData:data];
    self.eventHandler(event, nil);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    self.eventHandler(nil, error);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    self.eventHandler(nil, error);
}

@end
