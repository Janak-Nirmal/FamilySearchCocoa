//
//  FSPersonTests.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/3/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSPersonTests.h"
#import "FSAuth.h"
#import "FSPerson.h"
#import "constants.h"


@interface FSPersonTests ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end


@implementation FSPersonTests

- (void)setUp
{
	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:DEV_KEY sandboxed:SANDBOXED];
	_sessionID = [auth sessionIDFromLoginWithUsername:USERNAME password:PASSWORD].body;

	_person = [FSPerson personWithSessionID:_sessionID identifier:nil];
	_person.name = @"Adam Kirk";
	_person.gender = @"Male";
	MTPocketResponse *response = [_person save];
	STAssertTrue(response.success, nil);
}

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
//
//- (void)testPersonFetch
//{
//	MTPocketResponse *response = [_person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertNotNil(_person.identifier, nil);
//	STAssertTrue([_person.name isEqualToString:@"Adam Kirk"], nil);
//	STAssertTrue([_person.gender isEqualToString:@"Male"], nil);
//}

- (void)testFetchAncestors
{
	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:@"H2KN-XPL8-JJSV-RN76-6D36-WJPV-T2BP-BT6X" sandboxed:NO];
	_sessionID = [auth sessionIDFromLoginWithUsername:@"KirkAT" password:@"georgia1107325"].body;
	_person = [FSPerson currentUserWithSessionID:_sessionID];
	
	MTPocketResponse *response = [_person fetchAncestors:3];
	STAssertTrue(response.success, nil);
}

//- (void)testAddPropertiesToPerson
//{
//	MTPocketResponse *response;
//
//	// add the properties
//	[_person setProperty:@"Kirk" forKey:FSPropertyTypeCasteName];
//	[_person setProperty:@"Programmer" forKey:FSPropertyTypeOccupation];
//	response = [_person save];
//	STAssertTrue(response.success, nil);
//
//	// read and check the properties were added on the server
//	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue([[person propertyForKey:FSPropertyTypeCasteName] isEqualToString:@"Kirk"], nil);
//	STAssertTrue([[person propertyForKey:FSPropertyTypeOccupation] isEqualToString:@"Programmer"], nil);
//}
//
//- (void)testAddAndRemoveFather
//{
//	MTPocketResponse *response;
//
//	// create and add the father
//	FSPerson *father = [FSPerson personWithSessionID:_sessionID identifier:nil];
//	father.name = @"Nathan Kirk";
//	father.gender = @"Male";
//
//	[_person addParent:father withLineage:FSLineageTypeBiological];
//	response = [_person save];
//	STAssertTrue(response.success, nil);
//
//	// assert father was added
//	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.parents.count == 1, nil);
//
//	[person removeParent:father];
//	response = [person save];
//	STAssertTrue(response.success, nil);
//
//	// assert father was removed
//	person = [FSPerson personWithSessionID:_sessionID identifier:person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.parents.count == 0, nil);
//}
//
//- (void)testAddAndRemoveMother
//{
//	MTPocketResponse *response;
//
//	// create and add the mother
//	FSPerson *mother = [FSPerson personWithSessionID:_sessionID identifier:nil];
//	mother.name = @"Jackie Kirk";
//	mother.gender = @"Female";
//
//	[_person addParent:mother withLineage:FSLineageTypeBiological];
//	response = [_person save];
//	STAssertTrue(response.success, nil);
//
//	// assert mother was added
//	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.parents.count == 1, nil);
//
//	// remove the mother
//	[person removeParent:mother];
//	response = [person save];
//	STAssertTrue(response.success, nil);
//
//	// assert mother was removed
//	person = [FSPerson personWithSessionID:_sessionID identifier:person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.parents.count == 0, nil);
//
//}
//
//- (void)testAddMotherAndFather
//{
//	MTPocketResponse *response;
//
//	// create and add the father
//	FSPerson *father = [FSPerson personWithSessionID:_sessionID identifier:nil];
//	father.name = @"Nathan Kirk";
//	father.gender = @"Male";
//
//	// create and add the mother
//	FSPerson *mother = [FSPerson personWithSessionID:_sessionID identifier:nil];
//	mother.name = @"Jackie Kirk";
//	mother.gender = @"Female";
//
//	[_person addParent:father withLineage:FSLineageTypeBiological];
//	[_person addParent:mother withLineage:FSLineageTypeBiological];
//	response = [_person save];
//	STAssertTrue(response.success, nil);
//
//	// read the father
//	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.parents.count == 2, nil);
//}
//
//- (void)testAddAndRemoveChild
//{
//	MTPocketResponse *response;
//
//	// create and add the child
//	FSPerson *child = [FSPerson personWithSessionID:_sessionID identifier:nil];
//	child.name = @"Jack Kirk";
//	child.gender = @"Male";
//
//	[_person addChild:child withLineage:FSLineageTypeBiological];
//	response = [_person save];
//	STAssertTrue(response.success, nil);
//
//	// assert child was added
//	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.children.count == 1, nil);
//
//	// remove the child
//	[person removeChild:child];
//	response = [person save];
//	STAssertTrue(response.success, nil);
//
//	// assert child was removed
//	person = [FSPerson personWithSessionID:_sessionID identifier:person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.children.count == 0, nil);
//}
//
//- (void)testAddAndRemoveSpouse
//{
//	MTPocketResponse *response;
//
//	// create and add the spouse
//	FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:nil];
//	spouse.name = @"She Kirk";
//	spouse.gender = @"Female";
//
//	[_person addSpouse:spouse];
//	response = [_person save];
//	STAssertTrue(response.success, nil);
//
//	// assert spouse was added
//	FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:_person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.spouses.count == 1, nil);
//
//	// remove the spouse
//	[person removeSpouse:spouse];
//	response = [person save];
//	STAssertTrue(response.success, nil);
//
//	// assert spouse was removed
//	person = [FSPerson personWithSessionID:_sessionID identifier:person.identifier];
//	response = [person fetch];
//	STAssertTrue(response.success, nil);
//	STAssertTrue(person.spouses.count == 0, nil);
//}



@end
