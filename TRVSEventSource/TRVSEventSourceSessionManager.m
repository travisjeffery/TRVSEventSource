//
//  TRVSEventSourceManager.m
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import "TRVSEventSourceSessionManager.h"
#import "TRVSEvent.h"

NSString *const TRVSEventSourceErrorDomain = @"com.travisjeffery.TRVSEventSourceSessionManager";
const NSInteger TRVSEventSourceErrorSourceClosed = 666;
static NSString *const TRVSEventSourceURLSesssionIndentifer = @"TRVSEventSourceURLSesssionIndentifer";

@interface TRVSEventSourceSessionManager ()

@property (nonatomic, copy, readwrite) TRVSDidReceiveEventHandler eventHandler;
@property (nonatomic, strong, readwrite) NSURLSession *URLSession;
@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, strong, readwrite) NSOperationQueue *operationQueue;

@end

@implementation TRVSEventSourceSessionManager

+ (instancetype)sessionManagerWithURL:(NSURL *)URL eventHandler:(TRVSDidReceiveEventHandler)eventHandler {
    TRVSEventSourceSessionManager *manager = [[self alloc] initWithURL:URL eventHandler:eventHandler];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLSessionDataTask *task = [manager.URLSession dataTaskWithRequest:request];
    [task resume];
    return manager;
}

- (instancetype)initWithURL:(NSURL *)URL eventHandler:(TRVSDidReceiveEventHandler)eventHandler {
    self = [self init];
    if (self) {
        self.eventHandler = eventHandler;
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.URL = URL;
        self.URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:TRVSEventSourceURLSesssionIndentifer]
                                                        delegate:self delegateQueue:self.operationQueue];

    }
    return self;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    TRVSEvent *event = [TRVSEvent eventFromData:data];
    self.eventHandler(event, nil);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    self.eventHandler(nil, error);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    self.eventHandler(nil, error);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    self.eventHandler(nil, [NSError errorWithDomain:TRVSEventSourceErrorDomain code:TRVSEventSourceErrorSourceClosed userInfo:@{
        NSLocalizedDescriptionKey: NSLocalizedString(@"Connection with event source closed.", nil)
    }]);
}

@end
