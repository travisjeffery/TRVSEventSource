//
//  TRVSEventSourceManager.m
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import "TRVSEventSource.h"
#import "TRVSServerSentEvent.h"

NSString *const TRVSEventSourceErrorDomain = @"com.travisjeffery.TRVSEventSource";
const NSInteger TRVSEventSourceErrorSourceClosed = 666;
static NSUInteger const TRVSEventSourceListenersCapacity = 100;

typedef NS_ENUM(NSUInteger, TRVSEventSourceState) {
    TRVSEventSourceConnecting = 0,
    TRVSEventSourceOpen = 1,
    TRVSEventSourceClosed = 2,
};

@interface TRVSEventSource () <NSStreamDelegate>
@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, strong, readwrite) NSURLSession *URLSession;
@property (nonatomic, strong, readwrite) NSURLSessionTask *URLSessionTask;
@property (nonatomic) TRVSEventSourceState state;
@property (nonatomic, strong) NSMapTable *listenersKeyedByEvent;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic) NSUInteger offset;
@end

@implementation TRVSEventSource

- (instancetype)initWithURL:(NSURL *)URL {
    self = [self init];
    if (!self) return nil;
    self.URL = URL;
    self.listenersKeyedByEvent = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsStrongMemory capacity:TRVSEventSourceListenersCapacity];
    self.URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSError *error = nil;
    [self open:&error];
    if (error) {
        if ([self.delegate respondsToSelector:@selector(eventSource:didFailWithError:)]) {
            [self.delegate eventSource:self didFailWithError:error];
        }
    }
    return self;
}

- (BOOL)open:(NSError * __autoreleasing *)error {
    if ([self isOpen]) return YES;

    self.state = TRVSEventSourceConnecting;

    self.URLSessionTask = [self.URLSession dataTaskWithURL:self.URL];
    self.outputStream = [NSOutputStream outputStreamToMemory];
    self.outputStream.delegate = self;
     [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    [self.URLSessionTask resume];

    self.state = TRVSEventSourceOpen;

    return YES;
}

- (NSUInteger)addListenerForEvent:(NSString *)event usingEventHandler:(TRVSEventSourceEventHandler)eventHandler {
    NSMutableDictionary *mutableListenersKeyedByIdentifier = [self.listenersKeyedByEvent objectForKey:event];
    if (!mutableListenersKeyedByIdentifier) {
        mutableListenersKeyedByIdentifier = [NSMutableDictionary dictionary];
    }

    NSUInteger identifier = [[NSUUID UUID] hash];
    mutableListenersKeyedByIdentifier[@(identifier)] = [eventHandler copy];

    [self.listenersKeyedByEvent setObject:mutableListenersKeyedByIdentifier forKey:event];

    return identifier;
}

- (BOOL)isConnecting {
    return self.state == TRVSEventSourceConnecting;
}

- (BOOL)isOpen {
    return self.state == TRVSEventSourceOpen;
}

- (BOOL)isClosed {
    return self.state == TRVSEventSourceClosed;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSUInteger length = data.length;
    while (YES) {
        NSInteger totalNumberOfBytesWritten = 0;
        if (self.outputStream.hasSpaceAvailable) {
            const uint8_t *dataBuffer = (uint8_t *)[data bytes];
            
            NSInteger numberOfBytesWritten = 0;
            while (totalNumberOfBytesWritten < (NSInteger)length) {
                numberOfBytesWritten = [self.outputStream write:&dataBuffer[0] maxLength:length];
                if (numberOfBytesWritten == -1) {
                    return;
                } else {
                    totalNumberOfBytesWritten += numberOfBytesWritten;
                }
            }
            
            break;
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.outputStream close];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    [self.outputStream close];
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable: {
            NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
            NSError *error = nil;
            TRVSServerSentEvent *event = [TRVSServerSentEvent eventFromData:[data subdataWithRange:NSMakeRange(self.offset, [data length] - self.offset)] error:error];
            self.offset = [data length];
            
            if (error) {
                if ([self.delegate respondsToSelector:@selector(eventSource:didFailWithError:)]) {
                    [self.delegate eventSource:self didFailWithError:error];
                }
            }
            else {
                if (event) {
                    if ([self.delegate respondsToSelector:@selector(eventSource:didReceiveEvent:)]) {
                        [self.delegate eventSource:self didReceiveEvent:event];
                    }

                    [[self.listenersKeyedByEvent objectForKey:event.event] enumerateKeysAndObjectsUsingBlock:^(id _, TRVSEventSourceEventHandler eventHandler, BOOL *stop) {
                        eventHandler(event, nil);
                    }];
                }
            }
            break;
        }
        default: break;
    }
}

@end
