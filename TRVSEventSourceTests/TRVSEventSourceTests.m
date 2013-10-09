//
//  TRVSEventSourceTests.m
//  TRVSEventSourceTests
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRVSEventSource.h"

@interface TRVSEventSourceTests : XCTestCase

@end

@implementation TRVSEventSourceTests

- (void)setUp {
    [super setUp];

}

- (void)tearDown {
    [super tearDown];
}

- (void)testEventFromData {
    NSData *data = [@"event: kung fu\ndata: bill: bro: baggins" dataUsingEncoding:NSUTF8StringEncoding];
    TRVSServerSentEvent *event = [TRVSServerSentEvent eventFromData:data error:nil ];

    XCTAssertEqualObjects(@"kung fu", event.event);
    XCTAssertEqualObjects(@"bill: bro: baggins", event.dataString);
}

@end
