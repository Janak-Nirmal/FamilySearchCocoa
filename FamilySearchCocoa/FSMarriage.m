//
//  FSMarriage.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSMarriage.h"
#import "private.h"
#import <NSDate+MTDates.h>
#import <NSDateComponents+MTDates.h>
#import <NSObject+MTJSONUtils.h>




@implementation FSMarriageEvent

+ (FSMarriageEvent *)marriageEventWithType:(FSMarriageEventType)type identifier:(NSString *)identifier
{
	return (FSMarriageEvent *)[super eventWithType:type identifier:identifier];
}

@end









@implementation FSMarriage

- (id)initWithHusband:(FSPerson *)husband wife:(FSPerson *)wife
{
	if (!husband)	raiseParamException(@"husband");
	if (!wife)		raiseParamException(@"wife");

    self = [super init];
    if (self) {
		_url			= [[FSURL alloc] initWithSessionID:husband.sessionID];
		_husband		= husband;
		_wife			= wife;
		_properties		= [NSMutableDictionary dictionary];
		_changed		= YES;
		_deleted		= NO;
		_version		= 1;
		_events			= [NSMutableArray array];
    }
    return self;
}

+ (FSMarriage *)marriageWithHusband:(FSPerson *)husband wife:(FSPerson *)wife
{
	return [[FSMarriage alloc] initWithHusband:husband wife:wife];
}




#pragma mark - Properties

- (NSString *)propertyForKey:(FSMarriagePropertyType)key
{
	FSProperty *property = _properties[key];
	return property.value;
}

- (void)setProperty:(NSString *)property forKey:(FSMarriagePropertyType)key
{
	if (!property)	raiseParamException(@"property");
	if (!key)		raiseParamException(@"key");

	_changed = YES;
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




#pragma mark - Marriage Events

- (void)addMarriageEvent:(FSMarriageEvent *)event
{
	if (!event)	raiseParamException(@"event");

	_changed = YES;
	for (FSEvent *e in _events) {
		if ([e isEqualToEvent:event]) {
			((NSMutableArray *)_events)[[_events indexOfObject:e]] = event;
			return;
		}
	}
	[(NSMutableArray *)_events addObject:event];
}

- (void)removeMarriageEvent:(FSMarriageEvent *)event
{
	for (FSEvent *e in _events) {
		if ([event isEqualToEvent:e])
			_deleted = YES;
	}
}



- (MTPocketResponse *)fetch
{
	// empty out this object so it only contains what's on the server
	[self empty];

	NSURL *url = [self.url urlWithModule:@"familytree"
							  version:2
							 resource:[NSString stringWithFormat:@"person/%@/spouse", self.husband.identifier]
						  identifiers:(self.wife.identifier ? @[ self.wife.identifier ] : nil)
							   params:defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics
								 misc:nil];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];
	



	if (response.success) {
		NSArray *spouses = [response.body valueForComplexKeyPath:@"persons[first].relationships.spouse"];
		for (NSDictionary *spouse in spouses) {
			NSString *wifeID = spouse[@"id"];
			if ([wifeID isEqualToString:self.wife.identifier]) {

				// PROPERTIES
				NSArray *characteristics = [spouse valueForComplexKeyPath:@"assertions.characteristics"];
				if (![characteristics isKindOfClass:[NSNull class]])
					for (NSDictionary *characteristic in characteristics) {
						NSString *dateString = [characteristic valueForComplexKeyPath:@"value.date.normalized"];
						if (!dateString) dateString = [characteristic valueForComplexKeyPath:@"value.date.original"];
						FSProperty *property = [[FSProperty alloc] init];
						property.identifier = [characteristic valueForComplexKeyPath:@"value.id"];
						property.key		= [characteristic valueForComplexKeyPath:@"value.type"];
						property.value		= [characteristic valueForComplexKeyPath:@"value.detail"];
						property.title		= [characteristic valueForComplexKeyPath:@"value.title"];
						property.lineage	= [characteristic valueForComplexKeyPath:@"value.lineage"];
						property.date		= [NSDateComponents componentsFromString:objectForPreferredKeys(characteristic, @"value.date.normalized", @"value.date.original")];
						property.place		= [characteristic valueForComplexKeyPath:@"value.place.original"];
						(self.properties)[property.key] = property;
					}
				
				// EVENTS
				NSArray *events = [spouse valueForComplexKeyPath:@"assertions.events"];
				if (![events isKindOfClass:[NSNull class]])
					for (NSDictionary *eventDict in events) {
						FSMarriageEventType type = [eventDict valueForComplexKeyPath:@"value.type"];
						NSString *identifier = [eventDict valueForComplexKeyPath:@"value.id"];
						FSMarriageEvent *event = [FSMarriageEvent marriageEventWithType:type identifier:identifier];
						event.date = [NSDateComponents componentsFromString:objectForPreferredKeys(eventDict, @"value.date.normalized", @"value.date.original")];
						event.place = [eventDict valueForComplexKeyPath:@"value.place.normalized.value"];
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
		FSProperty *property = (self.properties)[key];
		NSMutableDictionary *characteristic = [NSMutableDictionary dictionary];
		if (property.identifier) characteristic[@"id"] = property.identifier;
		if (property.key) characteristic[@"type"] = property.key;
		if (property.value) characteristic[@"detail"] = property.value;
		[characteristics addObject: @{ @"value" : characteristic } ];
	}
	[assertions addEntriesFromDictionary: @{ @"characteristics" : characteristics } ];


	// EVENTS
	NSMutableArray *events = [NSMutableArray array];
	for (FSEvent *event in self.events) {
		NSMutableDictionary *eventInfo = [NSMutableDictionary dictionaryWithObject:event.type forKey:@"type"];
		if (event.date)		eventInfo[@"date"] = @{ @"original" : event.date };
		if (event.place)	eventInfo[@"place"] = @{ @"original" : event.place };

		if ((event.date || event.place)) {
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

	NSURL *url = [self.url urlWithModule:@"familytree"
								 version:2
								resource:[NSString stringWithFormat:@"person/%@/spouse", self.husband.identifier]
							 identifiers:(self.wife.identifier ? @[ self.wife.identifier ] : nil)
								  params:defaultQueryParameters() | familyQueryParameters() | FSQProperties | FSQCharacteristics
									misc:nil];


	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body];

	if (response.success) {
		self.changed = NO;
		self.deleted = NO;
	}

	return response;
}

- (MTPocketResponse *)deleteMarriage
{
	NSURL *url = [self.url urlWithModule:@"familytree"
								 version:2
								resource:[NSString stringWithFormat:@"person/%@/spouse", self.husband.identifier]
							 identifiers:(self.wife.identifier ? @[ self.wife.identifier ] : nil)
								  params:defaultQueryParameters() | FSQValues | FSQExists | FSQEvents | FSQCharacteristics | FSQOrdinances | FSQContributors
									misc:nil];


	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		NSMutableDictionary *relationshipTypesToDelete = [NSMutableDictionary dictionary];
		NSDictionary *relationshipTypes = [response.body valueForComplexKeyPath:@"persons[first].relationships"];
		for (NSString *key in [relationshipTypes allKeys]) {
			if (![key isEqualToString:@"spouse"]) continue;
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
				[relationshipsToDelete addObject: @{ @"id" : self.wife.identifier, @"assertions" : assertionTypesToDelete, @"version" : relationship[@"version"] } ];
			}
			relationshipTypesToDelete[key] = relationshipsToDelete;
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
