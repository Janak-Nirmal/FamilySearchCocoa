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
#import <NSDateComponents+MTDates.h>


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




#pragma mark - Create Events

+ (FSEvent *)eventWithType:(FSPersonEventType)type identifier:(NSString *)identifier
{
	return [[FSEvent alloc] initWithType:type identifier:identifier];
}




#pragma mark - Compare Events

- (BOOL)isEqualToEvent:(FSEvent *)event
{
	BOOL date	= [self.date isEqualToDateComponents:event.date];
//	BOOL place	= [self.place isEqualToString:event.place]; // TODO: normalized name won't match original. Can't update on save because it's not returned. talk to API guys.
	BOOL select	= self.selected == event.selected;
	BOOL type	= [self.type isEqualToString:event.type];
//	BOOL ident	= self.identifier && event.identifier && [self.identifier isEqualToString:event.identifier];
	BOOL equal	= date && select && type;
	
	if (self == event || equal)
		return YES;

	return NO;
}



#pragma mark - Keys

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
