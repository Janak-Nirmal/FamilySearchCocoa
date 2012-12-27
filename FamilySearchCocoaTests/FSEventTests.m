//
//  FSEventTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/23/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <NSDate+MTDates.h>
#import <NSDateComponents+MTDates.h>
#import "FSEventTests.h"
#import "FSUser.h"
#import "FSPerson.h"
#import "FSEvent.h"
#import "FSURL.h"
#import "constants.h"
#import <NSObject+MTJSONUtils.h>

@interface FSEventTests ()
@property (strong, nonatomic) FSPerson *person;
@end

@implementation FSEventTests

- (void)setUp
{
	[FSURL setSandboxed:YES];

	FSUser *user = [[FSUser alloc] initWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD developerKey:SANDBOXED_DEV_KEY];
	[user login];

	_person = [FSPerson personWithIdentifier:nil];
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
	death.date = [NSDateComponents componentsFromString:@"11 August 1995"];
	death.place = @"Kennewick, WA";
	[_person addEvent:death];


	// create and add event to person
	FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeBaptism identifier:nil];
	event.date = [NSDateComponents componentsFromString:@"11 August 1994"];
	event.place = @"Kennewick, WA";
	[_person addEvent:event];
	response = [_person save];
	STAssertTrue(response.success, nil);

	// fetch the person and assert the events were added
	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.events.count == 2, nil);

	// remove the event
	[person removeEvent:event];
	response = [person save];
	STAssertTrue(response.success, nil);

	// assert event was removed
	person = [FSPerson personWithIdentifier:person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.events.count == 1, nil);
}

- (void)testPartialDate
{
	MTPocketResponse *response = nil;
	NSString *dateString = @"July 1995";

	// add a death event so the sytem acknowledges they are dead
	FSEvent *death = [FSEvent eventWithType:FSPersonEventTypeDeath identifier:nil];
	death.date = [NSDateComponents componentsFromString:dateString];
	death.place = @"Kennewick, WA";
	[_person addEvent:death];
	response = [_person save];
	STAssertTrue(response.success, nil);

	response = [_person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue([NILL([response.body valueForComplexKeyPath:@"persons[first].assertions.events[first].value.date.normalized"]) isEqualToString:dateString], nil);
}

- (void)testConvenienceEventMethods
{
	MTPocketResponse *response = nil;

	// assert person has no events to start with
	STAssertTrue(_person.events.count == 0, nil);

	NSDateComponents	*birthDate	= [NSDateComponents componentsFromString:@"11 August 1995"];
	NSString			*birthPlace	= @"Kennewick, Benton, Washington, United States";
	NSDateComponents	*deathDate	= [NSDateComponents componentsFromString:@"11 August 1994"];
	NSString			*deathPlace	= @"Pasco, Franklin, Washington, United States";

	// create and add event to person
	_person.birthDate	= birthDate;
	_person.birthPlace	= birthPlace;

	// add a death event so the sytem acknowledges they are dead
	_person.deathDate	= deathDate;
	_person.deathPlace	= deathPlace;

	response = [_person save];
	STAssertTrue(response.success, nil);

	// fetch the person and assert the events were added
	FSPerson *person = [FSPerson personWithIdentifier:_person.identifier];
	response = [person fetch];
	STAssertTrue(response.success, nil);
	STAssertTrue(person.events.count == 2, nil);

	// read the values
	STAssertTrue([person.birthDate	isEqualToDateComponents:birthDate],	nil);
	STAssertTrue([person.birthPlace isEqualToString:birthPlace],		nil);
	STAssertTrue([person.deathDate	isEqualToDateComponents:deathDate],	nil);
	STAssertTrue([person.deathPlace	isEqualToString:deathPlace],		nil);
}

- (void)testUpdateEvent
{
    MTPocketResponse *response = nil;

    // create and add event to person
	FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeBirth identifier:nil];
	event.date = [NSDateComponents componentsFromString:@"11 August 1994"];
	event.place = @"Kennewick, WA";
	[_person addEvent:event];
	response = [_person save];
	STAssertTrue(response.success, nil);

    // fetch and update the event
    response = [_person fetch];
    STAssertTrue(response.success, nil);
    event = [_person.events lastObject];
    event.place = @"Farmington, UT";

    // update the event
    response = [_person save];
    STAssertTrue(response.success, nil);

    // fetch and update the event (again)
    response = [_person fetch];
    STAssertTrue(response.success, nil);
    event = [_person.events lastObject];
	event.date = [NSDateComponents componentsFromString:@"11 July 1994"];

    response = [_person save];
    STAssertTrue(response.success, nil);

    response = [_person save];
    STAssertTrue(response.success, nil);
}


@end
