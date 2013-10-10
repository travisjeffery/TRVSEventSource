//
//  TRVSServerSentEvent.h
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRVSServerSentEvent : NSObject

@property (nonatomic, copy, readonly) NSString *event;
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, readonly) NSTimeInterval retry;
@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, copy, readonly) NSString *dataString;
@property (nonatomic, copy, readonly) NSDictionary *dataDictionary;

+ (instancetype)eventWithType:(NSString *)type
                           ID:(NSString *)ID
                         dataString:(NSString *)dataString
                        retry:(NSTimeInterval)retry;

+ (instancetype)eventFromData:(NSData *)data error:(NSError *)error;

@end
