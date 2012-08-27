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
#import "constants.h"


@implementation FSAuthTests

- (void)testGetSessionID
{
	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:DEV_KEY sandboxed:SANDBOXED];
	MTPocketResponse *response = [auth sessionIDFromLoginWithUsername:USERNAME password:PASSWORD];

	STAssertNotNil(response.body, @"sessionID was nil");
	STAssertFalse([response.body isEqualToString:@""], @"sessionID was empty");
}

- (void)testLogout
{
	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:DEV_KEY sandboxed:SANDBOXED];
	[auth sessionIDFromLoginWithUsername:USERNAME password:PASSWORD];
	MTPocketResponse *response = [auth logout];

	STAssertTrue(response.success, nil);
}

@end
