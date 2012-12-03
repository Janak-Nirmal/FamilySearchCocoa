//
//  FSBugFixes.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 11/2/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSBugFixes.h"
#import "private.h"
#import "FSSearch.h"
#import "constants.h"


@interface FSBugFixes ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end



@implementation FSBugFixes


- (void)setUp
{
	[FSURL setSandboxed:YES];

	FSUser *user = [[FSUser alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
	[user loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];
	_sessionID = user.sessionID;

	_person = [FSPerson personWithSessionID:_sessionID identifier:nil];
	_person.name = @"Adam Kirk";
	_person.gender = @"Male";
	MTPocketResponse *response = [_person save];
	STAssertTrue(response.success, nil);
}

- (void)testAddedMotherAndFatherAreReturnedInPedigree
{
	MTPocketResponse *response = nil;

	FSPerson *father = [FSPerson personWithSessionID:_sessionID identifier:nil];
	father.name = @"Nathan Kirk";
	father.gender = @"Male";
	response = [father save];
	STAssertTrue(response.success, nil);

	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	FSPerson *mother = [FSPerson personWithSessionID:_sessionID identifier:nil];
	mother.name = @"Jackie Taylor";
	mother.gender = @"Female";
	response = [mother save];
	STAssertTrue(response.success, nil);

	[_person addParent:mother withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
	response = [person fetchAncestors:2];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.parents.count == 2, nil);
}

@end