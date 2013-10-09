//
//  TRVSEventSourceDelegate.h
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/9/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TRVSEventSource;
@class TRVSServerSentEvent;

@protocol TRVSEventSourceDelegate <NSObject>
@optional
- (void)eventSourceDidOpen:(TRVSEventSource *)eventSource;
- (void)eventSourceDidClose:(TRVSEventSource *)eventSource;
- (void)eventSource:(TRVSEventSource *)eventSource didReceiveEvent:(TRVSServerSentEvent *)event;
- (void)eventSource:(TRVSEventSource *)eventSource didFailWithError:(NSError *)error;
@end
