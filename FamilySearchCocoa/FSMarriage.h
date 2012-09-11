//
//  FSMarriage.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSEvent.h"

@class FSPerson;


// Marriage Properties
typedef NSString * FSMarriagePropertyType;
#define FSMarriagePropertyTypeGEDCOMID			@"GEDCOM ID"
#define FSMarriagePropertyTypeCommonLawMarriage	@"Common Law Marriage"
#define FSMarriagePropertyTypeNumberOfChildren	@"Number of Children"
#define FSMarriagePropertyTypeCurrentlySpouses	@"Currently Spouses"
#define FSMarriagePropertyTypeNeverHadChildren	@"Never Had Children"
#define FSMarriagePropertyTypeNeverMarried		@"Never Married"
#define FSMarriagePropertyTypeOther				@"Other"

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
+ (FSMarriageEvent *)marriageEventWithType:(FSMarriageEventType)type identifier:(NSString *)identifier;
@end







@interface FSMarriage : NSObject

@property (readonly)	FSPerson	*husband;
@property (readonly)	FSPerson	*wife;
@property (readonly)	NSArray		*events;

#pragma mark - Constructor
// obtain marriage objects from the FSPerson `spouses` property.

#pragma mark - Properties
- (NSString *)propertyForKey:(FSMarriagePropertyType)key;
- (void)setProperty:(NSString *)property forKey:(FSMarriagePropertyType)key;
- (void)reset;

#pragma mark - Marriage Events
- (void)addMarriageEvent:(FSMarriageEvent *)event;
- (void)removeMarriageEvent:(FSMarriageEvent *)event;

@end
