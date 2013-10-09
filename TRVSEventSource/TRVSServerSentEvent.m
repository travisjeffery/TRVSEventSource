//
//  TRVSServerSentEvent.m
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import "TRVSServerSentEvent.h"

@interface TRVSServerSentEvent ()

@property (nonatomic, copy, readwrite) NSString *type;
@property (nonatomic, copy, readwrite) NSString *ID;
@property (nonatomic, readwrite) NSTimeInterval retry;
@property (nonatomic, copy, readwrite) NSString *dataString;
@property (nonatomic, copy, readwrite) NSDictionary *dataDictionary;

@end

@implementation TRVSServerSentEvent

+ (instancetype)eventWithType:(NSString *)type ID:(NSString *)ID dataString:(NSString *)dataString retry:(NSTimeInterval)retry {
    TRVSServerSentEvent *event = [[self alloc] init];
    event.type = type;
    event.ID = ID;
    event.dataString = dataString;
    event.retry = retry;
    return event;
}

+ (instancetype)eventFromData:(NSData *)data {
    TRVSServerSentEvent *event = [[self alloc] init];
    NSArray *fields = [self fieldsFromData:data];
    [fields enumerateObjectsUsingBlock:^(NSString *field, NSUInteger idx, BOOL *stop) {
        NSRange range = [field rangeOfString:@": "];
        if (range.location == NSNotFound) return;
        NSString *key = [self eventFieldsDictionary][[field substringToIndex:range.location]];
        if (key) [event setValue:[field substringFromIndex:range.location + range.length] forKey:key];
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
         @"data": @"dataString"
     };
}

- (NSDictionary *)dataDictionary {
    if (_dataDictionary) return _dataDictionary;
    _dataDictionary = [NSJSONSerialization JSONObjectWithData:[self.dataString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    return _dataDictionary;
}

@end
