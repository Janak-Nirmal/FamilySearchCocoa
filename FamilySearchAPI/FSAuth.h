//
//  FamilySearchAPI.h
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import <MTPocket.h>


@interface FSAuth : NSObject


#pragma mark - Public Properties


#pragma mark - Public Methods
- (id)initWithDeveloperKey:(NSString *)devKey sandboxed:(BOOL)sandboxed;
- (MTPocketResponse *)sessionIDFromLoginWithUsername:(NSString *)un password:(NSString *)pw;
- (MTPocketResponse *)logout;


@end
