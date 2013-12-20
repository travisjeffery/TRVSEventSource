//
//  TRVSServerSentEvent.h
//  TRVSEventSource
//
//  Created by Travis Jeffery on 10/8/13.
//  Copyright (c) 2013 Travis Jeffery. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRVSServerSentEvent : NSObject <NSCoding, NSCopying>

@property (nonatomic, copy, readonly) NSString *event;
@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, readonly) NSTimeInterval retry;
@property (nonatomic, copy, readonly) NSData *data;
@property (nonatomic, copy, readonly) NSDictionary *userInfo;

+ (instancetype)eventWithFields:(NSDictionary *)fields;

@end
