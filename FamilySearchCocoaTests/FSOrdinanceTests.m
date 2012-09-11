//
//  FSOrdinanceTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 9/10/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSOrdinanceTests.h"
#import <NSDate+MTDates.h>
#import "FSURL.h"
#import "FSAuth.h"
#import "FSPerson.h"
#import "FSEvent.h"
#import "FSMarriage.h"
#import "constants.h"

@interface FSOrdinanceTests ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end


@implementation FSOrdinanceTests

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

//- (void)testFetchGetsOrdinances
//{
//	MTPocketResponse *response = nil;
//
//	FSPerson *father = [FSPerson personWithSessionID:_sessionID identifier:nil];
//	father.name = @"Nathan Kirk";
//	father.gender = @"Male";
//	father.deathDate = [NSDate dateFromYear:1970 month:11 day:11];
//
//	[_person addParent:father withLineage:FSLineageTypeBiological];
//	response = [_person save];
//	STAssertTrue(response.success, nil);
//
//	FSPerson *parent            = [_person.parents lastObject];
//
//	STAssertTrue(ggGrandParent.ordinances.count == 0, nil);
//
//	response = [ggGrandParent fetch];
//	STAssertTrue(response.success, nil);
//
//	STAssertTrue(ggGrandParent.ordinances.count == 0, nil);
//}

@end
