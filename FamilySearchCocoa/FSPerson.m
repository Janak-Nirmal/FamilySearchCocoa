//
//  FSPerson.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSPerson.h"
#import "private.h"
#import <NSDate+MTDates.h>
#import <NSObject+MTJSONUtils.h>







@interface FSPerson ()
@property (strong, nonatomic)	FSURL				*url;
@property (strong, nonatomic)	NSMutableDictionary	*properties;
@property (strong, nonatomic)	NSMutableArray		*relationships;
@property (strong, nonatomic)	NSMutableArray		*marriages;
@end





@interface FSRelationship : NSObject
@property (strong, nonatomic)	FSURL			*url;
@property (readonly)			FSPerson		*parent;
@property (readonly)			FSPerson		*child;
@property (readonly)			FSLineageType	lineage;
@property (getter = isChanged)	BOOL			changed;	// is newly created or updated and needs to be updated on the server
@property (getter = isDeleted)	BOOL			deleted;	// has been deleted and needs to be deleted from the server
+ (FSRelationship *)relationshipWithParent:(FSPerson *)parent child:(FSPerson *)child lineage:(FSLineageType)lineage;
- (MTPocketResponse *)save;
- (MTPocketResponse *)destroy;
@end












@implementation FSPerson

@synthesize events = _events;




#pragma mark - Constructor

- (id)initWithSessionID:(NSString *)sessionID identifier:(NSString *)identifier
{
	static NSMutableArray *__people;
	if (!__people) __people = [[NSMutableArray alloc] initWithCapacity:0];

	for (FSPerson *person in __people) {
		if ([person.identifier isEqualToString:identifier]) {
			return person;
		}
	}

	self = [super init];
	if (self) {
		_sessionID		= sessionID;
		_url			= [[FSURL alloc] initWithSessionID:sessionID];
		_identifier		= identifier;
		_name			= nil;
		_gender			= @"Male";
		_isAlive		= NO;
		_relationships	= [NSMutableArray array];
		_properties		= [NSMutableDictionary dictionary];
		_marriages		= [NSMutableArray array];
		_events			= [NSMutableArray array];
		_ordinances		= [NSMutableArray array];
		[__people addObject:self];
	}
	return self;
}

+ (FSPerson *)personWithSessionID:(NSString *)sessionID identifier:(NSString *)identifier
{
	return [[FSPerson alloc] initWithSessionID:sessionID identifier:identifier];
}

+ (FSPerson *)currentUserWithSessionID:(NSString *)sessionID
{
	static FSPerson *__me;
	if (!__me || ![__me.sessionID isEqualToString:sessionID]) __me = [[FSPerson alloc] initWithSessionID:sessionID identifier:@"me"];
	return __me;
}




#pragma mark - Syncing

- (BOOL)isNew
{
	return _identifier == nil;
}

- (MTPocketResponse *)fetch
{
	if (!_identifier) raiseException(@"Nil 'identifier'", @"You cannot fetch on a person with a nil identifier." );
	if ([_identifier isEqualToString:@"me"]) _identifier = nil;

	MTPocketResponse *response = [FSPerson batchFetchPeople:@[ self ]];

	// Fetch marriage properties and events
	if (response.success) {
		for (FSPerson *spouse in self.spouses) {
			FSMarriage *marriage = [self marriageWithSpouse:spouse];
			[marriage fetch];
		}
	}
	return response;
}

- (MTPocketResponse *)save
{
	NSMutableDictionary *assertions = [NSMutableDictionary dictionary];


	// NAME
	if (_name) {
		NSDictionary *nameDict = @{
								@"names" : @[ @{
									@"value" : @{
										@"forms" : @[ @{
											@"fullText" : _name
										}]
									}
								}]
							};
		[assertions addEntriesFromDictionary:nameDict];
	}


	// GENDER
	if (_gender) {
		NSDictionary *genderDict = @{
									@"genders" : @[ @{
										@"value" : @{
											@"type" : _gender
										}
									}]
								};
		[assertions addEntriesFromDictionary:genderDict];
	}


	// PROPERTIES
	NSMutableArray *characteristics = [NSMutableArray array];
	for (FSPropertyType key in [_properties allKeys]) {
		FSProperty *property = _properties[key];
		NSMutableDictionary *characteristic = [NSMutableDictionary dictionary];
		if (property.identifier) characteristic[@"id"] = property.identifier;
		if (property.key) characteristic[@"type"] = property.key;
		if (property.value) characteristic[@"detail"] = property.value;
		[characteristics addObject: @{ @"value" : characteristic } ];
	}
	[assertions addEntriesFromDictionary: @{ @"characteristics" : characteristics } ];


	// EVENTS
	NSMutableArray *events = [NSMutableArray array];
	for (FSEvent *event in _events) {
		NSMutableDictionary *eventInfo = [NSMutableDictionary dictionaryWithObject:event.type forKey:@"type"];
		if (event.date)		eventInfo[@"date"] = @{ @"original" : event.date };
		if (event.place)	eventInfo[@"place"] = @{ @"original" : event.place };

		if (event.date || event.place) {
			if (event.identifier) {
				eventInfo[@"id"] = event.identifier;
				if (event.isDeleted)
					[events addObject: @{ @"value" : eventInfo, @"action" : @"Delete" } ];
				else
					[events addObject: @{ @"value" : eventInfo, @"tempId" : event.localIdentifier } ];
			}
			else {
				[events addObject: @{ @"value" : eventInfo, @"tempId" : event.localIdentifier } ]; // TODO: figure out why tempId is not coming back
			}
		}
	}
	if (events.count > 0) [assertions addEntriesFromDictionary: @{ @"events" : events } ];

	// ORDINANCES
	NSMutableArray *ordinances = [NSMutableArray array];
	for (FSOrdinance *ordinance in _ordinances) {
		if (!ordinance.userAdded) continue;
		NSMutableDictionary *ordinanceInfo = [NSMutableDictionary dictionaryWithObject:ordinance.type forKey:@"type"];
		if (ordinance.type)			ordinanceInfo[@"type"] = ordinance.type;
		if (ordinance.date)			ordinanceInfo[@"date"] = @{ @"original" : ordinance.date };
		if (ordinance.templeCode)	ordinanceInfo[@"temple"] = ordinance.templeCode;

		if (ordinance.type && ordinance.date) {
			[ordinances addObject: @{ @"value" : ordinanceInfo } ];
		}
	}
	if (ordinances.count > 0) [assertions addEntriesFromDictionary: @{ @"ordinances" : ordinances } ];

	// SAVE
	NSURL *url = [_url urlWithModule:@"familytree"
							 version:2
							resource:@"person"
						 identifiers:(_identifier ? @[ _identifier ] : nil)
							  params:defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics
								misc:nil];

	NSMutableDictionary *personDict = [NSMutableDictionary dictionary];
	if (_identifier)				personDict[@"id"] = _identifier;
	if (assertions.count > 0)		personDict[@"assertions"] = assertions;

	NSDictionary *body = @{ @"persons" : @[ personDict ] };
	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body];

	// if newly created person, assign id and link relationships
	if (response.success) {

		if (!_identifier) {
			_identifier = [response.body valueForComplexKeyPath:@"persons[first].id"];
		}

		for (FSProperty *property in [_properties allValues]) {
			[property markAsSaved];
		}

		for (FSEvent *event in [_events copy]) {
			if (event.isDeleted) [(NSMutableArray *)_events removeObject:event];
		}

		// RELATIONSHIPS
		for (FSRelationship *relationship in _relationships) {
			if (relationship.isChanged || relationship.isDeleted) {
				[relationship save];
			}
		}

		// MARRIAGES
		for (FSMarriage *marriage in _marriages) {
			if (marriage.isChanged || marriage.isDeleted) {
				[marriage save];
			}
		}
	}

	return response;
}

- (MTPocketResponse *)fetchAncestors:(NSUInteger)generations
{
	if (!_identifier) raiseException(@"Nil identifier", @"You cannot fetch ancestors when the persons 'identifier' is nil");

	NSURL *url = [_url urlWithModule:@"familytree"
							  version:2
							 resource:@"pedigree"
						  identifiers:(_identifier ? @[ _identifier ] : nil)
							   params:0
								 misc:[NSString stringWithFormat:@"ancestors=%d&properties=all", generations]];
	
	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSDictionary *pedigree = [response.body valueForComplexKeyPath:@"pedigrees[first]"];
		NSArray *people = pedigree[@"persons"];
		for (NSDictionary *personDict in people) {
			FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:personDict[@"id"]];

			// GENERAL
			person.name		= [personDict valueForComplexKeyPath:@"assertions.names[first].value.forms[first].fullText"];
			person.gender	= [personDict valueForComplexKeyPath:@"assertions.genders[first].value.type"];

			// PARENTS
			NSArray *parents = [personDict valueForComplexKeyPath:@"parents[first].parent"];
			for (NSDictionary *parentDict in parents) {
				FSPerson *parent = [FSPerson personWithSessionID:_sessionID identifier:parentDict[@"id"]];
				parent.gender = parentDict[@"gender"];
				[person addParent:parent withLineage:FSLineageTypeBiological];
			}

			// EVENTS
			NSString *birth = [personDict valueForComplexKeyPath:@"properties.lifespan.birth.text"];
			NSString *death = [personDict valueForComplexKeyPath:@"properties.lifespan.death.text"];

			if ([birth isKindOfClass:[NSString class]]) {
				FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeBirth identifier:nil];
				event.date = [NSDate dateFromString:birth usingFormat:DATE_FORMAT];
				event.place = nil;
				[person addEvent:event];
			}

			if ([death isKindOfClass:[NSString class]]) {
				FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeDeath identifier:nil];
				event.date = [NSDate dateFromString:death usingFormat:DATE_FORMAT];
				event.place = nil;
				[person addEvent:event];
			}
		}
	}

	return response;
}




#pragma mark - Properties

- (NSString *)propertyForKey:(FSPropertyType)key
{
	FSProperty *property = _properties[key];
	return property.value;
}

- (void)setProperty:(NSString *)property forKey:(FSPropertyType)key
{
	FSProperty *p = _properties[key];
	if (!p) {
		p = [[FSProperty alloc] init];
		p.identifier = nil;
		p.key = key;
		_properties[key] = p;
	}
	p.value = property;
}

- (void)reset
{
	for (FSProperty *property in [_properties allValues]) {
		[property reset];
	}
}




#pragma mark - Parents

- (NSArray *)parents
{
	NSMutableArray *parents = [NSMutableArray array];
	for (FSRelationship *relationship in _relationships) {
		if ([relationship.child isSamePerson:self] && !relationship.isDeleted) {
			[parents addObject:relationship.parent];
		}
	}
	return parents;
}

- (void)addParent:(FSPerson *)parent withLineage:(FSLineageType)lineage
{
	if (!parent) raiseParamException(@"parent");

	FSRelationship *relationship = [FSRelationship relationshipWithParent:parent child:self lineage:lineage];
	relationship.changed = YES;
	[self addRelationship:relationship];
}

- (void)removeParent:(FSPerson *)parent
{
	for (FSRelationship *relationship in _relationships) {
		if ([relationship.parent isSamePerson:parent]) {
			relationship.deleted = YES;
		}
	}
}




#pragma mark - Children

- (NSArray *)children
{
	NSMutableArray *children = [NSMutableArray array];
	for (FSRelationship *relationship in _relationships) {
		if ([relationship.parent isSamePerson:self] && !relationship.isDeleted) {
			[children addObject:relationship.child];
		}
	}
	return children;
}

- (void)addChild:(FSPerson *)child withLineage:(FSLineageType)lineage
{
	if (!child) raiseParamException(@"spouse");
	if (!lineage) raiseParamException(@"lineage");

	[child addParent:self withLineage:lineage];
}

- (void)removeChild:(FSPerson *)person
{
	[person removeParent:self];
}




#pragma mark - Spouses

- (NSArray *)spouses
{
	NSMutableArray *spouses = [NSMutableArray array];
	for (FSMarriage *marriage in _marriages) {
		if (!marriage.isDeleted) {
			if ([marriage.husband isSamePerson:self])
				[spouses addObject:marriage.wife];
			if ([marriage.wife isSamePerson:self])
				[spouses addObject:marriage.husband];
		}
	}
	return spouses;
}

- (FSMarriage *)addSpouse:(FSPerson *)spouse
{
	if (!spouse) raiseParamException(@"spouse");

	FSMarriage *marriage = [FSMarriage marriageWithHusband:(self.isMale ? self : spouse)	wife:(self.isMale ? spouse : self)];
	marriage.changed = YES;
	[self addMarriage:marriage];
	return marriage;
}

- (FSMarriage *)marriageWithSpouse:(FSPerson *)spouse
{
	for (FSMarriage *marriage in _marriages) {
		if ([marriage.husband isSamePerson:spouse] || [marriage.wife isSamePerson:spouse])
			return marriage;
	}
	return nil;
}

- (void)removeSpouse:(FSPerson *)spouse;
{
	if (!spouse) raiseParamException(@"spouse");

	for (FSMarriage *marriage in _marriages) {
		if ([marriage.wife isSamePerson:spouse] || [marriage.husband isSamePerson:spouse]) {
			marriage.deleted = YES;
		}
	}
}




#pragma mark - Events

- (NSArray *)events
{
	NSMutableArray *events = [NSMutableArray array];
	for (FSEvent *e in _events) {
		if (!e.isDeleted) [events addObject:e];
	}
	return events;
}

- (void)addEvent:(FSEvent *)event
{
	if (!event) raiseParamException(@"event");

	for (FSEvent *e in _events) {
		if ([e isEqualToEvent:event]) {
			((NSMutableArray *)_events)[[_events indexOfObject:e]] = event;
			return;
		}
	}
	[(NSMutableArray *)_events addObject:event];
}

- (void)removeEvent:(FSEvent *)event
{
	for (FSEvent *e in _events) {
		if ([event isEqualToEvent:e])
			e.deleted = YES;
	}
}

- (NSDate *)birthDate							{ return [self dateForEventOfType:FSPersonEventTypeBirth];						}
- (void)setBirthDate:(NSDate *)birthDate		{ [self setDate:birthDate place:nil forEventOfType:FSPersonEventTypeBirth];		}
- (NSString *)birthPlace						{ return [self placeForEventOfType:FSPersonEventTypeBirth];						}
- (void)setBirthPlace:(NSString *)birthPlace	{ [self setDate:nil place:birthPlace forEventOfType:FSPersonEventTypeBirth];	}
- (NSDate *)deathDate							{ return [self dateForEventOfType:FSPersonEventTypeDeath];						}
- (void)setDeathDate:(NSDate *)deathDate		{ [self setDate:deathDate place:nil forEventOfType:FSPersonEventTypeDeath];		}
- (NSString *)deathPlace						{ return [self placeForEventOfType:FSPersonEventTypeDeath];						}
- (void)setDeathPlace:(NSString *)deathPlace	{ [self setDate:nil place:deathPlace forEventOfType:FSPersonEventTypeDeath];	}




#pragma mark - Misc

- (MTPocketResponse *)duplicates:(NSArray **)duplicates
{
	if (!_identifier) raiseException(@"Nil 'identifier'", @"The persons 'identifier' cannot be nil to find duplicates");
	*duplicates = [[NSMutableArray alloc] init];

	NSURL *url = [_url urlWithModule:@"familytree"
							 version:2
							resource:@"match"
						 identifiers:@[ _identifier ]
							  params:0
								misc:nil];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSDictionary *search = [response.body valueForComplexKeyPath:@"matches[first]"];
		NSArray *searches = [search valueForComplexKeyPath:@"match"];
		for (NSDictionary *searchDictionary in searches) {
			NSDictionary *personDictionary = searchDictionary[@"person"];
			FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:personDictionary[@"id"]];
			[person populateFromPersonDictionary:personDictionary];

			// Add parents
			NSArray *parents = personDictionary[@"parent"];
			for (NSDictionary *parentDictionary in parents) {
				FSPerson *parent = [FSPerson personWithSessionID:_sessionID identifier:parentDictionary[@"id"]];
				[parent populateFromPersonDictionary:parentDictionary];
				[person addParent:parent withLineage:FSLineageTypeBiological];
			}

			// Add children
			NSArray *children = personDictionary[@"child"];
			for (NSDictionary *childDictionary in children) {
				FSPerson *child = [FSPerson personWithSessionID:_sessionID identifier:childDictionary[@"id"]];
				[child populateFromPersonDictionary:childDictionary];
				[person addChild:child withLineage:FSLineageTypeBiological];
			}

			// Add spouses
			NSArray *spouses = personDictionary[@"spouse"];
			for (NSDictionary *spouseDictionary in spouses) {
				FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:spouseDictionary[@"id"]];
				[spouse populateFromPersonDictionary:spouseDictionary];
				[person addSpouse:spouse];
			}

			[(NSMutableArray *)*duplicates addObject:person];
		}
	}
	
	return response;
}

- (void)addUnofficialOrdinanceWithType:(FSOrdinanceType)type date:(NSDate *)date templeCode:(NSString *)templeCode
{
	if (!type) raiseParamException(@"type");
	if (!date) raiseParamException(@"date");

	FSOrdinance *ordinance = [FSOrdinance ordinanceWithType:type];
	ordinance.userAdded = YES;
	[ordinance setStatus:FSOrdinanceStatusCompleted];
	[ordinance setDate:date];
	[ordinance setTempleCode:templeCode];
	[ordinance setOfficial:NO];
	[self addOrReplaceOrdinance:ordinance];
}


// TODO
- (MTPocketResponse *)combineWithPerson:(FSPerson *)person
{
	NSURL *url = [_url urlWithModule:@"familytree"
							 version:2
							resource:@"person"
						 identifiers:nil
							  params:defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics | FSQOrdinances
								misc:nil];

	NSDictionary *body =	@{	@"persons" : @[ @{
									@"personas" : @[ @{
										@"id" : _identifier
									}, @{
										@"id" : person.identifier
									}]
								}]
							};

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body];

	if (response.success) {
		NSDictionary *combinedPersonDictionary = [response.body valueForComplexKeyPath:@"persons[first]"];
		_identifier = combinedPersonDictionary[@"id"];
		[self fetch];
	}

	return response;
}

+ (MTPocketResponse *)batchFetchPeople:(NSArray *)people
{
	if (people.count == 0) return nil;
	FSPerson *anyPerson = [people lastObject];
	if (!anyPerson.sessionID) raiseException(@"Required sessionID nil", @"Every FSPerson in people must have a valid 'sessionID'");


	NSMutableArray *identifiers = [NSMutableArray array];
	for (FSPerson *person in people) {
		if (person.identifier) [identifiers addObject:person.identifier];
	}

	FSURL *fsURL = [[FSURL alloc] initWithSessionID:anyPerson.sessionID];
	NSURL *url = [fsURL urlWithModule:@"familytree"
							  version:2
							 resource:@"person"
						  identifiers:identifiers
							   params:defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics | FSQOrdinances
								 misc:nil];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {

		NSArray *peopleDictionaries = (response.body)[@"persons"];
		for (NSDictionary *personDictionary in peopleDictionaries) {
			NSString *id = personDictionary[@"id"];
			FSPerson *person = people.count == 1 ? anyPerson : [FSPerson personWithSessionID:anyPerson.sessionID identifier:id];
			[person populateFromPersonDictionary:personDictionary];
		}
	}

	return response;
}





#pragma mark - Private Methods

- (void)addRelationship:(FSRelationship *)relationship
{
	// add it to me
	[self addOrReplaceRelationship:relationship];

	// add it to them
	FSPerson *other = [relationship.parent isSamePerson:self] ? relationship.child : relationship.parent;
	[other addOrReplaceRelationship:relationship];
}

- (void)removeRelationship:(FSRelationship *)relationship
{
	// remove it from me
	[_relationships removeObject:relationship];

	// remove it form them
	FSPerson *other = [relationship.parent isSamePerson:self] ? relationship.child : relationship.parent;
	[other.relationships removeObject:relationship];
}

- (void)addOrReplaceRelationship:(FSRelationship *)relationship
{
	for (NSInteger i = 0; i < _relationships.count; i++) {
		FSRelationship *existing = _relationships[i];
		if ([existing.parent isSamePerson:relationship.parent]	&& [existing.child isSamePerson:relationship.child]) {
			_relationships[i] = relationship;
			return;
		}
	}
	[_relationships addObject:relationship];
}

- (void)removeAllRelationships
{
	for (FSRelationship *relationship in [_relationships copy]) {
		[self removeRelationship:relationship];
	}
}

- (void)addMarriage:(FSMarriage *)marriage
{
	// add it to me
	[self addOrReplaceMarriage:marriage];

	// add it to them
	FSPerson *other = [marriage.husband isSamePerson:self] ? marriage.wife : marriage.husband;
	[other addOrReplaceMarriage:marriage];
}

- (void)removeMarriage:(FSMarriage *)marriage
{
	// remove it from me
	[_marriages removeObject:marriage];

	// remove it form them
	FSPerson *other = [marriage.husband isSamePerson:self] ? marriage.wife : marriage.husband;
	[other.marriages removeObject:marriage];
}

- (void)addOrReplaceMarriage:(FSMarriage *)marriage
{
	for (NSInteger i = 0; i < _marriages.count; i++) {
		FSMarriage *existing = _marriages[i];
		if ([existing.husband isSamePerson:marriage.husband] && [existing.wife isSamePerson:marriage.wife]) {
			_marriages[i] = marriage;
			return;
		}
	}
	[_marriages addObject:marriage];
}

- (void)removeAllMarriages
{
	for (FSMarriage *marriage in [_marriages copy]) {
		[self removeMarriage:marriage];
	}
}

- (void)removeAllEvents
{
	for (FSEvent *event in [_events copy]) {
		[(NSMutableArray *)_events removeObject:event];
	}
}

- (void)addOrReplaceOrdinance:(FSOrdinance *)ordinance
{
	[ordinance addPerson:self];

	FSOrdinance *existing = nil;
	for (FSOrdinance *existingOrdinance in _ordinances) {
		if ([ordinance isEqualToOrdinance:existingOrdinance]) {
			existing = existingOrdinance;
			break;
		}
	}
		
	if (existing) {
		((NSMutableArray *)_ordinances)[[_ordinances indexOfObject:existing]] = ordinance;
	}
	else {
		[(NSMutableArray *)_ordinances addObject:ordinance];
	}
}

- (BOOL)isSamePerson:(FSPerson *)person
{
	return person == self || [person.identifier isEqualToString:self.identifier];
}

- (BOOL)isMale
{
	return [_gender isEqualToString:@"Male"];
}

- (void)empty
{
	_name = nil;
	_gender = nil;
	[_properties removeAllObjects];
	[self removeAllRelationships];
	[self removeAllMarriages];
	[self removeAllEvents];
}

- (void)populateFromPersonDictionary:(NSDictionary *)person
{
	// empty out this object so it only contains what's on the server
	[self empty];
	
	// GENERAL INFO
	_identifier			= person[@"id"];
	_name				= [person valueForComplexKeyPath:@"assertions.names[first].value.forms[first].fullText"];
	_gender				= [person valueForComplexKeyPath:@"assertions.genders[first].value.type"];
	_isAlive			= [[person valueForComplexKeyPath:@"properties.living"] intValue] == YES;
	_isModifiable		= [[person valueForComplexKeyPath:@"properties.modifiable"] intValue] == YES;
	_lastModifiedDate	= [NSDate dateWithTimeIntervalSince1970:[[person valueForComplexKeyPath:@"properties.modified"] intValue]];


	// PROPERTIES
	NSArray *characteristics = [person valueForComplexKeyPath:@"assertions.characteristics"];
	if (![characteristics isKindOfClass:[NSNull class]])
		for (NSDictionary *characteristic in characteristics) {
			FSProperty *property = [[FSProperty alloc] init];
			property.identifier = [characteristic valueForComplexKeyPath:@"value.id"];
			property.key		= [characteristic valueForComplexKeyPath:@"value.type"];
			property.value		= [characteristic valueForComplexKeyPath:@"value.detail"];
			property.title		= [characteristic valueForComplexKeyPath:@"value.title"];
			property.lineage	= [characteristic valueForComplexKeyPath:@"value.lineage"];
			property.date		= [NSDate dateFromString:[characteristic valueForKeyPath:@"value.date.numeric"] usingFormat:MTDatesFormatISODate];
			property.place		= [characteristic valueForComplexKeyPath:@"value.place.original"];
			_properties[property.key] = property;
		}


	// EVENTS
	NSArray *events = [person valueForKeyPath:@"assertions.events"];
	if (![events isKindOfClass:[NSNull class]])
		for (NSDictionary *eventDict in events) {
			FSPersonEventType type = [eventDict valueForKeyPath:@"value.type"];
			NSString *identifier = [eventDict valueForKeyPath:@"value.id"];
			FSEvent *event = [FSEvent eventWithType:type identifier:identifier];
			event.date = [NSDate dateFromString:[eventDict valueForKeyPath:@"value.date.numeric"] usingFormat:MTDatesFormatISODate];
			event.place = [eventDict valueForKeyPath:@"value.place.normalized.value"];
			[self addEvent:event];
		}


	// RELATIONSHIPS
	NSArray *parents = [person valueForComplexKeyPath:@"parents"];
	for (NSDictionary *parent in parents) {
		NSArray *coupledParents = parent[@"parent"];
		for (NSDictionary *coupledParent in coupledParents) {
			FSPerson *p = [[FSPerson alloc] initWithSessionID:_sessionID identifier:coupledParent[@"id"]];
			NSString *lineage = [coupledParent valueForComplexKeyPath:@"characteristics[first].value.lineage"];
			FSRelationship *relationship = [FSRelationship relationshipWithParent:p child:self lineage:lineage];
			[self addRelationship:relationship];
		}
	}

	NSArray *families = [person valueForComplexKeyPath:@"families"];
	for (NSDictionary *family in families) {
		NSArray *children = [family valueForComplexKeyPath:@"child"];
		for (NSDictionary *child in children) {
			FSPerson *p = [[FSPerson alloc] initWithSessionID:_sessionID identifier:child[@"id"]];
			FSRelationship *relationship = [FSRelationship relationshipWithParent:self child:p lineage:FSLineageTypeBiological];
			[self addRelationship:relationship];
		}
		NSArray *spouses = [family valueForComplexKeyPath:@"parent"];
		for (NSDictionary *spouse in spouses) {
			FSPerson *p = [[FSPerson alloc] initWithSessionID:_sessionID identifier:spouse[@"id"]];
			if ([p isSamePerson:self]) continue;
			FSMarriage *marriage = [self addSpouse:p];
			id version = spouse[@"version"];
			marriage.version = version == [NSNull null] ? 1 : [version intValue];
		}
	}

	// ORDINANCES
	NSArray *ordinances = [person valueForComplexKeyPath:@"ordinances"];
	if (![ordinances isKindOfClass:[NSNull class]])
		for (NSDictionary *ordinanceDictionary in ordinances) {
			NSString		*identifer	= [ordinanceDictionary valueForKeyPath:@"value.id"];
			FSOrdinanceType	type		= [ordinanceDictionary valueForKeyPath:@"value.type"];
			BOOL			official	= [ordinanceDictionary[@"official"] boolValue];
			NSDate			*date		= [NSDate dateFromString:[ordinanceDictionary valueForKeyPath:@"value.date.numeric"] usingFormat:MTDatesFormatISODate];
			NSString		*templeCode	= [ordinanceDictionary valueForKeyPath:@"value.temple"];

			FSOrdinance *ordinance = [FSOrdinance ordinanceWithType:type];
			ordinance.identifier = identifer;
			[ordinance setDate:date];
			[ordinance setTempleCode:templeCode];
			[ordinance setOfficial:official];
			[self addOrReplaceOrdinance:ordinance];
		}
}

- (void)setDate:(NSDate *)date place:(NSString *)place forEventOfType:(FSPersonEventType)eventType
{
	for (FSEvent *event in _events) {
		if ([event.type isEqualToString:eventType]) {
			if (date)	event.date = date;
			if (place)	event.place = place;
			return;
		}
	}

	FSEvent *event = [FSEvent eventWithType:eventType identifier:nil];
	event.date = date;
	event.place = place;
	[self addEvent:event];
}

- (NSDate *)dateForEventOfType:(FSPersonEventType)eventType
{
	for (FSEvent *event in _events) {
		if ([event.type isEqualToString:eventType]) {
			return event.date;
		}
	}
	return nil;
}

- (NSString *)placeForEventOfType:(FSPersonEventType)eventType
{
	for (FSEvent *event in _events) {
		if ([event.type isEqualToString:eventType]) {
			return event.place;
		}
	}
	return nil;
}

@end









@implementation FSRelationship

- (id)initWithParent:(FSPerson *)parent child:(FSPerson *)child lineage:(FSLineageType)lineage
{
    self = [super init];
    if (self) {
		_url		= [[FSURL alloc] initWithSessionID:parent.sessionID];
        _parent		= parent;
		_child		= child;
		_lineage	= lineage ? lineage : FSLineageTypeBiological;
		_changed	= NO;
    }
    return self;
}

+ (FSRelationship *)relationshipWithParent:(FSPerson *)parent child:(FSPerson *)child lineage:(FSLineageType)lineage
{
	return [[FSRelationship alloc] initWithParent:parent child:child lineage:lineage];
}

- (MTPocketResponse *)save
{
	if (_deleted) {
		return [self deleteRelationship];
	}
	return [self updateRelationship];
}

- (MTPocketResponse *)destroy
{
	_deleted = YES;
	return [self save];
}

#pragma mark - Private Methods

- (MTPocketResponse *)updateRelationship
{
	// make sure the each is saved. If it is not, return because that save will also save this relationship.
	if (self.parent.isNew)
		return [self.parent save];
	if (self.child.isNew)
		return [self.child save];

	NSURL *url = [_url urlWithModule:@"familytree"
							 version:2
							resource:[NSString stringWithFormat:@"person/%@/parent", self.child.identifier]
						 identifiers:(self.parent.identifier ? @[ self.parent.identifier ] : nil)
							  params:defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics | FSQOrdinances
								misc:nil];

	NSDictionary *body = @{
							@"persons" : @[ @{
								@"id" : self.child.identifier,
								@"relationships" : @{
									@"parent" : @[ @{
										@"id" : self.parent.identifier,
										@"assertions" :	@{
											@"characteristics" : @[ @{
												@"value" : @{
													@"type" : @"Lineage",
													@"lineage" : _lineage
												}
											}]
										}
									}]
								}
							}]
						};

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body];

	if (response.success) {
		_changed = NO;
		_deleted = NO;
	}

	return response;
}

- (MTPocketResponse *)deleteRelationship
{
	NSURL *url = [_url urlWithModule:@"familytree"
							 version:2
							resource:[NSString stringWithFormat:@"person/%@/parent", self.child.identifier]
						 identifiers:(self.parent.identifier ? @[ self.parent.identifier ] : nil)
							  params:defaultQueryParameters() | FSQValues | FSQExists | FSQEvents | FSQCharacteristics | FSQOrdinances | FSQContributors
								misc:nil];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSMutableDictionary *relationshipTypesToDelete = [NSMutableDictionary dictionary];
		NSDictionary *relationshipTypes = [response.body valueForComplexKeyPath:@"persons[first].relationships"];
		for (NSString *key in [relationshipTypes allKeys]) {
			if (![key isEqualToString:@"parent"]) continue;
			NSMutableArray *relationshipsToDelete = [NSMutableArray array];
			NSArray *relationshipType = relationshipTypes[key];
			for (NSDictionary *relationship in relationshipType) {
				NSMutableDictionary *assertionTypesToDelete = [NSMutableDictionary dictionary];
				NSDictionary *assertionTypes = relationship[@"assertions"];
				for (NSString *aKey in [assertionTypes allKeys]) {
					NSMutableArray *assertionsToDelete = [NSMutableArray array];
					NSArray *assertionType = assertionTypes[aKey];
					for (NSDictionary *assertion in assertionType) {
						NSArray *valueID = [assertion valueForComplexKeyPath:@"value.id"];
						[assertionsToDelete addObject: @{ @"value" : @{ @"id" : valueID }, @"action" : @"Delete" } ];
					}
					assertionTypesToDelete[aKey] = assertionsToDelete;
				}
				[relationshipsToDelete addObject: @{ @"id" : self.parent.identifier, @"assertions" : assertionTypesToDelete, @"version" : relationship[@"version"] } ];
			}
			relationshipTypesToDelete[key] = relationshipsToDelete;
		}

		NSDictionary *body = @{
								@"persons" : @[ @{
									@"id" : self.child.identifier,
									@"relationships" : relationshipTypesToDelete
								}]
							};

		response = [MTPocketRequest objectAtURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body];

		if (response.success) {
			_changed = NO;
			_deleted = NO;
			[_child removeRelationship:self];
			[_parent removeRelationship:self];
		}
	}

	return response;
}

@end










@implementation FSProperty

- (void)setValue:(NSString *)value
{
	_previousValue = _value;
	_value = value;
}

- (BOOL)isChanged
{
	return ![_value isEqualToString:_previousValue];
}

- (void)reset
{
	_value = _previousValue;
}

- (void)markAsSaved
{
	_previousValue = _value;
}

@end

