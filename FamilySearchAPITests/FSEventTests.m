//
//  FSEventTests.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/23/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <NSDate+MTDates.h>
#import "FSEventTests.h"
#import "FSAuth.h"
#import "FSPerson.h"
#import "FSEvent.h"
#import "constants.h"

@interface FSEventTests ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end

@implementation FSEventTests

- (void)setUp
{
	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:DEV_KEY];
	_sessionID = [auth sessionIDFromLoginWithUsername:USERNAME password:PASSWORD].body;

	_person = [FSPerson personWithSessionID:_sessionID identifier:nil];
	_person.name = @"Adam Kirk";
	_person.gender = @"Male";
	MTPocketResponse *response = [_person save];
	STAssertTrue(response.success, nil);
}

- (void)testAddAndRemoveEvent
{
	MTPocketResponse *response = nil;

	// assert person has no events to start with
	STAssertTrue(_person.events.count == 0, nil);

	// add a death event so the sytem acknowledges they are dead
	FSEvent *death = [FSEvent eventWithType:FSPersonEventTypeDeath identifier:nil];
	death.date = [NSDate dateFromYear:1995 month:8 day:11 hour:10 minute:0];
	death.place = @"Kennewick, WA";
	[_person addEvent:death];


	// create and add event to person
	FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeBaptism identifier:nil];
	event.date = [NSDate dateFromYear:1994 month:8 day:11 hour:10 minute:0];
	event.place = @"Kennewick, WA";
	[_person addEvent:event];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// fetch the person and assert the events were added
	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.events.count == 2, nil);

	// remove the event
	[person removeEvent:event];
	response = [person save];
	STAssertTrue(response.success, nil);

	// assert event was removed
	person = [FSPerson personWithSessionID:_sessionID identifier:person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.events.count == 1, nil);
}

@end
