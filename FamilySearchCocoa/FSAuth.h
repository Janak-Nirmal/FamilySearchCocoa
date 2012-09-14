//
//  FSAuth.h
//  FSAuth
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

@class MTPocketResponse;


@interface FSAuth : NSObject

- (id)initWithDeveloperKey:(NSString *)devKey;
- (MTPocketResponse *)loginWithUsername:(NSString *)un password:(NSString *)pw;
- (MTPocketResponse *)logout;

@property (strong, nonatomic) NSString *sessionID;

@end
