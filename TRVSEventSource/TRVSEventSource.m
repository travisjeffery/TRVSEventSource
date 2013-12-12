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
static char *const TRVSEventSourceSyncQueueLabel = "com.travisjeffery.TRVSEventSource.syncQueue";
static NSString *const TRVSEventSourceOperationQueueName = @"com.travisjeffery.TRVSEventSource.operationQueue";

static NSDictionary *TRVSServerSentEventFieldsFromData(NSData *data, NSError * __autoreleasing *error) {
    if (!data || [data length] == 0) return nil;
    
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableDictionary *mutableFields = [NSMutableDictionary dictionary];
    
    for (NSString *line in [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        if (!line || [line length] == 0 || [line hasPrefix:@":"]) continue;
        
        @autoreleasepool {
            NSScanner *scanner = [[NSScanner alloc] initWithString:line];
            scanner.charactersToBeSkipped = [NSCharacterSet whitespaceCharacterSet];
            NSString *key, *value;
            [scanner scanUpToString:@":" intoString:&key];
            [scanner scanString:@":" intoString:nil];
            [scanner scanUpToString:@"\n" intoString:&value];
            
            if (key && value) {
                if (mutableFields[key]) {
                    mutableFields[key] = [mutableFields[key] stringByAppendingFormat:@"\n%@", value];
                } else {
                    mutableFields[key] = value;
                }
            }
        }
    }
    
    return mutableFields;
}

typedef NS_ENUM(NSUInteger, TRVSEventSourceState) {
    TRVSEventSourceConnecting = 0,
    TRVSEventSourceOpen = 1,
    TRVSEventSourceClosed = 2,
};

@interface TRVSEventSource () <NSStreamDelegate>
@property (nonatomic, strong, readwrite) NSOperationQueue *operationQueue;
@property (nonatomic, readwrite) dispatch_queue_t syncQueue;
@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, strong, readwrite) NSURLSession *URLSession;
@property (nonatomic, strong, readwrite) NSURLSessionTask *URLSessionTask;
@property (nonatomic, readwrite) TRVSEventSourceState state;
@property (nonatomic, strong, readwrite) NSMapTable *listenersKeyedByEvent;
@property (nonatomic, strong, readwrite) NSOutputStream *outputStream;
@property (nonatomic, readwrite) NSUInteger offset;
@end

@implementation TRVSEventSource

- (instancetype)initWithURL:(NSURL *)URL {
    if (!(self = [super init])) return nil;
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.name = TRVSEventSourceOperationQueueName;
    self.URL = URL;
    self.listenersKeyedByEvent = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsStrongMemory capacity:TRVSEventSourceListenersCapacity];
    self.URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:self delegateQueue:self.operationQueue];
    self.syncQueue = dispatch_queue_create(TRVSEventSourceSyncQueueLabel, NULL);
    return self;
}

- (BOOL)open:(NSError * __autoreleasing *)error {
    if (self.isOpen) return YES;
    
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.syncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        strongSelf.state = TRVSEventSourceConnecting;
        
        strongSelf.outputStream = [NSOutputStream outputStreamToMemory];
        strongSelf.outputStream.delegate = strongSelf;
        [strongSelf.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [strongSelf.outputStream open];
        
        strongSelf.URLSessionTask = [strongSelf.URLSession dataTaskWithURL:strongSelf.URL];
        [strongSelf.URLSessionTask resume];
        
        strongSelf.state = TRVSEventSourceOpen;

        if ([strongSelf.delegate respondsToSelector:@selector(eventSourceDidOpen:)]) {
            [strongSelf.delegate eventSourceDidOpen:strongSelf];
        }
    });
    
    return YES;
}

- (BOOL)close:(NSError *__autoreleasing *)error {
    if (self.isClosed) return YES;
    
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.syncQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.URLSession invalidateAndCancel];
        strongSelf.outputStream.delegate = nil;
        [strongSelf.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [strongSelf.outputStream close];

        strongSelf.state = TRVSEventSourceClosed;

        if ([strongSelf.delegate respondsToSelector:@selector(eventSourceDidClose:)]) {
            [strongSelf.delegate eventSourceDidClose:strongSelf];
        }
    });
    
    return YES;
}

- (NSUInteger)addListenerForEvent:(NSString *)event usingEventHandler:(TRVSEventSourceEventHandler)eventHandler {
    NSMutableDictionary *mutableListenersKeyedByIdentifier = [self.listenersKeyedByEvent objectForKey:event];
    if (!mutableListenersKeyedByIdentifier) mutableListenersKeyedByIdentifier = [NSMutableDictionary dictionary];
    
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

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(eventSource:didFailWithError:)]) {
        [self.delegate eventSource:self didFailWithError:error];
    }
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable: {
            NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
            NSError *error = nil;
            TRVSServerSentEvent *event = [TRVSServerSentEvent eventWithFields:TRVSServerSentEventFieldsFromData([data subdataWithRange:NSMakeRange(self.offset, [data length] - self.offset)], &error)];
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
        case NSStreamEventErrorOccurred: {
            if ([self.delegate respondsToSelector:@selector(eventSource:didFailWithError:)]) {
                [self.delegate eventSource:self didFailWithError:self.outputStream.streamError];
            }
            break;
        }
        default: break;
    }
}

@end
