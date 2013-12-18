//
//  TRVSEventSourceTestDelegate.m
//  TRVSEventSource
//
//  Created by Travis Jeffery on 12/18/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import "TRVSEventSourceTestDelegate.h"
#import "TRVSEventSource.h"

@implementation TRVSEventSourceTestDelegate

- (void)eventSourceDidOpen:(TRVSEventSource *)eventSource {}
- (void)eventSourceDidClose:(TRVSEventSource *)eventSource {}
- (void)eventSource:(TRVSEventSource *)eventSource didReceiveEvent:(TRVSServerSentEvent *)event {}
- (void)eventSource:(TRVSEventSource *)eventSource didFailWithError:(NSError *)error {}

@end
