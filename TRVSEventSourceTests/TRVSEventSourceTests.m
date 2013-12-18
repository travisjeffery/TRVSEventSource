//
//  TRVSEventSourceTests.m
//  TRVSEventSourceTests
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRVSEventSource.h"
#import <TRVSMonitor/TRVSMonitor.h>
#import <OCMock/OCMock.h>
#import "TRVSEventSourceTestDelegate.h"

@interface TRVSEventSourceTests : XCTestCase

@end

@implementation TRVSEventSourceTests

- (void)testEventSourceStreaming {
    // you must be running the local server. see README.md.
    TRVSEventSource *eventSource = [[TRVSEventSource alloc] initWithURL:[NSURL URLWithString:@"http://127.0.0.1:8000"]];

    __block TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:3];
    [eventSource addListenerForEvent:@"message" usingEventHandler:^(TRVSServerSentEvent *event, NSError *error) {
        XCTAssert(event);
        XCTAssertEqualObjects(@"message", event.event);
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:event.data options:0 error:NULL];
        XCTAssertEqualObjects(@1, dictionary[@"author_id"]);
        XCTAssertEqualObjects(@1, dictionary[@"conversation_id"]);
        XCTAssert(dictionary[@"body"]);
        [monitor signal];
    }];

    [eventSource open];
    XCTAssert([monitor wait]);
}


- (void)testEventSourceOpening {
    TRVSEventSource *eventSource = [[TRVSEventSource alloc] initWithURL:[NSURL URLWithString:@"http://127.0.0.1:8000"]];
    id delegate = [OCMockObject mockForClass:[TRVSEventSourceTestDelegate class]];
    eventSource.delegate = delegate;
    __block TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:2];
    __weak typeof(eventSource) weakEventSource = eventSource;

    [eventSource addListenerForEvent:@"message" usingEventHandler:^(TRVSServerSentEvent *event, NSError *error) {
        [[delegate expect] eventSource:weakEventSource didReceiveEvent:[OCMArg any]];
        [monitor signal];
    }];
    
    [[[delegate stub] andDo:^(NSInvocation *invocation) {
        XCTAssert(eventSource.isOpen);
        [monitor signal];
    }] eventSourceDidOpen:eventSource];
    
    [eventSource open];
    XCTAssert(eventSource.isConnecting);
    
    XCTAssert([monitor wait]);
    [delegate verify];
}

- (void)testEventSourceClosing {
    TRVSEventSource *eventSource = [[TRVSEventSource alloc] initWithURL:[NSURL URLWithString:@"http://127.0.0.1:8000"]];
    id delegate = [OCMockObject mockForClass:[TRVSEventSourceTestDelegate class]];
    eventSource.delegate = delegate;
    __block TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:3];
    __weak typeof(eventSource) weakEventSource = eventSource;
    
    [eventSource addListenerForEvent:@"message" usingEventHandler:^(TRVSServerSentEvent *event, NSError *error) {
        __strong typeof(weakEventSource) strongEventSource = weakEventSource;
        [[delegate expect] eventSource:strongEventSource didReceiveEvent:[OCMArg any]];
        [strongEventSource close];
        XCTAssert(strongEventSource.isClosing);
        [monitor signal];
    }];
    
    [[[delegate stub] andDo:^(NSInvocation *invocation) {
        [monitor signal];
    }] eventSourceDidOpen:eventSource];
    
    [eventSource open];
    
    [[[delegate stub] andDo:^(NSInvocation *invocation) {
        XCTAssert(eventSource.isClosed);
        [monitor signal];
    }] eventSourceDidClose:eventSource];
    
    XCTAssert([monitor wait]);
    [delegate verify];
}

- (void)testEventSourceNoServer {
    TRVSEventSource *eventSource = [[TRVSEventSource alloc] initWithURL:[NSURL URLWithString:@"http://doesntexistdotcom:8000"]];
    id delegate = [OCMockObject mockForClass:[TRVSEventSourceTestDelegate class]];
    eventSource.delegate = delegate;
    __block TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:1];
    
    [[[delegate stub] andDo:^(NSInvocation *invocation) {
        [monitor signal];
    }] eventSource:eventSource didFailWithError:[OCMArg any]];
    
    [eventSource open];
    
    XCTAssert([monitor wait]);
    [delegate verify];
}

@end
