//
//  FSMarriage.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSEvent.h"
#import <MTPocket.h>

@class FSPerson;


// Marriage Characteristics
typedef NSString * FSMarriageCharacteristicType;
#define FSMarriageCharacteristicTypeGEDCOMID			@"GEDCOM ID"
#define FSMarriageCharacteristicTypeCommonLawMarriage	@"Common Law Marriage"
#define FSMarriageCharacteristicTypeNumberOfChildren	@"Number of Children"
#define FSMarriageCharacteristicTypeCurrentlySpouses	@"Currently Spouses"
#define FSMarriageCharacteristicTypeNeverHadChildren	@"Never Had Children"
#define FSMarriageCharacteristicTypeNeverMarried		@"Never Married"
#define FSMarriageCharacteristicTypeOther				@"Other"

// Marriage Event Types
typedef NSString * FSMarriageEventType;
#define FSMarriageEventTypeAnnulment			@"Annulment"
#define FSMarriageEventTypeDivorce				@"Divorce"
#define FSMarriageEventTypeDivorceFiling		@"Divorce Filing"
#define FSMarriageEventTypeEngagement			@"Engagement"
#define FSMarriageEventTypeMarriage				@"Marriage"
#define FSMarriageEventTypeMarriageBanns		@"Marriage Banns"
#define FSMarriageEventTypeMarriageContract		@"Marriage Contract"
#define FSMarriageEventTypeMarriageLicense		@"Marriage License"
#define FSMarriageEventTypeCensus				@"Census"
#define FSMarriageEventTypeMission				@"Mission"
#define FSMarriageEventTypeMarriageSettlement	@"Marriage Settlement"
#define FSMarriageEventTypeSeperation			@"Seperation"
#define FSMarriageEventTypeTimeOnlyMarriage		@"Time Only Marriage"
#define FSMarriageEventTypeOther				@"Other"




@interface FSMarriageEvent : FSEvent

@property (readonly)	FSMarriageEventType	type;

#pragma mark - Create Marriag Event
+ (FSMarriageEvent *)marriageEventWithType:(FSMarriageEventType)type identifier:(NSString *)identifier;

#pragma mark - Keys
+ (NSArray *)marriageEventTypes;

@end







@interface FSMarriage : NSObject

@property (readonly)	FSPerson	*husband;
@property (readonly)	FSPerson	*wife;
@property (readonly)	NSArray		*events;


#pragma mark - Constructor
+ (FSMarriage *)marriageWithHusband:(FSPerson *)husband wife:(FSPerson *)wife;


#pragma mark - Syncing
- (MTPocketResponse *)fetch;	// Fetch all the marriage events and properties for this marriage
- (MTPocketResponse *)save;		// Save events and properties of this marriage to the server


#pragma mark - Characteristics
- (NSString *)characteristicForKey:(FSMarriageCharacteristicType)key;
- (void)setCharacteristic:(NSString *)characteristic forKey:(FSMarriageCharacteristicType)key;
- (void)reset;


#pragma mark - Marriage Events
- (void)addMarriageEvent:(FSMarriageEvent *)event;
- (void)removeMarriageEvent:(FSMarriageEvent *)event;


#pragma mark - Keys
+ (NSArray *)marriageCharacteristics;


@end
