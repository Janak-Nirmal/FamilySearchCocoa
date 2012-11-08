//
//  FSAuth.m
//  FSAuth
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSAuth.h"
#import "private.h"
#import <NSObject+MTJSONUtils.h>





@interface FSAuth ()
@property (strong, nonatomic) NSString *devKey;
@property (strong, nonatomic) FSURL *url;
@end







@implementation FSAuth

- (id)initWithDeveloperKey:(NSString *)devKey
{
    self = [super init];
    if (self) {
        _devKey = devKey;
		_url = [[FSURL alloc] initWithSessionID:nil];
    }
    return self;
}

- (MTPocketResponse *)loginWithUsername:(NSString *)un password:(NSString *)pw
{	
	NSURL *url = [_url urlWithModule:@"identity"
							 version:2
							resource:@"login"
						 identifiers:nil
							  params:0
								misc:[NSString stringWithFormat:@"key=%@", _devKey]];
	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON username:un password:pw body:nil];
	if (response.success) {
		_sessionID = [response.body valueForComplexKeyPath:@"session.id"];
	}
	return response;
}

- (MTPocketResponse *)logout
{
	NSURL *url = [_url urlWithModule:@"identity" version:2 resource:@"logout" identifiers:nil params:0 misc:nil];
	return [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];
}


@end
