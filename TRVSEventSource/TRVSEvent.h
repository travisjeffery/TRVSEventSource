//
//  TRVSEvent.h
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRVSEvent : NSObject

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *ID;
@property (nonatomic, readonly) NSTimeInterval retry;
@property (nonatomic, copy, readonly) NSData *data;

+ (instancetype)eventWithType:(NSString *)type
                           ID:(NSString *)ID
                         data:(NSData *)data
                        retry:(NSTimeInterval)retry;

+ (instancetype)eventFromData:(NSData *)data;

@end
