//
//  FSOrdinanceTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 9/10/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSOrdinanceTests.h"
#import <NSDate+MTDates.h>
#import <NSDateComponents+MTDates.h>
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

- (void)testFetchGetsOrdinances
{
	MTPocketResponse *response = nil;

	FSPerson *father = [FSPerson personWithSessionID:_sessionID identifier:nil];
	father.name = @"Nathan Kirk";
	father.gender = @"Male";
	father.deathDate = [NSDateComponents componentsFromString:@"11 November 1970"];

	STAssertTrue(_person.ordinances.count == 0, nil);

	[father addUnofficialOrdinanceWithType:FSOrdinanceTypeEndowment date:[NSDate dateFromYear:1998 month:2 day:3] templeCode:@"SLAKE"];

	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	response = [father fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(father.ordinances.count == 1, nil);
}

- (void)testFetchingAllOrdinances
{
	MTPocketResponse *response = nil;

	FSPerson *father = [FSPerson personWithSessionID:_sessionID identifier:nil];
	father.name			= @"Nathan Kirk";
	father.gender		= @"Male";
	father.deathDate	= [NSDateComponents componentsFromString:@"11 November 1970"];
	father.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	response = [father fetch];
	STAssertTrue(response.success, nil);

	NSUInteger startOrdinances = father.ordinances.count;

	response = [FSOrdinance fetchOrdinancesForPeople:@[father]];
	STAssertTrue(response.success, nil);
	STAssertTrue(father.ordinances.count == startOrdinances + 4, nil);
}

- (void)testReserveAndUnreserveOrdinances
{
	MTPocketResponse *response = nil;

	FSPerson *father = [FSPerson personWithSessionID:_sessionID identifier:nil];
	father.name			= @"Nathan Kirk";
	father.gender		= @"Male";
	father.deathDate	= [NSDateComponents componentsFromString:@"11 November 1970"];
	father.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[_person addParent:father withLineage:FSLineageTypeBiological];
	response = [_person save];
	STAssertTrue(response.success, nil);

	FSPerson *gFather	= [FSPerson personWithSessionID:_sessionID identifier:nil];
	gFather.name		= @"Nathan Kirk";
	gFather.gender		= @"Male";
	gFather.deathDate	= [NSDateComponents componentsFromString:@"11 November 1910"];
	gFather.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[father addParent:gFather withLineage:FSLineageTypeBiological];
	response = [father save];
	STAssertTrue(response.success, nil);

	FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:nil];
	spouse.name = @"She Kirk";
	spouse.gender = @"Female";
	spouse.deathDate	= [NSDateComponents componentsFromString:@"11 November 1909"];
	spouse.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[father addMarriage:[FSMarriage marriageWithHusband:father wife:spouse]];
	response = [father save];
	STAssertTrue(response.success, nil);

	response = [father fetch];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance fetchOrdinancesForPeople:@[father]];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance reserveOrdinancesForPeople:@[ father ] inventory:FSOrdinanceInventoryTypePersonal];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance fetchOrdinancesForPeople:@[father]];
	STAssertTrue(response.success, nil);

	NSMutableArray *reservedOrdinances = [NSMutableArray array];
	for (FSOrdinance *ordinance in father.ordinances) {
		if ([ordinance.status isEqualToString:FSOrdinanceStatusReserved]) [reservedOrdinances addObject:ordinance];
	}
	STAssertTrue(reservedOrdinances.count > 0, nil);

	response = [FSOrdinance unreserveOrdinancesForPeople: @[ father ] ];
	STAssertTrue(response.success, nil);

	response = [FSOrdinance fetchOrdinancesForPeople: @[ father ] ];
	STAssertTrue(response.success, nil);

	reservedOrdinances = [NSMutableArray array];
	for (FSOrdinance *ordinance in father.ordinances) {
		if ([ordinance.status isEqualToString:FSOrdinanceStatusReserved]) [reservedOrdinances addObject:ordinance];
	}
	STAssertTrue(reservedOrdinances.count == 0, nil);
}

- (void)testFetchListOfReservedPeopleByCurrentUser
{
	MTPocketResponse *response = nil;

	NSArray *people = nil;
	response = [FSOrdinance people:&people reservedByCurrentUserWithSessionID:_sessionID];
	STAssertTrue(response.success, nil);
	STAssertNotNil(people, nil);
	STAssertTrue(people.count > 0, nil);

	response = [FSOrdinance fetchOrdinancesForPeople:people];
	STAssertTrue(response.success, nil);

	FSPerson *anyPerson = [people lastObject];
	STAssertTrue(anyPerson.ordinances > 0, nil);
}

- (void)testFetchFamilyOrdinanceRequestPDFURL
{
	MTPocketResponse *response = nil;

	NSArray *people = nil;
	response = [FSOrdinance people:&people reservedByCurrentUserWithSessionID:_sessionID];
	STAssertTrue(response.success, nil);

	NSURL *url = [FSOrdinance familyOrdinanceRequestPDFURLForPeople:people response:&response];

	STAssertTrue(response.success, nil);
	STAssertNotNil(url, nil);
}

@end




