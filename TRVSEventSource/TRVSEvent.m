//
//  TRVSEvent.m
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import "TRVSEvent.h"

@interface TRVSEvent ()

@property (nonatomic, copy, readwrite) NSString *type;
@property (nonatomic, copy, readwrite) NSString *ID;
@property (nonatomic, readwrite) NSTimeInterval retry;
@property (nonatomic, copy, readwrite) NSData *data;

@end

@implementation TRVSEvent

+ (instancetype)eventWithType:(NSString *)type ID:(NSString *)ID data:(NSData *)data retry:(NSTimeInterval)retry {
    TRVSEvent *event = [[self alloc] init];
    event.type = type;
    event.ID = ID;
    event.data = data;
    event.retry = retry;
    return event;
}

+ (instancetype)eventFromData:(NSData *)data {
    TRVSEvent *event = [[self alloc] init];
    NSArray *fields = [self fieldsFromData:data];
    [fields enumerateObjectsUsingBlock:^(NSString *field, NSUInteger idx, BOOL *stop) {
        NSArray *components = [field componentsSeparatedByString:@": "];
        NSString *key = [self eventFieldsDictionary][components[0]];
        if (key) [event setValue:components[1] forKey:key];
    }];
    return event;
}

+ (NSArray *)fieldsFromData:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    dataString = [dataString stringByReplacingOccurrencesOfString:@"\n\n" withString:@""];
    NSArray *fields = [dataString componentsSeparatedByString:@"\n"];
    return fields;
}

+ (NSDictionary *)eventFieldsDictionary {
    return @{
         @"event": @"type",
         @"id": @"ID",
         @"data": @"data"
     };
}

@end
