//
//  TRVSEventSourceManager.m
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import "TRVSEventSource.h"

static NSUInteger const TRVSEventSourceListenersCapacity = 100;
static NSString *const TRVSEventSourceOperationQueueName =
    @"com.travisjeffery.TRVSEventSource.operationQueue";

static NSDictionary *TRVSServerSentEventFieldsFromString(
    NSString *string,
    NSError *__autoreleasing *error) {
  if (!string || [string length] == 0)
    return nil;

  NSMutableDictionary *mutableFields = [NSMutableDictionary dictionary];

  for (NSString *line in [string componentsSeparatedByCharactersInSet:
                                     [NSCharacterSet newlineCharacterSet]]) {
    if (!line || [line length] == 0 || [line hasPrefix:@":"])
      continue;

    @autoreleasepool {
      NSScanner *scanner = [[NSScanner alloc] initWithString:line];
      scanner.charactersToBeSkipped = [NSCharacterSet whitespaceCharacterSet];
      NSString *key, *value;
      [scanner scanUpToString:@":" intoString:&key];
      [scanner scanString:@":" intoString:nil];
      [scanner scanUpToString:@"\n" intoString:&value];

      if (key && value) {
        if (mutableFields[key]) {
          mutableFields[key] =
              [mutableFields[key] stringByAppendingFormat:@"\n%@", value];
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
  TRVSEventSourceOpen,
  TRVSEventSourceClosed,
  TRVSEventSourceClosing,
  TRVSEventSourceFailed
};

@interface TRVSEventSource ()

@property (nonatomic, strong, readwrite) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, strong, readwrite) NSURLSession *URLSession;
@property (nonatomic, strong, readwrite) NSURLSessionTask *URLSessionTask;
@property (nonatomic, readwrite) TRVSEventSourceState state;
@property (nonatomic, strong, readwrite) NSMapTable *listenersKeyedByEvent;
@property (nonatomic, strong) NSMutableString *buffer;

@end

@implementation TRVSEventSource

#pragma mark - Public

- (instancetype)initWithURL:(NSURL *)URL {
  return [self initWithURL:URL
      sessionConfiguration:NSURLSessionConfiguration
                               .defaultSessionConfiguration];
}

- (instancetype)initWithURL:(NSURL *)URL
       sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
  if (!(self = [super init]))
    return nil;

  _operationQueue = [[NSOperationQueue alloc] init];
  _operationQueue.name = TRVSEventSourceOperationQueueName;
  _operationQueue.maxConcurrentOperationCount = 1;
  _URL = URL;
  _listenersKeyedByEvent =
      [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsCopyIn
                                valueOptions:NSPointerFunctionsStrongMemory
                                    capacity:TRVSEventSourceListenersCapacity];
  _URLSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                              delegate:self
                                         delegateQueue:_operationQueue];
  self.buffer = [NSMutableString stringWithCapacity:4096];

  return self;
}

- (void)open {
  [self transitionToConnecting];
}

- (void)close {
  [self transitionToClosing];
}

- (NSUInteger)addListenerForEvent:(NSString *)event
                usingEventHandler:(TRVSEventSourceEventHandler)eventHandler {
  NSMutableDictionary *mutableListenersKeyedByIdentifier =
      [self.listenersKeyedByEvent objectForKey:event];
  if (!mutableListenersKeyedByIdentifier)
    mutableListenersKeyedByIdentifier = [NSMutableDictionary dictionary];

  NSUInteger identifier = [[NSUUID UUID] hash];
  mutableListenersKeyedByIdentifier[@(identifier)] = [eventHandler copy];

  [self.listenersKeyedByEvent setObject:mutableListenersKeyedByIdentifier
                                 forKey:event];

  return identifier;
}

- (void)removeEventListenerWithIdentifier:(NSUInteger)identifier {
  NSEnumerator *enumerator = [self.listenersKeyedByEvent keyEnumerator];
  id event = nil;

  while ((event = [enumerator nextObject])) {
    NSMutableDictionary *mutableListenersKeyedByIdentifier =
        [self.listenersKeyedByEvent objectForKey:event];

    if ([mutableListenersKeyedByIdentifier objectForKey:@(identifier)]) {
      [mutableListenersKeyedByIdentifier removeObjectForKey:@(identifier)];
      [self.listenersKeyedByEvent setObject:mutableListenersKeyedByIdentifier
                                     forKey:event];
      return;
    }
  }
}

- (void)removeAllListenersForEvent:(NSString *)event {
  [self.listenersKeyedByEvent removeObjectForKey:event];
}

#pragma mark - State

- (BOOL)isConnecting {
  return self.state == TRVSEventSourceConnecting;
}

- (BOOL)isOpen {
  return self.state == TRVSEventSourceOpen;
}

- (BOOL)isClosed {
  return self.state == TRVSEventSourceClosed;
}

- (BOOL)isClosing {
  return self.state == TRVSEventSourceClosing;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.buffer appendString:string];
    NSRange range = [self.buffer rangeOfString:@"\n\n"];
    
    NSError *error;
    TRVSServerSentEvent *event;
    while (range.location != NSNotFound) @autoreleasepool {
        error = nil;
        event = [TRVSServerSentEvent eventWithFields:TRVSServerSentEventFieldsFromString([self.buffer substringToIndex:range.location], &error)];
        [self.buffer deleteCharactersInRange:NSMakeRange(0, range.location + 2)];
        
        if (error)
            [self transitionToFailedWithError:error];
        
        if (error || !event)
            return;
        
        [[self.listenersKeyedByEvent objectForKey:event.event]
         enumerateKeysAndObjectsUsingBlock:
         ^(id _, TRVSEventSourceEventHandler eventHandler, BOOL *stop) {
             eventHandler(event, nil);
         }];
        
        if ([self.delegate
             respondsToSelector:@selector(eventSource:didReceiveEvent:)]) {
            [self.delegate eventSource:self didReceiveEvent:event];
        }
        
        range = [self.buffer rangeOfString:@"\n\n"];
    }
}

- (void)URLSession:(NSURLSession *)session
              dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:
         (void (^)(NSURLSessionResponseDisposition))completionHandler {
  completionHandler(NSURLSessionResponseAllow);
  [self transitionToOpenIfNeeded];
}

- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
  if (self.isClosing && error.code == NSURLErrorCancelled) {
    [self transitionToClosed];
  } else {
    [self transitionToFailedWithError:error];
  }
}

#pragma NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
  NSURL *URL = [aDecoder decodeObjectForKey:@"URL"];

  if (!(self = [self initWithURL:URL]))
    return nil;

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.URL forKey:@"URL"];
}

#pragma NSCopying

- (id)copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone:zone] initWithURL:self.URL];
}

#pragma mark - Private

- (void)transitionToOpenIfNeeded {
  if (self.state != TRVSEventSourceConnecting)
    return;

  self.state = TRVSEventSourceOpen;

  if ([self.delegate respondsToSelector:@selector(eventSourceDidOpen:)]) {
    [self.delegate eventSourceDidOpen:self];
  }
}

- (void)transitionToFailedWithError:(NSError *)error {
  self.state = TRVSEventSourceFailed;

  if ([self.delegate
          respondsToSelector:@selector(eventSource:didFailWithError:)]) {
    [self.delegate eventSource:self didFailWithError:error];
  }
}

- (void)transitionToClosed {
  self.state = TRVSEventSourceClosed;

  if ([self.delegate respondsToSelector:@selector(eventSourceDidClose:)]) {
    [self.delegate eventSourceDidClose:self];
  }
}

- (void)transitionToConnecting {
  self.state = TRVSEventSourceConnecting;
  [self.operationQueue addOperationWithBlock:^{
    [self.buffer setString:@""];
  }];
  self.URLSessionTask = [self.URLSession dataTaskWithURL:self.URL];
  [self.URLSessionTask resume];
}

- (void)transitionToClosing {
  self.state = TRVSEventSourceClosing;
  [self.operationQueue addOperationWithBlock:^{
    [self.buffer setString:@""];
  }];
  [self.URLSession invalidateAndCancel];
}

@end
