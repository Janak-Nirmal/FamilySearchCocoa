//
//  FSEventTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/23/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <NSDate+MTDates.h>
#import <NSDateComponents+MTDates.h>
#import "FSMarriageTests.h"
#import "FSURL.h"
#import "FSUser.h"
#import "FSPerson.h"
#import "FSEvent.h"
#import "FSMarriage.h"
#import "constants.h"
#import "private.h"

@interface FSMarriageTests ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end

@implementation FSMarriageTests

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

- (void)testAddAndRemoveMarriageEvent
{
	MTPocketResponse *response = nil;

	// assert person has no spouses to start with
	STAssertTrue(_person.marriages.count == 0, nil);

	// add a spouse
	FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:nil];
	spouse.name = @"She Guest";
	spouse.gender = @"Female";
	FSMarriage *marriage = [FSMarriage marriageWithHusband:(spouse.isMale ? spouse : _person) wife:(spouse.isMale ? _person : spouse)];
	[_person addMarriage:marriage];
	response = [_person save];
	STAssertTrue(response.success, nil);
	STAssertTrue(_person.marriages.count == 1, nil);

	// add event to marriage
	FSMarriageEvent *event = [FSMarriageEvent marriageEventWithType:FSMarriageEventTypeMarriage identifier:nil];
	event.date = [NSDateComponents componentsFromString:@"11 August 1994"];
	event.place = @"Kennewick, WA";
	[marriage addMarriageEvent:event];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// assert marriage event was added
	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(_person.marriages.count == 1, nil);
	FSMarriage *m = [person marriageWithSpouse:spouse];
	[m fetch];
	STAssertTrue(m.events.count == 1, nil);

	// remove marriage event
	[m removeMarriageEvent:event];
	response = [person save];
	STAssertTrue(response.success, nil);

	// assert marriage event was removed
	person = [FSPerson personWithSessionID:_sessionID identifier:person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.children.count == 0, nil);
	FSMarriage *m2 = [person marriageWithSpouse:spouse];
	STAssertTrue(m2.events.count == 0, nil);
}

- (void)testAddCharacteristicsToMarriage
{
	MTPocketResponse *response;

	// add a spouse
	FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:nil];
	spouse.name = @"She Guest";
	spouse.gender = @"Female";
	FSMarriage *marriage = [FSMarriage marriageWithHusband:_person wife:spouse];
	[_person addMarriage:marriage];
	response = [_person save];
	STAssertTrue(response.success, nil);
	STAssertTrue(_person.marriages.count == 1, nil);

	// add the properties
	[marriage setCharacteristic:@"2" forKey:FSMarriageCharacteristicTypeNumberOfChildren];
	[marriage setCharacteristic:@"True" forKey:FSMarriageCharacteristicTypeCommonLawMarriage];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// read and check the properties were added on the server
	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	FSMarriage *m = [person marriageWithSpouse:spouse];
	[m fetch];
	STAssertTrue([[m characteristicForKey:FSMarriageCharacteristicTypeNumberOfChildren] isEqualToString:@"2"], nil);
	STAssertTrue([[m characteristicForKey:FSMarriageCharacteristicTypeCommonLawMarriage] isEqualToString:@"True"], nil);
}



@end
