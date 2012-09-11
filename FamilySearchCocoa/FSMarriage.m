//
//  FSMarriage.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSMarriage.h"
#import "private.h"




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
	FSProperty *property = [_properties objectForKey:key];
	return property.value;
}

- (void)setProperty:(NSString *)property forKey:(FSMarriagePropertyType)key
{
	if (!property)	raiseParamException(@"property");
	if (!key)		raiseParamException(@"key");

	_changed = YES;
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




#pragma mark - Marriage Events

- (void)addMarriageEvent:(FSMarriageEvent *)event
{
	if (!event)	raiseParamException(@"event");

	_changed = YES;
	for (FSEvent *e in _events) {
		if ([e isEqualToEvent:event]) {
			[(NSMutableArray *)_events replaceObjectAtIndex:[_events indexOfObject:e] withObject:event];
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


@end
