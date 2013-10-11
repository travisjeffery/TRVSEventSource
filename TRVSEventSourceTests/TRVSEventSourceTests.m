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

    NSError *error = nil;
    XCTAssert([eventSource open:&error]);
    XCTAssert(!error);
    [monitor wait];
}

@end
