//
//  FSAuthTests.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSAuthTests.h"
#import "FSAuth.h"
#import "FSPerson.h"
#import "FSURL.h"
#import "constants.h"


@implementation FSAuthTests

- (void)testGetSessionID
{
	[FSURL setSandboxed:YES];
	
	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
	MTPocketResponse *response = [auth loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];

	STAssertNotNil(response.body, @"sessionID was nil");
}

- (void)testLogout
{
	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
	[auth loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];
	MTPocketResponse *response = [auth logout];

	STAssertTrue(response.success, nil);
}

@end
