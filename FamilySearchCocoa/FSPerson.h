//
//  FSPerson.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

/*
 
 NOTE: Any methods of any class returning an MTPocketResponse
 object is a blocking, synchronous call so you should call it
 on another thread. All others are non-blocking.

*/

#import <MTPocket.h>
#import "FSOrdinance.h"

@class FSEvent, FSMarriage, FSOrdinance, FSAuth;


// Person Properties
typedef NSString * FSPropertyType;
#define FSPropertyTypeCasteName					@"Caste Name"
#define FSPropertyTypeClanName					@"Clan Name"
#define FSPropertyTypeNationalID				@"National ID"
#define FSPropertyTypeNationalOrigin			@"National Origin"
#define FSPropertyTypeTitleOfNobility			@"Title of Nobility"
#define FSPropertyTypeOccupation				@"Occupation"
#define FSPropertyTypePhysicalDescription		@"Physical Description"
#define FSPropertyTypeRace						@"Race"
#define FSPropertyTypeReligiousAffiliation		@"Religious Affiliation"
#define FSPropertyTypeStillborn					@"Stillborn"
#define FSPropertyTypeTribeName					@"Tribe Name"
#define FSPropertyTypeGEDCOMID					@"GEDCOM ID"
#define FSPropertyTypeCommonLawMarriage			@"Common Law Marriage"
#define FSPropertyTypeOther						@"Other"
#define FSPropertyTypeNumberOfChildren			@"Number of Children"
#define FSPropertyTypeNumberOfMarriages			@"Number of Marriages"
#define FSPropertyTypeCurrentlySpouses			@"Currently Spouses"
#define FSPropertyTypeDiedBeforeEight			@"Died before Eight"
#define FSPropertyTypeNameSake					@"Name Sake"
#define FSPropertyTypeNeverHadChildren			@"Never Had Children"
#define FSPropertyTypeNeverMarried				@"Never Married"
#define FSPropertyTypeNotAccountable			@"Not Accountable"
#define FSPropertyTypePossessions				@"Possessions"
#define FSPropertyTypeResidence					@"Residence"
#define FSPropertyTypeScholasticAchievement		@"Scholastic Achievement"
#define FSPropertyTypeSocialSecurityNumber		@"Social Security Number"
#define FSPropertyTypeTwin						@"Twin"


// Lineage Type
typedef NSString * FSLineageType;
#define FSLineageTypeBiological					@"Biological"
#define FSLineageTypeAdoptive					@"Adoptive"
#define FSLineageTypeFoster						@"Foster"
#define FSLineageTypeGuardianship				@"Guardianship"
#define FSLineageTypeStep						@"Step"
#define FSLineageTypeUnknown					@"Unknown"
#define FSLineageTypeHeadOfHousehold			@"Household"
#define FSLineageTypeOther						@"Other"







@interface FSPerson : NSObject

@property (readonly)		  NSString	*identifier;
@property (strong, nonatomic) NSString	*name;                  // @"Adam Kirk"
@property (strong, nonatomic) NSString	*gender;				// @"Male" or @"Female"
@property (readonly)		  BOOL		isAlive;				// Default: YES. You must add a death event for the system to return NO. Not editable by user.
@property (readonly)		  BOOL		isModifiable;			// Can be modified by the current logged in contributor
@property (readonly)		  BOOL		isNew;					// Has been created on the client but has not be saved to the server
@property (readonly)		  NSDate	*lastModifiedDate;
@property (readonly)		  NSArray	*parents;				// Returns array of FSPerson objects
@property (readonly)		  NSArray	*children;				// Returns array of FSperson objects
@property (readonly)		  NSArray	*spouses;				// Returns array of FSMarriage objects. See FSMarriage.h for more info.
@property (readonly)		  NSArray	*events;				// Returns array of FSEvent objects
@property (readonly)		  NSArray	*ordinances;			// Returns array of FSOrdinance objects. See FSOrdinance.h for more info.
@property (strong, nonatomic) void (^onChange)();				// The passed in block is invoked whenever the person is changed.
@property (strong, nonatomic) void (^onSync)();					// The passed in block is invoked whenever the person synced with the server.



#pragma mark - Getting A Person
+ (FSPerson *)currentUserWithSessionID:(NSString *)sessionID;
+ (FSPerson *)personWithSessionID:(NSString *)sessionID identifier:(NSString *)identifier;


#pragma mark - Syncing
- (MTPocketResponse *)fetch;												// If called when identifier is (not nil => reset w server info)	| (nil => throws an exception)
- (MTPocketResponse *)save;													// If called when identifier is (not nil => update person)			| (nil => create new person)
- (MTPocketResponse *)fetchAncestors:(NSUInteger)generations;


#pragma mark - Properties
- (NSString *)propertyForKey:(FSPropertyType)key;
- (void)setProperty:(NSString *)property forKey:(FSPropertyType)key;
- (void)reset;																// reverts all property values back to their last-saved values


#pragma mark - Parents
- (void)addParent:(FSPerson *)parent withLineage:(FSLineageType)lineage;
- (void)removeParent:(FSPerson *)parent;


#pragma mark - Children
- (void)addChild:(FSPerson *)child withLineage:(FSLineageType)lineage;
- (void)removeChild:(FSPerson *)child;


#pragma mark - Spouses
- (FSMarriage *)addSpouse:(FSPerson *)spouse;
- (FSMarriage *)marriageWithSpouse:(FSPerson *)spouse;						// Returns nil if there is no marriage with the spouse
- (void)removeSpouse:(FSPerson *)spouse;


#pragma mark - Events
- (void)addEvent:(FSEvent *)event;
- (void)removeEvent:(FSEvent *)event;

@property (nonatomic, strong) NSDate	*birthDate;							/*  These are for convenience.       */
@property (nonatomic, strong) NSString	*birthPlace;						/*  Does the same thing as           */
@property (nonatomic, strong) NSDate	*deathDate;							/*  creating an event and            */
@property (nonatomic, strong) NSString	*deathPlace;						/*  adding it with addEvent:         */


#pragma mark - Misc
- (MTPocketResponse *)duplicates:(NSArray **)duplicates;					// returns possible duplicates of this person (to potentially be merged)
- (void)addUnofficialOrdinanceWithType:(FSOrdinanceType)type date:(NSDate *)date templeCode:(NSString *)templeCode;
+ (MTPocketResponse *)batchFetchPeople:(NSArray *)people;					// Will fetch all properties and ordinance information for everyone in the array.


@end

