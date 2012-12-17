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

+ (NSArray *)marriageEventTypes
{
	return @[
		FSMarriageEventTypeAnnulment,
		FSMarriageEventTypeDivorce,
		FSMarriageEventTypeDivorceFiling,
		FSMarriageEventTypeEngagement,
		FSMarriageEventTypeMarriage,
		FSMarriageEventTypeMarriageBanns,
		FSMarriageEventTypeMarriageContract,
		FSMarriageEventTypeMarriageLicense,
		FSMarriageEventTypeCensus,
		FSMarriageEventTypeMission,
		FSMarriageEventTypeMarriageSettlement,
		FSMarriageEventTypeSeperation,
		FSMarriageEventTypeTimeOnlyMarriage,
		FSMarriageEventTypeOther
	];
}

@end









@implementation FSMarriage

- (id)initWithHusband:(FSPerson *)husband wife:(FSPerson *)wife
{
	if (!husband)	raiseParamException(@"husband");
	if (!wife)		raiseParamException(@"wife");

    self = [super init];
    if (self) {
		_url				= [[FSURL alloc] initWithSessionID:husband.sessionID];
		_husband			= husband;
		_wife				= wife;
		_characteristics	= [NSMutableDictionary dictionary];
		_changed			= YES;
		_deleted			= NO;
		_version			= 1;
		_events				= [NSMutableArray array];
    }
    return self;
}

+ (FSMarriage *)marriageWithHusband:(FSPerson *)husband wife:(FSPerson *)wife
{
	return [[FSMarriage alloc] initWithHusband:husband wife:wife];
}




#pragma mark - Syncing

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

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;

	if (response.success) {
		NSArray *spouses = NILL([response.body valueForComplexKeyPath:@"persons[first].relationships.spouse"]);
		for (NSDictionary *spouse in spouses) {
			NSString *wifeID = spouse[@"id"];
			if ([wifeID isEqualToString:self.wife.identifier]) {

				_version = [NILL([spouse valueForKeyPath:@"version"]) integerValue];

				// CHARACTERISTICS
				NSArray *characteristics = NILL([spouse valueForKeyPath:@"assertions.characteristics"]);
                for (NSDictionary *characteristicDict in characteristics) {
                    FSCharacteristic *characteristic    = [[FSCharacteristic alloc] init];
                    NSString *dateString                = NILL([characteristicDict valueForKeyPath:@"value.date.normalized"]);
                    if (!dateString) dateString         = NILL([characteristicDict valueForKeyPath:@"value.date.original"]);
                    characteristic.identifier           = NILL([characteristicDict valueForKeyPath:@"value.id"]);
                    characteristic.key                  = NILL([characteristicDict valueForKeyPath:@"value.type"]);
                    characteristic.value                = NILL([characteristicDict valueForKeyPath:@"value.detail"]);
                    characteristic.title                = NILL([characteristicDict valueForKeyPath:@"value.title"]);
                    characteristic.lineage              = NILL([characteristicDict valueForKeyPath:@"value.lineage"]);
                    characteristic.date                 = [NSDateComponents componentsFromString:objectForPreferredKeys(characteristicDict, @"value.date.normalized", @"value.date.original")];
                    characteristic.place                = NILL([characteristicDict valueForKeyPath:@"value.place.original"]);
                    (self.characteristics)[characteristic.key] = characteristic;
                }

				// EVENTS
				NSArray *events = NILL([spouse valueForKeyPath:@"assertions.events"]);
                for (NSDictionary *eventDict in events) {
                    FSMarriageEventType type    = NILL([eventDict valueForKeyPath:@"value.type"]);
                    NSString *identifier        = NILL([eventDict valueForKeyPath:@"value.id"]);
                    FSMarriageEvent *event      = [FSMarriageEvent marriageEventWithType:type identifier:identifier];
                    event.date                  = [NSDateComponents componentsFromString:objectForPreferredKeys(eventDict, @"value.date.normalized", @"value.date.original")];
                    event.place                 = NILL([eventDict valueForKeyPath:@"value.place.normalized.value"]);
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
	_deleted = YES;
	return [self save];
}




#pragma mark - Characteristics

- (NSString *)characteristicForKey:(FSMarriageCharacteristicType)key
{
	FSCharacteristic *characteristic = _characteristics[key];
	return characteristic.value;
}

- (void)setCharacteristic:(NSString *)characteristic forKey:(FSMarriageCharacteristicType)key
{
	if (!characteristic)	raiseParamException(@"property");
	if (!key)				raiseParamException(@"key");

	_changed = YES;
	FSCharacteristic *c = _characteristics[key];
	if (!c) {
		c = [[FSCharacteristic alloc] init];
		c.identifier = nil;
		c.key = key;
		_characteristics[key] = c;
	}
	c.value = characteristic;
}

- (void)reset
{
	for (FSCharacteristic *characteristic in [_characteristics allValues]) {
		[characteristic reset];
	}
}




#pragma mark - Marriage Events

- (void)addMarriageEvent:(FSMarriageEvent *)event
{
	if (!event)	raiseParamException(@"event");

	_changed = YES;
	event.changed = YES;
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
			e.deleted = YES;
	}
}




#pragma mark - Keys

+ (NSArray *)marriageCharacteristics
{
	return @[
		FSMarriageCharacteristicTypeGEDCOMID,
		FSMarriageCharacteristicTypeCommonLawMarriage,
		FSMarriageCharacteristicTypeNumberOfChildren,
		FSMarriageCharacteristicTypeCurrentlySpouses,
		FSMarriageCharacteristicTypeNeverHadChildren,
		FSMarriageCharacteristicTypeNeverMarried,
		FSMarriageCharacteristicTypeOther
	];
}




#pragma mark - Private Methods

- (void)empty
{
	for (FSMarriageEvent *event in self.events) {
		[(NSMutableArray *)self.events removeAllObjects];
	}
	for (FSCharacteristic *characteristic in _characteristics) {
		[_characteristics removeAllObjects];
	}
	self.changed = NO;
	self.deleted = NO;
}

- (MTPocketResponse *)updateMarriage
{
	// don't save blank parents or children
	if (!self.husband.name || [self.husband.name isEqualToString:@""])
		return nil;
	if (!self.wife.name || [self.wife.name isEqualToString:@""])
		return nil;

	// make sure the each is saved. If it is not, return because that save will also save this relationship.
	if (self.husband.isNew)
		return [self.husband save];
	if (self.wife.isNew)
		return [self.wife save];

	NSMutableDictionary *assertions = [NSMutableDictionary dictionary];


	// CHARACTERISTICS
	NSMutableArray *characteristics = [NSMutableArray array];
	for (FSCharacteristicType key in [_characteristics allKeys]) {
		FSCharacteristic *characteristic = (_characteristics)[key];
		NSMutableDictionary *characteristicDict = [NSMutableDictionary dictionary];
		if (characteristic.identifier) characteristicDict[@"id"] = characteristic.identifier;
		if (characteristic.key) characteristicDict[@"type"] = characteristic.key;
		if (characteristic.value) characteristicDict[@"detail"] = characteristic.value;
		[characteristics addObject: @{ @"value" : characteristicDict } ];
	}
	[assertions addEntriesFromDictionary: @{ @"characteristics" : characteristics } ];


	// EVENTS
	NSMutableArray *events = [NSMutableArray array];
	for (FSEvent *event in self.events) {
		NSMutableDictionary *eventInfo = [NSMutableDictionary dictionaryWithObject:event.type forKey:@"type"];
		if (event.date)		eventInfo[@"date"] = @{ @"original" : [event.date stringValue] };
		if (event.place)	eventInfo[@"place"] = @{ @"original" : event.place };

		if ((event.date || event.place)) {
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

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body].send;

	if (response.success) {
		_changed = NO;
		_deleted = NO;
		_version = [NILL([response.body valueForComplexKeyPath:@"persons[first].relationships.spouse[first].version"]) integerValue];
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


    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;

	if (response.success) {
		NSMutableDictionary *relationshipTypesToDelete = [NSMutableDictionary dictionary];
		NSDictionary *relationshipTypes = NILL([response.body valueForComplexKeyPath:@"persons[first].relationships"]);
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
						NSArray *valueID = NILL([assertion valueForKeyPath:@"value.id"]);
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

        response = [MTPocketRequest requestForURL:url method:MTPocketMethodPOST format:MTPocketFormatJSON body:body].send;

		if (response.success) {
			_changed = NO;
			_deleted = NO;
			[self.husband removeMarriage:self];
			[self.wife removeMarriage:self];
		}
	}

	return response;
}


@end
