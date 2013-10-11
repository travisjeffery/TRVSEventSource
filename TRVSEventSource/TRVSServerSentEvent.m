//
//  TRVSServerSentEvent.m
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import "TRVSServerSentEvent.h"

@interface TRVSServerSentEvent ()

@property (nonatomic, copy, readwrite) NSString *event;
@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, readwrite) NSTimeInterval retry;
@property (nonatomic, copy, readwrite) NSData *data;
@property (nonatomic, copy, readwrite) NSDictionary *userInfo;

@end

@implementation TRVSServerSentEvent

+ (instancetype)eventWithFields:(NSDictionary *)fields {
    if (!fields) {
        return nil;
    }
    
    TRVSServerSentEvent *event = [[self alloc] init];
    
    NSMutableDictionary *mutableFields = [NSMutableDictionary dictionaryWithDictionary:fields];
    event.event = mutableFields[@"event"];
    event.identifier = mutableFields[@"id"];
    event.data = [mutableFields[@"data"] dataUsingEncoding:NSUTF8StringEncoding];
    event.retry = [mutableFields[@"retry"] integerValue];
    
    [mutableFields removeObjectsForKeys:@[@"event", @"id", @"data", @"retry"]];
    event.userInfo = mutableFields;
    
    return event;
}

@end
