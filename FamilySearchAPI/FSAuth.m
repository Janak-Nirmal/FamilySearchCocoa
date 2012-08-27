//
//  FamilySearchAPI.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSAuth.h"
#import "config.h"




@interface FSAuth ()
@property (strong, nonatomic) NSString *devKey;
@property (strong, nonatomic) NSString *sessionID;
@end







@implementation FSAuth


- (id)initWithDeveloperKey:(NSString *)devKey
{
    self = [super init];
    if (self) {
		_devKey = devKey;
    }
    return self;
}

- (MTPocketResponse *)sessionIDFromLoginWithUsername:(NSString *)un password:(NSString *)pw
{	
	NSString *path = [NSString stringWithFormat:@"identity/v2/login"];
	NSString *query = [NSString stringWithFormat:@"key=%@&agent=%@", _devKey, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:AUTH_URL];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON username:un password:pw body:nil];
	_sessionID = [response.body valueForKeyPath:@"session.id"];
	response.body = _sessionID;

	return response;
}

- (MTPocketResponse *)logout
{
	NSString *path = [NSString stringWithFormat:@"logout"];
	NSString *query = [NSString stringWithFormat:@"sessionId=%@&agent=%@", _sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:AUTH_URL];
	return [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];
}


@end
