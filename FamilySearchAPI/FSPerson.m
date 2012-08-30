//
//  FSPerson.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import <NSDate+MTDates.h>
#import <NSDictionary+MTJSONDictionary.h>
#import "FSPerson.h"
#import "FSEvent.h"
#import "FSMarriage.h"
#import "FSOrdinance.h"
#import "FSURL.h"
#import "private.h"


#define IN_MASK(a, b) ((a & b) == b)
#define ALL_OR_NONE(a, b, c) (IN_MASK(a, b) ? @"all" : (c ? c : @"none"))


// FSQueryParameter (Bitwise OR these together to generate a query string)
typedef enum {
	FSQNames				= 1UL << 1,
	FSQGenders				= 1UL << 2,
	FSQEvents				= 1UL << 3,
	FSQCharacteristics		= 1UL << 4,
	FSQExists				= 1UL << 5,
	FSQValues				= 1UL << 6,
	FSQOrdinances			= 1UL << 7,
	FSQAssertions			= 1UL << 8,
	FSQFamilies				= 1UL << 9,
	FSQChildren				= 1UL << 10,
	FSQParents				= 1UL << 11,
	FSQPersonas				= 1UL << 12,
	FSQProperties			= 1UL << 13,
	FSQIdentifiers			= 1UL << 14,
	FSQDispositions			= 1UL << 15,
	FSQContributors			= 1UL << 16
} FSQueryParameter;




FSQueryParameter defaultQueryParameters()
{
	return FSQNames | FSQGenders | FSQEvents | FSQValues | FSQAssertions | FSQIdentifiers;
}

FSQueryParameter familyQueryParameters()
{
	return FSQFamilies | FSQChildren | FSQParents;
}

NSString *queryStringWithParameters(FSQueryParameter parameters)
{
	NSString *string = [NSString stringWithFormat:@"names=%@&genders=%@&events=%@&characteristics=%@&exists=%@&values=%@&ordinances=%@&assertions=%@&families=%@&children=%@&parents=%@&personas=%@&properties=%@&identifiers=%@&dispositions=%@&contributors=%@",
						ALL_OR_NONE(parameters, FSQNames,			nil),
						ALL_OR_NONE(parameters, FSQGenders,			nil),
						ALL_OR_NONE(parameters, FSQEvents,			nil),
						ALL_OR_NONE(parameters, FSQCharacteristics,	nil),
						ALL_OR_NONE(parameters, FSQExists,			nil),
						ALL_OR_NONE(parameters, FSQValues,			@"summary"),
						ALL_OR_NONE(parameters, FSQOrdinances,		nil),
						ALL_OR_NONE(parameters, FSQAssertions,		nil),
						ALL_OR_NONE(parameters, FSQFamilies,		nil),
						ALL_OR_NONE(parameters, FSQChildren,		nil),
						ALL_OR_NONE(parameters, FSQParents,			nil),
						ALL_OR_NONE(parameters, FSQPersonas,		nil),
						ALL_OR_NONE(parameters, FSQProperties,		nil),
						ALL_OR_NONE(parameters, FSQIdentifiers,		nil),
						ALL_OR_NONE(parameters, FSQDispositions,	@"affirming"),
						ALL_OR_NONE(parameters, FSQContributors,	nil)];

	return string;
}







@interface FSPerson ()
@property (readonly)				NSString			*sessionID;
@property (strong, nonatomic)		NSMutableDictionary	*properties;
@property (strong, nonatomic)		NSMutableArray		*relationships;
@property (strong, nonatomic)		NSMutableArray		*marriages;
@end





@interface FSRelationship : NSObject
@property (readonly)			FSPerson		*parent;
@property (readonly)			FSPerson		*child;
@property (readonly)			FSLineageType	lineage;
@property (getter = isChanged)	BOOL			changed;	// is newly created or updated and needs to be updated on the server
@property (getter = isDeleted)	BOOL			deleted;	// has been deleted and needs to be deleted from the server
+ (FSRelationship *)relationshipWithParent:(FSPerson *)parent child:(FSPerson *)child lineage:(FSLineageType)lineage;
- (MTPocketResponse *)save;
- (MTPocketResponse *)destroy;
@end




@interface FSMarriage (FSPerson)
- (MTPocketResponse *)fetch;
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
		if ([person.sessionID isEqualToString:sessionID] && [person.identifier isEqualToString:identifier]) {
			return person;
		}
	}

	self = [super init];
	if (self) {
		_sessionID		= sessionID;
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




#pragma mark - Properties

- (NSString *)propertyForKey:(FSPropertyType)key
{
	FSProperty *property = [_properties objectForKey:key];
	return property.value;
}

- (void)setProperty:(NSString *)property forKey:(FSPropertyType)key
{
	FSProperty *p = [_properties objectForKey:key];
	if (!p) {
		p = [[FSProperty alloc] init];
		p.identifier = nil;
		p.key = key;
		[_properties setObject:p forKey:key];
	}
	p.value = property;
}

- (void)reset
{
	for (FSProperty *property in [_properties allValues]) {
		[property reset];
	}
}




#pragma mark - Syncing

- (BOOL)isNew
{
	return _identifier == nil;
}

- (MTPocketResponse *)fetch
{
	if (!_identifier) [[NSException exceptionWithName:@"Nil identifier" reason:@"You cannot fetch on a person with a nil identifier." userInfo:nil] raise];
	if ([_identifier isEqualToString:@"me"]) _identifier = nil;

	// empty out this object so it only contains what's on the server
	[self empty];

	NSString *path = [NSString stringWithFormat:@"person"];
	if (_identifier) path = [path stringByAppendingFormat:@"/%@", _identifier];
	NSString *params = queryStringWithParameters( defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics );
	NSString *query = [NSString stringWithFormat:@"%@&sessionId=%@&agent=%@", params, _sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:[FSURL treeURL]];
	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {

		// GENERAL INFO
		NSDictionary *person = [response.body valueForComplexKeyPath:@"persons[first]"];
		_identifier			= [person objectForKey:@"id"];
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
				[_properties setObject:property forKey:property.key];
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
			NSArray *coupledParents = [parent valueForKey:@"parent"];
			for (NSDictionary *coupledParent in coupledParents) {
				FSPerson *p = [[FSPerson alloc] initWithSessionID:_sessionID identifier:[coupledParent objectForKey:@"id"]];
				NSString *lineage = [coupledParent valueForComplexKeyPath:@"characteristics[first].value.lineage"];
				FSRelationship *relationship = [FSRelationship relationshipWithParent:p child:self lineage:lineage];
				[self addRelationship:relationship];
			}
		}

		NSArray *families = [person valueForComplexKeyPath:@"families"];
		for (NSDictionary *family in families) {
			NSArray *children = [family valueForComplexKeyPath:@"child"];
			for (NSDictionary *child in children) {
				FSPerson *p = [[FSPerson alloc] initWithSessionID:_sessionID identifier:[child objectForKey:@"id"]];
				FSRelationship *relationship = [FSRelationship relationshipWithParent:self child:p lineage:FSLineageTypeBiological];
				[self addRelationship:relationship];
			}
			NSArray *spouses = [family valueForComplexKeyPath:@"parent"];
			for (NSDictionary *spouse in spouses) {
				FSPerson *p = [[FSPerson alloc] initWithSessionID:_sessionID identifier:[spouse objectForKey:@"id"]];
				if ([p isSamePerson:self]) continue;
				FSMarriage *marriage = [self addSpouse:p];
				id version = [spouse objectForKey:@"version"];
				marriage.version = version == [NSNull null] ? 1 : [version intValue];
				[marriage fetch];
			}
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
		FSProperty *property = [_properties objectForKey:key];
		NSMutableDictionary *characteristic = [NSMutableDictionary dictionary];
		if (property.identifier) [characteristic setObject:property.identifier forKey:@"id"];
		if (property.key) [characteristic setObject:property.key forKey:@"type"];
		if (property.value) [characteristic setObject:property.value forKey:@"detail"];
		[characteristics addObject: @{ @"value" : characteristic } ];
	}
	[assertions addEntriesFromDictionary: @{ @"characteristics" : characteristics } ];


	// EVENTS
	NSMutableArray *events = [NSMutableArray array];
	for (FSEvent *event in _events) {
		NSMutableDictionary *eventInfo = [NSMutableDictionary dictionaryWithObject:event.type forKey:@"type"];
		if (event.date)		[eventInfo setObject:@{ @"original" : event.date }	forKey:@"date"];
		if (event.place)	[eventInfo setObject:@{ @"original" : event.place }	forKey:@"place"];

		if ((event.date || event.place)) {
			if (event.identifier) {
				[eventInfo setObject:event.identifier forKey:@"id"];
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

	// SAVE
	NSString *path = [NSString stringWithFormat:@"person"];
	if (_identifier) path = [path stringByAppendingFormat:@"/%@", _identifier];
	NSString *params = queryStringWithParameters( defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics );
	NSString *query = [NSString stringWithFormat:@"%@&sessionId=%@&agent=%@", params, _sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:[FSURL treeURL]];

	NSMutableDictionary *personDict = [NSMutableDictionary dictionary];
	if (_identifier)				[personDict setObject:_identifier forKey:@"id"];
	if (assertions.count > 0)		[personDict setObject:assertions forKey:@"assertions"];

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
	if (!_identifier) [[NSException exceptionWithName:@"Nil identifier" reason:@"You cannot fetch on a person with a nil identifier." userInfo:nil] raise];

	NSString *path = [NSString stringWithFormat:@"pedigree"];
	if (_identifier) path = [path stringByAppendingFormat:@"/%@", _identifier];
	NSString *params = @"properties=all"; //queryStringWithParameters( defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics );
	NSString *query = [NSString stringWithFormat:@"ancestors=%d&%@&sessionId=%@&agent=%@", generations, params, _sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:[FSURL treeURL]];
	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSDictionary *pedigree = [response.body valueForComplexKeyPath:@"pedigrees[first]"];
		NSArray *people = [pedigree objectForKey:@"persons"];
		for (NSDictionary *personDict in people) {
			FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:[personDict objectForKey:@"id"]];

			// GENERAL
			person.name		= [personDict valueForComplexKeyPath:@"assertions.names[first].value.forms[first].fullText"];
			person.gender	= [personDict valueForComplexKeyPath:@"assertions.genders[first].value.type"];

			// PARENTS
			NSArray *parents = [personDict valueForComplexKeyPath:@"parents[first].parent"];
			for (NSDictionary *parentDict in parents) {
				FSPerson *parent = [FSPerson personWithSessionID:_sessionID identifier:[parentDict objectForKey:@"id"]];
				parent.gender = [parentDict objectForKey:@"gender"];
				[person addParent:parent withLineage:FSLineageTypeBiological];
			}

			// EVENTS
			NSString *birth = [personDict valueForComplexKeyPath:@"properties.lifespan.birth.text"];
			NSString *death = [personDict valueForComplexKeyPath:@"properties.lifespan.death.text"];

			if ([birth isKindOfClass:[NSString class]]) {
				FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeBirth identifier:nil];
				event.date = [NSDate dateFromString:birth usingFormat:@"dd MMM yyyy"];
				event.place = nil;
				[person addEvent:event];
			}

			if ([death isKindOfClass:[NSString class]]) {
				FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeDeath identifier:nil];
				event.date = [NSDate dateFromString:death usingFormat:@"dd MMM yyyy"];
				event.place = nil;
				[person addEvent:event];
			}
		}
	}

	return response;
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

- (void)addParent:(FSPerson *)person withLineage:(FSLineageType)lineage
{
	if (!person) [[NSException exceptionWithName:@"Nil Person" reason:@"The parent paramater cannot be nil." userInfo:nil] raise];
	FSRelationship *relationship = [FSRelationship relationshipWithParent:person child:self lineage:lineage];
	relationship.changed = YES;
	[self addRelationship:relationship];
}

- (void)removeParent:(FSPerson *)person
{
	if (!person) [[NSException exceptionWithName:@"Nil Person" reason:@"The person paramater cannot be nil." userInfo:nil] raise];
	for (FSRelationship *relationship in _relationships) {
		if ([relationship.parent isSamePerson:person]) {
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

- (void)addChild:(FSPerson *)person withLineage:(FSLineageType)lineage
{
	[person addParent:self withLineage:lineage];
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
	if (!spouse) [[NSException exceptionWithName:@"Nil Spouse" reason:@"The spouse paramater cannot be nil." userInfo:nil] raise];
	FSMarriage *marriage = [FSMarriage marriageWithHusband:([self isMale] ? self : spouse)	wife:([self isMale] ? spouse : self)];
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
	if (!spouse) [[NSException exceptionWithName:@"Nil Spouse" reason:@"The spouse paramater cannot be nil." userInfo:nil] raise];
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
	for (FSEvent *e in _events) {
		if ([e isEqualToEvent:event]) {
			[(NSMutableArray *)_events replaceObjectAtIndex:[_events indexOfObject:e] withObject:event];
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




#pragma mark - Ordinances

- (void)addOrdinance:(FSOrdinance *)ordinance {

}

- (void)removeOrdinance:(FSOrdinance *)ordinance {
	
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
		FSRelationship *existing = [_relationships objectAtIndex:i];
		if ([existing.parent isSamePerson:relationship.parent]	&& [existing.child isSamePerson:relationship.child]) {
			[_relationships replaceObjectAtIndex:i withObject:relationship];
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
		FSMarriage *existing = [_marriages objectAtIndex:i];
		if ([existing.husband isSamePerson:marriage.husband] && [existing.wife isSamePerson:marriage.wife]) {
			[_marriages replaceObjectAtIndex:i withObject:marriage];
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

@end









@implementation FSRelationship

- (id)initWithParent:(FSPerson *)parent child:(FSPerson *)child lineage:(FSLineageType)lineage
{
    self = [super init];
    if (self) {
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

	NSString *path = [NSString stringWithFormat:@"person/%@/parent/%@", self.child.identifier, self.parent.identifier];
	NSString *query = [NSString stringWithFormat:@"sessionId=%@&agent=%@", self.child.sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:[FSURL treeURL]];

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
	NSString *path = [NSString stringWithFormat:@"person/%@/parent/%@", self.child.identifier, self.parent.identifier];
	NSString *params = queryStringWithParameters( defaultQueryParameters() | FSQValues | FSQExists | FSQEvents | FSQCharacteristics | FSQOrdinances | FSQContributors );
	NSString *query = [NSString stringWithFormat:@"%@&sessionId=%@&agent=%@", params, self.parent.sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:[FSURL treeURL]];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSMutableDictionary *relationshipTypesToDelete = [NSMutableDictionary dictionary];
		NSDictionary *relationshipTypes = [response.body valueForComplexKeyPath:@"persons[first].relationships"];
		for (NSString *key in [relationshipTypes allKeys]) {
			if (![key isEqualToString:@"parent"]) continue;
			NSMutableArray *relationshipsToDelete = [NSMutableArray array];
			NSArray *relationshipType = [relationshipTypes objectForKey:key];
			for (NSDictionary *relationship in relationshipType) {
				NSMutableDictionary *assertionTypesToDelete = [NSMutableDictionary dictionary];
				NSDictionary *assertionTypes = [relationship objectForKey:@"assertions"];
				for (NSString *aKey in [assertionTypes allKeys]) {
					NSMutableArray *assertionsToDelete = [NSMutableArray array];
					NSArray *assertionType = [assertionTypes objectForKey:aKey];
					for (NSDictionary *assertion in assertionType) {
						NSArray *valueID = [assertion valueForComplexKeyPath:@"value.id"];
						[assertionsToDelete addObject: @{ @"value" : @{ @"id" : valueID }, @"action" : @"Delete" } ];
					}
					[assertionTypesToDelete setObject:assertionsToDelete forKey:aKey];
				}
				[relationshipsToDelete addObject: @{ @"id" : self.parent.identifier, @"assertions" : assertionTypesToDelete, @"version" : [relationship objectForKey:@"version"] } ];
			}
			[relationshipTypesToDelete setObject:relationshipsToDelete forKey:key];
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








@implementation FSMarriage (FSPerson)

- (MTPocketResponse *)fetch
{
	// empty out this object so it only contains what's on the server
	[self empty];

	NSString *path = [NSString stringWithFormat:@"person/%@/spouse/%@", self.husband.identifier, self.wife.identifier];
	NSString *params = queryStringWithParameters( defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics );
	NSString *query = [NSString stringWithFormat:@"%@&sessionId=%@&agent=%@", params, self.husband.sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:[FSURL treeURL]];
	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSArray *spouses = [response.body valueForComplexKeyPath:@"persons[first].relationships.spouse"];
		for (NSDictionary *spouse in spouses) {
			NSString *wifeID = [spouse objectForKey:@"id"];
			if ([wifeID isEqualToString:self.wife.identifier]) {

				// PROPERTIES
				NSArray *characteristics = [spouse valueForKeyPath:@"assertions.characteristics"];
				if (![characteristics isKindOfClass:[NSNull class]])
					for (NSDictionary *characteristic in characteristics) {
						FSProperty *property = [[FSProperty alloc] init];
						property.identifier = [characteristic valueForKeyPath:@"value.id"];
						property.key		= [characteristic valueForKeyPath:@"value.type"];
						property.value		= [characteristic valueForKeyPath:@"value.detail"];
						property.title		= [characteristic valueForKeyPath:@"value.title"];
						property.lineage	= [characteristic valueForKeyPath:@"value.lineage"];
						property.date		= [NSDate dateFromString:[characteristic valueForKeyPath:@"value.date.numeric"] usingFormat:MTDatesFormatISODate];
						property.place		= [characteristic valueForKeyPath:@"value.place.original"];
						[self.properties setObject:property forKey:property.key];
					}
				
				// EVENTS
				NSArray *events = [spouse valueForKeyPath:@"assertions.events"];
				if (![events isKindOfClass:[NSNull class]])
					for (NSDictionary *eventDict in events) {
						FSMarriageEventType type = [eventDict valueForKeyPath:@"value.type"];
						NSString *identifier = [eventDict valueForKeyPath:@"value.id"];
						FSMarriageEvent *event = [FSMarriageEvent marriageEventWithType:type identifier:identifier];
						event.date = [NSDate dateFromString:[eventDict valueForKeyPath:@"value.date.numeric"] usingFormat:MTDatesFormatISODate];
						event.place = [eventDict valueForKeyPath:@"value.place.normalized.value"];
						[self addMarriageEvent:event];
					}
			}
		}
	}

	return response;
}

- (MTPocketResponse *)save
{
	if (self.deleted) {
		return [self deleteMarriage];
	}
	return [self updateMarriage];
}

- (MTPocketResponse *)destroy
{
	self.deleted = YES;
	return [self save];
}


#pragma mark - Private Methods

- (void)empty
{
	for (FSMarriageEvent *event in self.events) {
		[(NSMutableArray *)self.events removeAllObjects];
	}
	for (FSProperty *property in self.properties) {
		[self.properties removeAllObjects];
	}
	self.changed = NO;
	self.deleted = NO;
}

- (MTPocketResponse *)updateMarriage
{
	// make sure the each is saved. If it is not, return because that save will also save this relationship.
	if (self.husband.isNew)
		return [self.husband save];
	if (self.wife.isNew)
		return [self.wife save];

	NSMutableDictionary *assertions = [NSMutableDictionary dictionary];


	// PROPERTIES
	NSMutableArray *characteristics = [NSMutableArray array];
	for (FSPropertyType key in [self.properties allKeys]) {
		FSProperty *property = [self.properties objectForKey:key];
		NSMutableDictionary *characteristic = [NSMutableDictionary dictionary];
		if (property.identifier) [characteristic setObject:property.identifier forKey:@"id"];
		if (property.key) [characteristic setObject:property.key forKey:@"type"];
		if (property.value) [characteristic setObject:property.value forKey:@"detail"];
		[characteristics addObject: @{ @"value" : characteristic } ];
	}
	[assertions addEntriesFromDictionary: @{ @"characteristics" : characteristics } ];


	// EVENTS
	NSMutableArray *events = [NSMutableArray array];
	for (FSEvent *event in self.events) {
		NSMutableDictionary *eventInfo = [NSMutableDictionary dictionaryWithObject:event.type forKey:@"type"];
		if (event.date)		[eventInfo setObject:@{ @"original" : event.date }	forKey:@"date"];
		if (event.place)	[eventInfo setObject:@{ @"original" : event.place }	forKey:@"place"];

		if ((event.date || event.place)) {
			if (event.identifier) {
				[eventInfo setObject:event.identifier forKey:@"id"];
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


	
	NSDictionary *body = @{
							@"persons" : @[ @{
								@"id" : self.husband.identifier,
								@"relationships" : @{
									@"spouse" : @[ @{
										@"id" : self.wife.identifier,
										@"version" : @(self.version),
										@"assertions" :	assertions
									}]
								}
							}]
						};

	NSString *path = [NSString stringWithFormat:@"person/%@/spouse/%@", self.husband.identifier, self.wife.identifier];
	NSString *query = [NSString stringWithFormat:@"sessionId=%@&agent=%@", self.husband.sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:[FSURL treeURL]];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body];

	if (response.success) {
		self.changed = NO;
		self.deleted = NO;
	}

	return response;
}

- (MTPocketResponse *)deleteMarriage
{
	NSString *path = [NSString stringWithFormat:@"person/%@/spouse/%@", self.husband.identifier, self.wife.identifier];
	NSString *params = queryStringWithParameters( defaultQueryParameters() | FSQValues | FSQExists | FSQEvents | FSQCharacteristics | FSQOrdinances | FSQContributors );
	NSString *query = [NSString stringWithFormat:@"%@&sessionId=%@&agent=%@", params, self.husband.sessionID, @"akirk-at-familysearch-dot-org/1.0"];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query] relativeToURL:[FSURL treeURL]];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSMutableDictionary *relationshipTypesToDelete = [NSMutableDictionary dictionary];
		NSDictionary *relationshipTypes = [response.body valueForComplexKeyPath:@"persons[first].relationships"];
		for (NSString *key in [relationshipTypes allKeys]) {
			if (![key isEqualToString:@"spouse"]) continue;
			NSMutableArray *relationshipsToDelete = [NSMutableArray array];
			NSArray *relationshipType = [relationshipTypes objectForKey:key];
			for (NSDictionary *relationship in relationshipType) {
				NSMutableDictionary *assertionTypesToDelete = [NSMutableDictionary dictionary];
				NSDictionary *assertionTypes = [relationship objectForKey:@"assertions"];
				for (NSString *aKey in [assertionTypes allKeys]) {
					NSMutableArray *assertionsToDelete = [NSMutableArray array];
					NSArray *assertionType = [assertionTypes objectForKey:aKey];
					for (NSDictionary *assertion in assertionType) {
						NSArray *valueID = [assertion valueForComplexKeyPath:@"value.id"];
						[assertionsToDelete addObject: @{ @"value" : @{ @"id" : valueID }, @"action" : @"Delete" } ];
					}
					[assertionTypesToDelete setObject:assertionsToDelete forKey:aKey];
				}
				[relationshipsToDelete addObject: @{ @"id" : self.wife.identifier, @"assertions" : assertionTypesToDelete, @"version" : [relationship objectForKey:@"version"] } ];
			}
			[relationshipTypesToDelete setObject:relationshipsToDelete forKey:key];
		}

		NSDictionary *body = @{
								@"persons" : @[ @{
									@"id" : self.husband.identifier,
									@"relationships" : relationshipTypesToDelete
								}]
							};

		response = [MTPocketRequest objectAtURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body];

		if (response.success) {
			self.changed = NO;
			self.deleted = NO;
			[self.husband removeMarriage:self];
			[self.wife removeMarriage:self];
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

