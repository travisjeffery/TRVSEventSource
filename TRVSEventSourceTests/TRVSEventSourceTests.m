//
//  TRVSEventSourceTests.m
//  TRVSEventSourceTests
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRVSServerSentEvent.h"

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
    TRVSEvent *event = [TRVSEvent eventFromData:data];

    XCTAssertEqualObjects(@"kung fu", event.type);
    XCTAssertEqualObjects(@"bill: bro: baggins", event.dataString);
}

@end
