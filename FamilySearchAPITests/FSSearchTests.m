//
//  FSSearchTests.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 9/6/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSSearchTests.h"
#import "private.h"
#import "FSSearch.h"
#import "constants.h"


@interface FSSearchTests ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end


@implementation FSSearchTests

- (void)setUp
{
	[FSURL setSandboxed:YES];

	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
	[auth loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];
	_sessionID = auth.sessionID;

	_person = [FSPerson personWithSessionID:_sessionID identifier:nil];
	_person.name = @"Adam Kirk";
	_person.gender = @"Male";
	MTPocketResponse *response = [_person save];
	STAssertTrue(response.success, nil);
}

- (void)testSearch
{
	FSSearch *search = [[FSSearch alloc] initWithSessionID:_sessionID];
	[search addValue:@"Nathan" forCriteria:FSSearchCriteriaName onRelative:FSSearchRelativeTypeSelf matchingExactly:NO];
	FSSearchResults *results = [search results];

	MTPocketResponse *response = [results next];
	if (response.success) {
		for (FSPerson *p in results) {
			NSLog(@"%@", p.name);
		}
	}
}



@end
