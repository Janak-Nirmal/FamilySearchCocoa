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
#import <NSDateComponents+MTDates.h>
#import <NSObject+MTJSONUtils.h>







@interface FSPerson ()
@property (strong, nonatomic)	FSURL				*url;
@property (strong, nonatomic)	NSMutableArray		*properties;
@property (strong, nonatomic)	NSMutableDictionary	*characteristics;
@property (strong, nonatomic)	NSMutableArray		*relationships;
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

@synthesize events		= _events;
@synthesize marriages	= _marriages;




#pragma mark - Constructor

- (id)initWithSessionID:(NSString *)sessionID identifier:(NSString *)identifier
{
	static NSMutableArray *__people;
	if (!__people) __people = [[NSMutableArray alloc] initWithCapacity:0];

	for (FSPerson *person in [__people copy]) {
		if ([person.identifier isEqualToString:identifier]) {
			return person;
		}
	}

	self = [super init];
	if (self) {
		_sessionID			= sessionID;
		_url				= [[FSURL alloc] initWithSessionID:sessionID];
		_identifier			= identifier;
		_properties			= [NSMutableArray array];
		_isAlive			= NO;
		_relationships		= [NSMutableArray array];
		_characteristics	= [NSMutableDictionary dictionary];
		_marriages			= [NSMutableArray array];
		_events				= [NSMutableArray array];
		_ordinances			= [NSMutableArray array];
		_onChange			= ^(FSPerson *p){};
		_onSync				= ^(FSPerson *p, FSPersonSyncResult status){};
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
	
	return response;
}

- (MTPocketResponse *)save
{
	NSMutableDictionary *assertions = [NSMutableDictionary dictionary];


	// NAME
	if (self.name) {
		NSDictionary *nameDict = @{
								@"names" : @[ @{
									@"value" : @{
										@"forms" : @[ @{
											@"fullText" : self.name
										}]
									}
								}]
							};
		[assertions addEntriesFromDictionary:nameDict];
	}


	// GENDER
	if (self.gender) {
		NSDictionary *genderDict = @{
									@"genders" : @[ @{
										@"value" : @{
											@"type" : self.gender
										}
									}]
								};
		[assertions addEntriesFromDictionary:genderDict];
	}
	

	// CHARACTERISTICS
	NSMutableArray *characteristics = [NSMutableArray array];
	for (FSCharacteristicType key in [_characteristics allKeys]) {
		FSCharacteristic *characteristic = _characteristics[key];
		NSMutableDictionary *characteristicDict = [NSMutableDictionary dictionary];
		if (characteristic.identifier) characteristicDict[@"id"] = characteristic.identifier;
		if (characteristic.key) characteristicDict[@"type"] = characteristic.key;
		if (characteristic.value) characteristicDict[@"detail"] = characteristic.value;
		[characteristics addObject: @{ @"value" : characteristicDict } ];
	}
	[assertions addEntriesFromDictionary: @{ @"characteristics" : characteristics } ];


	// EVENTS
	NSMutableArray *events = [NSMutableArray array];
	for (FSEvent *event in _events) {
		NSMutableDictionary *eventInfo = [NSMutableDictionary dictionaryWithObject:event.type forKey:@"type"];
		if (event.date)		eventInfo[@"date"] = @{ @"original" : [event.date stringValue] };
		if (event.place)	eventInfo[@"place"] = @{ @"original" : event.place };

		if (event.date || event.place) {
			if (event.identifier) {
				eventInfo[@"id"] = event.identifier;
				if (event.isDeleted)
					[events addObject: @{ @"value" : eventInfo, @"action" : @"Delete" } ];
				else if (event.isChanged) {
					[events addObject: @{ @"value" : eventInfo } ];
				}
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

		FSPersonSyncResult status = FSPersonSyncResultUpdated;

		if (!_identifier) {
			_identifier = [response.body valueForComplexKeyPath:@"persons[first].id"];
			status = FSPersonSyncResultCreated;
		}

		for (FSCharacteristic *characteristic in [_characteristics allValues]) {
			[characteristic markAsSaved];
		}

		for (FSEvent *event in [_events copy]) {
			if (event.isDeleted) [(NSMutableArray *)_events removeObject:event];
		}

		// RELATIONSHIPS
		for (FSRelationship *relationship in [_relationships copy]) {
			if (relationship.isChanged || relationship.isDeleted) {
				[relationship save];
			}
		}

		// MARRIAGES
		for (FSMarriage *marriage in [_marriages copy]) {
			if (marriage.isChanged || marriage.isDeleted) {
				[marriage save];
			}
		}

		_onSync(self, status);
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
								 misc:[NSString stringWithFormat:@"ancestors=%u&properties=all", generations]];
	
	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSDictionary *pedigree = [response.body valueForComplexKeyPath:@"pedigrees[first]"];
		NSArray *people = pedigree[@"persons"];
		for (NSDictionary *personDict in people) {
			FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:personDict[@"id"]];
			[person populateFromPersonDictionary:personDict];

			// PARENTS GENDER
			NSArray *parents = [personDict valueForComplexKeyPath:@"parents[first].parent"];
			for (NSDictionary *parentDict in parents) {
				FSPerson *parent = [FSPerson personWithSessionID:_sessionID identifier:parentDict[@"id"]];
				parent.gender = parentDict[@"gender"];
			}

			// EVENTS
			NSString *birth = [personDict valueForComplexKeyPath:@"properties.lifespan.birth.text"];
			NSString *death = [personDict valueForComplexKeyPath:@"properties.lifespan.death.text"];

			if ([birth isKindOfClass:[NSString class]]) {
				FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeBirth identifier:nil];
				event.date = [NSDateComponents componentsFromString:birth];
				event.place = nil;
				[person addEvent:event];
			}

			if ([death isKindOfClass:[NSString class]]) {
				FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeDeath identifier:nil];
				event.date = [NSDateComponents componentsFromString:death];
				event.place = nil;
				[person addEvent:event];
			}
		}
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
			[person empty]; // empty out this object so it only contains what's on the server
			[person populateFromPersonDictionary:personDictionary];
			person.onSync(person, FSPersonSyncResultFetched);
		}
	}

	return response;
}

- (MTPocketResponse *)saveSummary
{
	NSMutableDictionary *assertions = [NSMutableDictionary dictionary];


	// NAME
	FSProperty *nameProperty = [self selectedPropertyForType:FSPropertyTypeName];
	if (nameProperty) {
		NSDictionary *nameDict = @{
										@"names" : @[ @{
											@"action" : @"Select",
											@"value" : @{
												@"id" : nameProperty.identifier
											}
										}]
									};
		[assertions addEntriesFromDictionary:nameDict];
	}


	// GENDER
	FSProperty *genderProperty = [self selectedPropertyForType:FSPropertyTypeGender];
	if (genderProperty) {
		NSDictionary *genderDict = @{
										@"genders" : @[ @{
											@"action" : @"Select",
											@"value" : @{
												@"id" : genderProperty.identifier
											}
										}]
									};
		[assertions addEntriesFromDictionary:genderDict];
	}

	// EVENTS
	NSMutableArray *events = [NSMutableArray array];
	for (FSEvent *event in _events) {
		NSMutableDictionary *eventInfo = [NSMutableDictionary dictionaryWithObject:event.type forKey:@"type"];
		if (event.identifier) {
			eventInfo[@"id"] = event.identifier;
			[events addObject: @{
									@"action" : @"Select",
									@"value" : @{
										@"type" : event.type,
										@"id"	: event.identifier
									}
								}];
		}
	}
	if (events.count > 0) [assertions addEntriesFromDictionary: @{ @"events" : events } ];

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

	return response;
}




#pragma mark - Properties

- (NSString *)name
{
	return [self summaryValueForPropertyType:FSPropertyTypeName];
}

- (void)setName:(NSString *)name
{
	[self setValue:name forPropertyType:FSPropertyTypeName identifier:nil summary:FSSummaryLocalYES];
}

- (NSString *)gender
{
	return [self summaryValueForPropertyType:FSPropertyTypeGender];
}

- (void)setGender:(NSString *)gender
{
	[self setValue:gender forPropertyType:FSPropertyTypeGender identifier:nil summary:FSSummaryLocalYES];
}

- (NSArray *)loggedValuesForPropertyType:(FSPropertyType)type
{
	return [_properties filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FSProperty *property, NSDictionary *bindings) {
		return [property.type isEqualToString:type];
	}]];
}




#pragma mark - Characteristics

- (NSString *)characteristicForKey:(FSCharacteristicType)key
{
	FSCharacteristic *characteristic = _characteristics[key];
	return characteristic.value;
}

- (void)setCharacteristic:(NSString *)characteristic forKey:(FSCharacteristicType)key
{
	FSCharacteristic *c = _characteristics[key];
	if (!c) {
		c = [[FSCharacteristic alloc] init];
		c.identifier = nil;
		c.key = key;
		_characteristics[key] = c;
	}
	c.value = characteristic;
	_onChange(self);
}

- (void)reset
{
	for (FSCharacteristic *characteristic in [_characteristics allValues]) {
		[characteristic reset];
	}
	_onChange(self);
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

- (NSArray *)motherAndFather
{
	FSPerson *father = nil;
	FSPerson *mother = nil;

	for (FSPerson *parent in self.parents) {
		if ([parent.gender isEqualToString:@"Male"])
			father = parent;

		else if ([parent.gender isEqualToString:@"Female"])
			mother = parent;
	}

	if (!father) {
		father = [FSPerson personWithSessionID:self.sessionID identifier:nil];
		father.gender = @"Male";
		[self addParent:father withLineage:FSLineageTypeBiological];
	}

	if (!mother) {
		mother = [FSPerson personWithSessionID:self.sessionID identifier:nil];
		mother.gender = @"Female";
		[self addParent:mother withLineage:FSLineageTypeBiological];
	}

	return @[ father, mother ];
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




#pragma mark - Marriages

- (NSArray *)marriages
{
	NSMutableArray *marriages = [NSMutableArray array];
	for (FSMarriage *marriage in _marriages) {
		if (!marriage.isDeleted)
			[marriages addObject:marriage];
	}
	return marriages;
}

- (void)addMarriage:(FSMarriage *)marriage
{
	if (!marriage) raiseParamException(@"marriage");

	marriage.changed = YES;
	
	// add it to me
	[self addOrReplaceMarriage:marriage];

	// add it to them
	FSPerson *other = [marriage.husband isSamePerson:self] ? marriage.wife : marriage.husband;
	[other addOrReplaceMarriage:marriage];
}

- (void)removeMarriage:(FSMarriage *)marriage
{
	if (!marriage) raiseParamException(@"marriage");
	marriage.deleted = YES;
}

- (FSMarriage *)marriageWithSpouse:(FSPerson *)spouse
{
	for (FSMarriage *marriage in _marriages) {
		if ([marriage.husband isSamePerson:spouse] || [marriage.wife isSamePerson:spouse])
			return marriage;
	}
	return nil;
}




#pragma mark - Events

- (NSArray *)events
{
	NSMutableDictionary *events = [NSMutableDictionary dictionary];

	// so that if none of the summary statuses win, the last one set (highest id) wins
	NSArray *sorted = [_events sortedArrayUsingComparator:^NSComparisonResult(FSEvent *e1, FSEvent *e2) {
		return [e2.identifier localizedCaseInsensitiveCompare:e1.identifier];
	}];

	for (FSEvent *event in sorted) {
		FSEvent *existing = events[event.type];
		if (!event.isDeleted && (!existing || summaryFlagChosenBeforeFlag(event.summary, existing.summary))) {
			events[event.type] = event;
		}
	}

	return [events allValues];
}

- (void)addEvent:(FSEvent *)event
{
	if (!event) raiseParamException(@"event");
	[self addEvent:event summary:FSSummaryLocalYES];
	event.changed = YES;
	_onChange(self);
}

- (void)removeEvent:(FSEvent *)event
{
	for (FSEvent *e in _events) {
		if ([event isEqualToEvent:e])
			e.deleted = YES;
	}
	_onChange(self);
}

- (NSDateComponents *)birthDate						{ return [self dateForEventOfType:FSPersonEventTypeBirth];						}
- (void)setBirthDate:(NSDateComponents *)birthDate	{ [self setDate:birthDate place:nil forEventOfType:FSPersonEventTypeBirth];		}
- (NSString *)birthPlace							{ return [self placeForEventOfType:FSPersonEventTypeBirth];						}
- (void)setBirthPlace:(NSString *)birthPlace		{ [self setDate:nil place:birthPlace forEventOfType:FSPersonEventTypeBirth];	}
- (NSDateComponents *)deathDate						{ return [self dateForEventOfType:FSPersonEventTypeDeath];						}
- (void)setDeathDate:(NSDateComponents *)deathDate	{ [self setDate:deathDate place:nil forEventOfType:FSPersonEventTypeDeath];		}
- (NSString *)deathPlace							{ return [self placeForEventOfType:FSPersonEventTypeDeath];						}
- (void)setDeathPlace:(NSString *)deathPlace		{ [self setDate:nil place:deathPlace forEventOfType:FSPersonEventTypeDeath];	}

- (NSArray *)loggedEventsOfType:(FSPersonEventType)type
{
	return [_events filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(FSEvent *event, NSDictionary *bindings) {
		return [event.type isEqualToString:type];
	}]];
}




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
				[person addMarriage:[FSMarriage marriageWithHusband:(spouse.isMale ? spouse : self) wife:(spouse.isMale ? self : spouse)]];
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

- (MTPocketResponse *)combineWithPerson:(FSPerson *)person // TODO
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

	_onSync(self, FSPersonSyncResultCreated);
	return response;
}




#pragma mark - Keys

+ (NSArray *)characteristics
{
	return @[
		FSCharacteristicTypeCasteName,
		FSCharacteristicTypeClanName,
		FSCharacteristicTypeNationalID,
		FSCharacteristicTypeNationalOrigin,
		FSCharacteristicTypeTitleOfNobility,
		FSCharacteristicTypeOccupation,
		FSCharacteristicTypePhysicalDescription,
		FSCharacteristicTypeRace,
		FSCharacteristicTypeReligiousAffiliation,
		FSCharacteristicTypeStillborn,
		FSCharacteristicTypeTribeName,
		FSCharacteristicTypeGEDCOMID,
		FSCharacteristicTypeCommonLawMarriage,
		FSCharacteristicTypeOther,
		FSCharacteristicTypeNumberOfChildren,
		FSCharacteristicTypeNumberOfMarriages,
		FSCharacteristicTypeCurrentlySpouses,
		FSCharacteristicTypeDiedBeforeEight,
		FSCharacteristicTypeNameSake,
		FSCharacteristicTypeNeverHadChildren,
		FSCharacteristicTypeNeverMarried,
		FSCharacteristicTypeNotAccountable,
		FSCharacteristicTypePossessions,
		FSCharacteristicTypeResidence,
		FSCharacteristicTypeScholasticAchievement,
		FSCharacteristicTypeSocialSecurityNumber,
		FSCharacteristicTypeTwin
	];
}

+ (NSArray *)lineageTypes
{
	return @[
		FSLineageTypeBiological,
		FSLineageTypeAdoptive,
		FSLineageTypeFoster,
		FSLineageTypeGuardianship,
		FSLineageTypeStep,
		FSLineageTypeUnknown,
		FSLineageTypeHeadOfHousehold,
		FSLineageTypeOther
	];
}





#pragma mark - Private Methods

- (NSString *)summaryValueForPropertyType:(FSPropertyType)type
{
	FSProperty *candidate = nil;
	FSSummary strongestFlag = FSSummaryRemoteNO;

	// so that if none of the summary statuses win, the last one set (highest id) wins
	NSArray *sorted = [_properties sortedArrayUsingComparator:^NSComparisonResult(FSProperty *p1, FSProperty *p2) {
		return [p2.identifier localizedCaseInsensitiveCompare:p1.identifier];
	}];

	for (FSProperty *property in sorted)
		if ([property.type isEqualToString:type] && (!candidate || summaryFlagChosenBeforeFlag(property.summary, strongestFlag))) {
			candidate		= property;
			strongestFlag	= property.summary;
		}

	return candidate.value;
}

- (FSProperty *)selectedPropertyForType:(FSPropertyType)type
{
	FSProperty *candidate = nil;
	FSSummary strongestFlag = FSSummaryRemoteYES;
	for (FSProperty *property in _properties)
		if ([property.type isEqualToString:type] && summaryFlagChosenBeforeFlag(property.summary, strongestFlag)) {
			candidate		= property;
			strongestFlag	= property.summary;
		}

	return candidate;
}

- (void)setValue:(NSString *)value forPropertyType:(FSPropertyType)type identifier:(NSString *)identifier summary:(FSSummary)summary
{
	// there can only be at most one local YES
	if (summary == FSSummaryLocalYES)
		for (FSProperty *property in _properties)
			if ([property.type isEqualToString:type] && property.summary == FSSummaryLocalYES)
				property.summary = FSSummaryLocalNO;

	// there can only be at most one remote YES
	if (summary == FSSummaryRemoteYES)
		for (FSProperty *property in _properties)
			if ([property.type isEqualToString:type] && property.summary == FSSummaryRemoteYES)
				property.summary = FSSummaryRemoteNO;

	// there should not be duplicate properties with the same values
	for (FSProperty *property in _properties)
		if ([property.type isEqualToString:type] && [property.value isEqualToString:value]) {
			property.summary = summary;
			property.identifier = identifier;
			return;
		}

	FSProperty *property = [FSProperty propertyWithType:type withValue:value identifier:identifier summary:summary];
	[_properties addObject:property];
}

- (void)addEvent:(FSEvent *)event summary:(BOOL)summary
{
	// there can only be at most one local YES
	if (summary == FSSummaryLocalYES)
		for (FSEvent *e in _events)
			if ([e.type isEqualToString:event.type] && e.summary == FSSummaryLocalYES)
				e.summary = FSSummaryLocalNO;

	// there can only be at most one remote YES
	if (summary == FSSummaryRemoteYES)
		for (FSEvent *e in _events)
			if ([e.type isEqualToString:event.type] && e.summary == FSSummaryRemoteYES)
				e.summary = FSSummaryRemoteNO;

	event.summary = summary;

	// if this event is already in the list, replace the existing
	for (FSEvent *e in _events)
		if ([e isEqualToEvent:event]) {
			((NSMutableArray *)_events)[[_events indexOfObject:e]] = event;
			return;
		}

	[(NSMutableArray *)_events addObject:event];
}

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
	_onChange(self);
}

- (void)clearAllRelationships
{
	for (FSRelationship *relationship in [_relationships copy]) {
		[self removeRelationship:relationship];
	}
}

- (void)deleteMarriage:(FSMarriage *)marriage
{
	// remove it from me
	[(NSMutableArray *)_marriages removeObject:marriage];

	// remove it form them
	FSPerson *other = [marriage.husband isSamePerson:self] ? marriage.wife : marriage.husband;
	[(NSMutableArray *)other.marriages removeObject:marriage];
}

- (void)addOrReplaceMarriage:(FSMarriage *)marriage
{
	for (NSInteger i = 0; i < _marriages.count; i++) {
		FSMarriage *existing = _marriages[i];
		if ([existing.husband isSamePerson:marriage.husband] && [existing.wife isSamePerson:marriage.wife]) {
			((NSMutableArray *)_marriages)[i] = marriage;
			return;
		}
	}
	[(NSMutableArray *)_marriages addObject:marriage];
	_onChange(self);
}

- (void)clearAllMarriages
{
	for (FSMarriage *marriage in [_marriages copy]) {
		[self deleteMarriage:marriage];
	}
}

- (void)clearAllEvents
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
	_onChange(self);
}

- (BOOL)isSamePerson:(FSPerson *)person
{
	return person == self || [person.identifier isEqualToString:self.identifier];
}

- (BOOL)isMale
{
	return [self.gender isEqualToString:@"Male"];
}

- (void)empty
{
	// TODO: We shouldn't need this really, cause 

	[_characteristics removeAllObjects];
	[self clearAllRelationships];
	[self clearAllMarriages];
//	[self clearAllEvents];
}

- (void)populateFromPersonDictionary:(NSDictionary *)person
{
	// GENERAL INFO
	_identifier			= person[@"id"];
	_isAlive			= [[person valueForComplexKeyPath:@"properties.living"] intValue] == YES;
	_isModifiable		= [[person valueForComplexKeyPath:@"properties.modifiable"] intValue] == YES;
	_lastModifiedDate	= [NSDate dateWithTimeIntervalSince1970:[[person valueForComplexKeyPath:@"properties.modified"] intValue]];

	NSArray *names = [person valueForComplexKeyPath:@"assertions.names"];
	for (NSDictionary *nameDict in names) {
		NSString	*identifier		= [nameDict valueForComplexKeyPath:@"value.id"];
		FSSummary	selected		= [nameDict valueForComplexKeyPath:@"selected"] != nil ? FSSummaryRemoteYES : FSSummaryRemoteNO;
		NSString	*name			= [nameDict valueForComplexKeyPath:@"value.forms[first].fullText"];
		[self setValue:name forPropertyType:FSPropertyTypeName identifier:identifier summary:selected];
	}

	NSArray *genders = [person valueForComplexKeyPath:@"assertions.genders"];
	for (NSDictionary *genderDict in genders) {
		NSString	*identifier		= [genderDict valueForComplexKeyPath:@"value.id"];
		FSSummary	selected		= [genderDict valueForComplexKeyPath:@"selected"] != nil ? FSSummaryRemoteYES : FSSummaryRemoteNO;
		NSString	*gender			= [genderDict valueForComplexKeyPath:@"value.type"];
		[self setValue:gender forPropertyType:FSPropertyTypeGender identifier:identifier summary:selected];
	}

	// CHARACTERISTICS
	NSArray *characteristics = [person valueForComplexKeyPath:@"assertions.characteristics"];
	if (characteristics && [characteristics isKindOfClass:[NSArray class]])
		for (NSDictionary *characteristicDict in characteristics) {
			FSCharacteristic *characteristic		= [[FSCharacteristic alloc] init];
			characteristic.identifier				= [characteristicDict valueForComplexKeyPath:@"value.id"];
			characteristic.key						= [characteristicDict valueForComplexKeyPath:@"value.type"];
			characteristic.value					= [characteristicDict valueForComplexKeyPath:@"value.detail"];
			characteristic.title					= [characteristicDict valueForComplexKeyPath:@"value.title"];
			characteristic.lineage					= [characteristicDict valueForComplexKeyPath:@"value.lineage"];
			characteristic.date						= [NSDateComponents componentsFromString:objectForPreferredKeys(characteristicDict, @"value.date.normalized", @"value.date.original")];
			characteristic.place					= [characteristicDict valueForComplexKeyPath:@"value.place.original"];
			_characteristics[characteristic.key]	= characteristic;
		}


	// EVENTS
	NSArray *events = [person valueForComplexKeyPath:@"assertions.events"];
	if (events && [events isKindOfClass:[NSArray class]])
		for (NSDictionary *eventDict in events) {
			FSPersonEventType	type		= [eventDict valueForComplexKeyPath:@"value.type"];
			NSString			*identifier	= [eventDict valueForComplexKeyPath:@"value.id"];
			FSEvent				*event		= [FSEvent eventWithType:type identifier:identifier];
			FSSummary			selected	= [eventDict valueForComplexKeyPath:@"selected"] != nil ? FSSummaryRemoteYES : FSSummaryRemoteNO;
			event.date						= [NSDateComponents componentsFromString:objectForPreferredKeys(eventDict, @"value.date.normalized", @"value.date.original")];
			event.place						= [eventDict valueForComplexKeyPath:@"value.place.normalized.value"];
			[self addEvent:event summary:selected];
			event.changed = NO;
		}


	// RELATIONSHIPS
	NSArray *parents = [person valueForComplexKeyPath:@"parents"];
	for (NSDictionary *parent in parents) {
		NSArray *coupledParents = parent[@"parent"];
		for (NSDictionary *coupledParent in coupledParents) {
			FSPerson		*p				= [[FSPerson alloc] initWithSessionID:_sessionID identifier:coupledParent[@"id"]];
			NSString		*lineage		= [coupledParent valueForComplexKeyPath:@"characteristics[first].value.lineage"];
			FSRelationship	*relationship	= [FSRelationship relationshipWithParent:p child:self lineage:lineage];
			[self addRelationship:relationship];
		}
	}

	NSArray *families = [person valueForComplexKeyPath:@"families"];
	for (NSDictionary *family in families) {
		NSArray *children = [family valueForComplexKeyPath:@"child"];
		for (NSDictionary *child in children) {
			FSPerson		*p				= [[FSPerson alloc] initWithSessionID:_sessionID identifier:child[@"id"]];
			FSRelationship	*relationship	= [FSRelationship relationshipWithParent:self child:p lineage:FSLineageTypeBiological];
			[self addRelationship:relationship];
		}
		NSArray *spouses = [family valueForComplexKeyPath:@"parent"];
		for (NSDictionary *spouse in spouses) {
			FSPerson	*p			= [[FSPerson alloc] initWithSessionID:_sessionID identifier:spouse[@"id"]];
			if ([p isSamePerson:self]) continue;
			FSMarriage	*marriage	= [FSMarriage marriageWithHusband:(p.isMale ? p : self) wife:(p.isMale ? self : p)];
			id			version		= spouse[@"version"];
			marriage.version		= version == [NSNull null] ? 1 : [version intValue];
			[self addMarriage:marriage];
		}
	}

	// ORDINANCES
	NSArray *ordinances = [person valueForComplexKeyPath:@"ordinances"];
	if (![ordinances isKindOfClass:[NSNull class]])
		for (NSDictionary *ordinanceDictionary in ordinances) {
			NSString		*identifer	= [ordinanceDictionary valueForComplexKeyPath:@"value.id"];
			FSOrdinanceType	type		= [ordinanceDictionary valueForComplexKeyPath:@"value.type"];
			BOOL			official	= [ordinanceDictionary[@"official"] boolValue];
			NSDate			*date		= [NSDate dateFromString:[ordinanceDictionary valueForComplexKeyPath:@"value.date.numeric"] usingFormat:MTDatesFormatISODate];
			NSString		*templeCode	= [ordinanceDictionary valueForComplexKeyPath:@"value.temple"];

			FSOrdinance *ordinance		= [FSOrdinance ordinanceWithType:type];
			ordinance.identifier		= identifer;
			[ordinance setDate:date];
			[ordinance setTempleCode:templeCode];
			[ordinance setOfficial:official];
			[self addOrReplaceOrdinance:ordinance];
		}

	_onChange(self);
}

- (void)setDate:(NSDateComponents *)date place:(NSString *)place forEventOfType:(FSPersonEventType)eventType
{
	FSEvent *event = nil;

	// Get the already selected summary event if there is one
	for (FSEvent *e in self.events)
		if ([e.type isEqualToString:eventType])
			event = e;

	// Create a new event if no current event is the selected summary
	if (!event) event = [FSEvent eventWithType:eventType identifier:nil];

	if (date)	event.date = date;
	if (place)	event.place = place;
	
	[self addEvent:event];
}

- (NSDateComponents *)dateForEventOfType:(FSPersonEventType)eventType
{
	for (FSEvent *event in self.events)
		if ([event.type isEqualToString:eventType])
			return event.date;

	return nil;
}

- (NSString *)placeForEventOfType:(FSPersonEventType)eventType
{
	for (FSEvent *event in self.events)
		if ([event.type isEqualToString:eventType])
			return event.place;

	return nil;}


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
	// don't save blank parents or children
	if (!self.parent.name || [self.parent.name isEqualToString:@""])
		return nil;
	if (!self.child.name || [self.child.name isEqualToString:@""])
		return nil;

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

- (id)init
{
    self = [super init];
    if (self) {
        _summary = FSSummaryRemoteNO;
    }
    return self;
}

+ (FSProperty *)propertyWithType:(FSPropertyType)type withValue:(NSString *)value identifier:(NSString *)identifier summary:(FSSummary)summary
{
	FSProperty *property = [[FSProperty alloc] init];
	property.identifier	= identifier;
	property.type		= type;
	property.value		= value;
	property.summary	= summary;
	return property;
}

- (void)setSummary:(FSSummary)summary
{
	if (summaryFlagCanOverwriteFlag(summary, _summary)) _summary = summary;
}

@end










@implementation FSCharacteristic

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
