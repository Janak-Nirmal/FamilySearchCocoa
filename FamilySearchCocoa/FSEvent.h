//
//  FSEvent.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//


// Person Event Types
typedef NSString * FSPersonEventType;
#define FSPersonEventTypeAdoption				@"Adoption"
#define FSPersonEventTypeAdultChristening		@"Adult Christening"
#define FSPersonEventTypeBaptism				@"Baptism"
#define FSPersonEventTypeConfirmation			@"Confirmation"
#define FSPersonEventTypeBirth					@"Birth"
#define FSPersonEventTypeBlessing				@"Blessing"
#define FSPersonEventTypeBurial					@"Burial"
#define FSPersonEventTypeChristening			@"Christening"
#define FSPersonEventTypeCremation				@"Cremation"
#define FSPersonEventTypeDeath					@"Death"
#define FSPersonEventTypeGraduation				@"Graduation"
#define FSPersonEventTypeImmigration			@"Immigration"
#define FSPersonEventTypeMilitaryService		@"Military Service"
#define FSPersonEventTypeMission				@"Mission"
#define FSPersonEventTypeMove					@"Move"
#define FSPersonEventTypeNaturalization			@"Naturalization"
#define FSPersonEventTypeProbate				@"Probate"
#define FSPersonEventTypeRetirement				@"Retirement"
#define FSPersonEventTypeWill					@"Will"
#define FSPersonEventTypeCensus					@"Census"
#define FSPersonEventTypeCircumcision			@"Circumcision"
#define FSPersonEventTypeEmigration				@"Emigration"
#define FSPersonEventTypeExcommunication		@"Excommunication"
#define FSPersonEventTypeFirstCommunion			@"FirstCommunion"
#define FSPersonEventTypeFirstKnownChild		@"FirstKnownChild"
#define FSPersonEventTypeFuneral				@"Funeral"
#define FSPersonEventTypeHospitalization		@"Hospitalization"
#define FSPersonEventTypeIllness				@"Illness"
#define FSPersonEventTypeNaming					@"Naming"
#define FSPersonEventTypeMiscarriage			@"Miscarriage"
#define FSPersonEventTypeOrdination				@"Ordination"
#define FSPersonEventTypeOther					@"Other"



@class FSPerson;


@interface FSEvent : NSObject

@property (readonly)						NSString			*identifier;
@property (readonly)						FSPersonEventType	type;
@property (strong, nonatomic)				NSDateComponents	*date;
@property (strong, nonatomic)				NSString			*place;

#pragma mark - Create Event
+ (FSEvent *)eventWithType:(FSPersonEventType)type identifier:(NSString *)identifier;

#pragma mark - Compare Events
- (BOOL)isEqualToEvent:(FSEvent *)event;

#pragma mark - Keys
+ (NSArray *)eventTypes;

@end

