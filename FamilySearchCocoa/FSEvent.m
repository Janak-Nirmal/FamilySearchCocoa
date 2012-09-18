//
//  FSEvent.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSEvent.h"
#import "private.h"
#import <NSDate+MTDates.h>


NSString *randomStringWithLength(NSInteger length)
{
	unichar string[length];
	for (NSInteger i = 0; i < length; i++) {
		unichar r = (arc4random() % 25) + 65;
		string[i] = r;
	}
	return [[NSString stringWithCharacters:string length:length] lowercaseString];
}




@implementation FSEvent


- (id)initWithType:(FSPersonEventType)type identifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _type				= type;
		_identifier			= identifier;
		_selected			= NO;
		_changed			= NO;
		_localIdentifier	= randomStringWithLength(5);
		_deleted			= NO;
    }
    return self;
}

+ (FSEvent *)eventWithType:(FSPersonEventType)type identifier:(NSString *)identifier
{
	return [[FSEvent alloc] initWithType:type identifier:identifier];
}

- (BOOL)isEqualToEvent:(FSEvent *)event
{
	if (self == event || [self.type isEqualToString:event.type]) // TODO: this needs to be more precise. (e.g. mutliple Mission events)
		return YES;
	return NO;
}

+ (NSArray *)eventTypes
{
	return @[
		FSPersonEventTypeAdoption,
		FSPersonEventTypeAdultChristening,
		FSPersonEventTypeBaptism,
		FSPersonEventTypeConfirmation,
		FSPersonEventTypeBirth,
		FSPersonEventTypeBlessing,
		FSPersonEventTypeBurial,
		FSPersonEventTypeChristening,
		FSPersonEventTypeCremation,
		FSPersonEventTypeDeath,
		FSPersonEventTypeGraduation,
		FSPersonEventTypeImmigration,
		FSPersonEventTypeMilitaryService,
		FSPersonEventTypeMission,
		FSPersonEventTypeMove,
		FSPersonEventTypeNaturalization,
		FSPersonEventTypeProbate,
		FSPersonEventTypeRetirement,
		FSPersonEventTypeWill,
		FSPersonEventTypeCensus,
		FSPersonEventTypeCircumcision,
		FSPersonEventTypeEmigration,
		FSPersonEventTypeExcommunication,
		FSPersonEventTypeFirstCommunion,
		FSPersonEventTypeFirstKnownChild,
		FSPersonEventTypeFuneral,
		FSPersonEventTypeHospitalization,
		FSPersonEventTypeIllness,
		FSPersonEventTypeNaming,
		FSPersonEventTypeMiscarriage,
		FSPersonEventTypeOrdination,
		FSPersonEventTypeOther
	];
}



#pragma mark - Private Methods

- (void)setDate:(NSDateComponents *)date
{
	_date		= date;
	_changed	= YES;
}

- (void)setPlace:(NSString *)place
{
	_place		= place;
	_changed	= YES;
}

- (void)setSelected:(BOOL)selected
{
	_selected	= selected;
	_changed	= YES;
}


@end
