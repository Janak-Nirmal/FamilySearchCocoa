//
//  FSOrdinance.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

/* 
 
 USER STORY // TODO

 1. Find ancestors with ready ordinances
 2. Fetch ordinances for ancestors
 3. Reserve ordinances
	a. Acknowledge compliance with church policies
	b. Verify ordinances have not already been done
	c. Allow user to merge duplicates
	d. Reserve, specifying inventory type
 4. 
 
*/

#import <MTPocket.h>

@class FSPerson;


// Ordinance Types
typedef NSString * FSOrdinanceType;
#define FSOrdinanceTypeBaptism						@"Baptism"
#define FSOrdinanceTypeConfirmation					@"Confirmation"
#define FSOrdinanceTypeInitiatory					@"Initiatory"
#define FSOrdinanceTypeEndowment					@"Endowment"
#define FSOrdinanceTypeSealingToParents				@"Sealing to Parents"
#define FSOrdinanceTypeSealingToSpouse				@"Sealing to Spouse"

// Ordinance Status
typedef NSString * FSOrdinanceStatus;
#define FSOrdinanceStatusCompleted					@"Completed"				// May or may not be an officially recorded ordinance. (could be patron submitted).
#define FSOrdinanceStatusReady						@"Ready"					// Is ready for an Ordinance Request to be printed
#define FSOrdinanceStatusInProgress					@"In Progress"				// Family Ordinance Request has been printed
#define FSOrdinanceStatusNeedsMoreInfo				@"Needs More Information"	// The person record needs more info before the work can be done
#define FSOrdinanceStatusNotReady					@"Not Ready"				// The person has not be deceaced for at least a year
#define FSOrdinanceStatusNotAvailable				@"Not Available"			// Privacy reasons or person lived before 1500 AD
#define FSOrdinanceStatusNotNeeded					@"Not Needed"				// Died before the age of accountability
#define FSOrdinanceStatusOnHold						@"On Hold"					// Someone has printed cards for prerequesited ordinances. Will be taken off hold when they are completed.
#define FSOrdinanceStatusReserved					@"Reserved"					// Someone else has already reserved this ordinance
#define FSOrdinanceStatusNotSet						@"Not Set"					// The status of this person record has not been set


typedef enum {
	FSOrdinanceInventoryTypePersonal,											// You are responsible for getting the ordinance done
	FSOrdinanceInventoryTypeChurch												// The church will assign a patron to do the ordinance
} FSOrdinanceInventoryType;




@interface FSOrdinance : NSObject

@property (readonly)	FSOrdinanceType				type;
@property (readonly)	FSOrdinanceStatus			status;
@property (readonly)	NSDate						*date;
@property (readonly)	NSString					*templeCode;
@property (nonatomic)	FSOrdinanceInventoryType	inventory;
@property (readonly)	BOOL						official;
@property (readonly)	BOOL						completed;
@property (readonly)	BOOL						reservable;
@property (readonly)	BOOL						bornInTheCovenant;
@property (readonly)	NSString					*notes;
@property (readonly)	NSArray						*prerequisites;				// FSOrdinance objects representing ordinances that must be completed before this one.
@property (readonly)	NSSet						*people;					// All the people involved in this ordinance.


#pragma mark - Getting Ordinances
+ (MTPocketResponse *)fetchOrdinancesForPeople:(NSArray *)people;				// Populates the 'ordinances' properties on the passed in people.


#pragma mark - Reserving Ordinances
+ (MTPocketResponse *)reserveOrdinancesForPeople:(NSArray *)people inventory:(FSOrdinanceInventoryType)inventory;
+ (MTPocketResponse *)unreserveOrdinancesForPeople:(NSArray *)people;
+ (MTPocketResponse *)people:(NSArray **)people reservedByCurrentUserWithSessionID:(NSString *)sessionID;	// All the people this current user has reserved ordinances for.


#pragma mark - Printing Ordinance Requests
+ (MTPocketResponse *)familyOrdinanceRequestPDFURL:(NSURL **)PDFURL withSessionID:(NSString *)sessionID;
+ (MTPocketResponse *)urlOfChurchPolicies:(NSURL **)url;


#pragma mark - Keys
+ (NSArray *)ordinanceTypes;
+ (NSArray *)ordinanceStatuses;

@end
