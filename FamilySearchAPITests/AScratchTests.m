//
//  0ScratchTests.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 9/7/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "AScratchTests.h"
#import "FSURL.h"
#import "FSAuth.h"
#import "FSPerson.h"
#import "constants.h"
#import <NSDate+MTDates.h>


@interface AScratchTests ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end

@implementation AScratchTests


//- (void)setUp
//{
//	[FSURL setSandboxed:YES];
//
//	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
//	[auth loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];
//	_sessionID = auth.sessionID;
//
//	_person = [FSPerson personWithSessionID:_sessionID identifier:nil];
//	_person.name = @"Adam Kirk";
//	_person.gender = @"Male";
//	MTPocketResponse *response = [_person save];
//	STAssertTrue(response.success, nil);
//}
//
//- (void)testCurrentUserFetch
//{
//	MTPocketResponse *response = nil;
//
//	@try {
//		FSPerson *p = [FSPerson personWithSessionID:_sessionID identifier:nil];
//		[p fetch];
//		STFail(@"Was able to fetch person with nil identifier");
//	}
//	@catch (NSException *exception) {
//
//	}
//
//	FSPerson *me = [FSPerson currentUserWithSessionID:_sessionID];
//	FSPerson *me2 = [FSPerson currentUserWithSessionID:_sessionID];
//	STAssertTrue(me == me2, nil);
//
//	response = [me fetch];
//	response = [me2 fetch];
//	STAssertTrue(me == me2, nil);
//	STAssertTrue(response.success, nil);
//	STAssertNotNil(me.identifier, nil);
//	STAssertNotNil(me.name, nil);
//	STAssertNotNil(me.gender, nil);
//}

@end
