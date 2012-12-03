//
//  FSUserTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSUserTests.h"
#import "FSUser.h"
#import "FSPerson.h"
#import "FSURL.h"
#import "constants.h"


@implementation FSUserTests

- (void)testGetSessionID
{
	[FSURL setSandboxed:YES];
	
	FSUser *user = [[FSUser alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
	MTPocketResponse *response = [user loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];

	STAssertNotNil(response.body, @"sessionID was nil");
}

- (void)testLogout
{
	FSUser *user = [[FSUser alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
	MTPocketResponse *response = [user loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];
    STAssertTrue(response.success, nil);

    response = [user logout];
	STAssertTrue(response.success, nil);
}

- (void)testFetch
{
    FSUser *user = [[FSUser alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
    MTPocketResponse *response = [user loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];
    STAssertTrue(response.success, nil);

    response = [user fetch];
    STAssertTrue(response.success, nil);
    STAssertNotNil(user.info[FSUserInfoNameKey], nil);
    STAssertNotNil(user.info[FSUserInfoUsernameKey], nil);
    STAssertNotNil(user.info[FSUserInfoIDKey], nil);
    STAssertNotNil(user.info[FSUserInfoMembershipIDKey], nil);
    STAssertTrue([user.permissions[FSUserPermissionAccess] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionView] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionModify] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionViewLDSInformation] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionModifyLDSInformation] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionAccessLDSInterface] boolValue], nil);
    STAssertTrue([user.permissions[FSUserPermissionAccessDiscussionForums] boolValue], nil);
}

@end
