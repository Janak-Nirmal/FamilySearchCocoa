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
#import "FSEvent.h"

@class FSMarriage, FSOrdinance, FSUser;


// Person Property
typedef NSString * FSPropertyType;
#define FSPropertyTypeName		@"Name"
#define FSPropertyTypeGender	@"Gender"


// Person Characteristics
typedef NSString * FSCharacteristicType;
#define FSCharacteristicTypeCasteName				@"Caste Name"
#define FSCharacteristicTypeClanName				@"Clan Name"
#define FSCharacteristicTypeNationalID				@"National ID"
#define FSCharacteristicTypeNationalOrigin			@"National Origin"
#define FSCharacteristicTypeTitleOfNobility			@"Title of Nobility"
#define FSCharacteristicTypeOccupation				@"Occupation"
#define FSCharacteristicTypePhysicalDescription		@"Physical Description"
#define FSCharacteristicTypeRace					@"Race"
#define FSCharacteristicTypeReligiousAffiliation	@"Religious Affiliation"
#define FSCharacteristicTypeStillborn				@"Stillborn"
#define FSCharacteristicTypeTribeName				@"Tribe Name"
#define FSCharacteristicTypeGEDCOMID				@"GEDCOM ID"
#define FSCharacteristicTypeCommonLawMarriage		@"Common Law Marriage"
#define FSCharacteristicTypeOther					@"Other"
#define FSCharacteristicTypeNumberOfChildren		@"Number of Children"
#define FSCharacteristicTypeNumberOfMarriages		@"Number of Marriages"
#define FSCharacteristicTypeCurrentlySpouses		@"Currently Spouses"
#define FSCharacteristicTypeDiedBeforeEight			@"Died before Eight"
#define FSCharacteristicTypeNameSake				@"Name Sake"
#define FSCharacteristicTypeNeverHadChildren		@"Never Had Children"
#define FSCharacteristicTypeNeverMarried			@"Never Married"
#define FSCharacteristicTypeNotAccountable			@"Not Accountable"
#define FSCharacteristicTypePossessions				@"Possessions"
#define FSCharacteristicTypeResidence				@"Residence"
#define FSCharacteristicTypeScholasticAchievement	@"Scholastic Achievement"
#define FSCharacteristicTypeSocialSecurityNumber	@"Social Security Number"
#define FSCharacteristicTypeTwin					@"Twin"


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


typedef enum {
	FSPersonSyncResultCreated,
	FSPersonSyncResultFetched,
	FSPersonSyncResultUpdated,
	FSPersonSyncResultDeleted,
	FSPersonSyncResultNone
} FSPersonSyncResult;







@interface FSPerson : NSObject

@property (readonly)		  NSString	*identifier;
@property (readonly)		  BOOL		isAlive;				// Default: YES. You must add a death event for the system to return NO. Not editable by user.
@property (readonly)		  BOOL		isModifiable;			// Can be modified by the current logged in contributor
@property (readonly)		  BOOL		isNew;					// Has been created on the client but has not be saved to the server
@property (readonly)          BOOL      isFetched;              // Has been fetched from the server.
@property (readonly)		  NSDate	*lastModifiedDate;
@property (readonly)		  NSArray	*parents;				// Returns array of FSPerson objects
@property (readonly)		  NSArray	*children;				// Returns array of FSperson objects
@property (readonly)		  NSArray	*marriages;				// Returns array of FSMarriage objects. See FSMarriage.h for more info.
@property (readonly)		  NSArray	*events;				// Returns array of FSEvent objects
@property (readonly)		  NSArray	*ordinances;			// Returns array of FSOrdinance objects. See FSOrdinance.h for more info.
@property (strong, nonatomic) void (^onChange)(FSPerson *p);	// The passed in block is invoked whenever the person is changed.
@property (strong, nonatomic) void (^onSync)(FSPerson *p, FSPersonSyncResult result);		// The passed in block is invoked whenever the person synced with the server.



#pragma mark - Getting A Person
+ (FSPerson *)person;
+ (FSPerson *)personWithIdentifier:(NSString *)identifier;


#pragma mark - Syncing
- (MTPocketResponse *)fetch;									// If called when identifier is (not nil => reset w server info)	| (nil => throws an exception)
- (MTPocketResponse *)save;										// If called when identifier is (not nil => update person)			| (nil => create new person)
- (MTPocketResponse *)fetchAncestors:(NSUInteger)generations;
+ (MTPocketResponse *)batchFetchPeople:(NSArray *)people;
// After setting name, gender and birthlike/deathlike events, you must call save, then fetch, then this
// in order to save them as the "primary" values for the person. This will not be necessary in a future
// API, but until then...
- (MTPocketResponse *)saveSummary;


#pragma mark - Properties
@property (strong, nonatomic) NSString	*name;                  // @"Adam Kirk"
@property (strong, nonatomic) NSString	*gender;				// @"Male" or @"Female"
- (NSArray *)loggedValuesForPropertyType:(FSPropertyType)type;


#pragma mark - Characteristics
- (NSString *)characteristicForKey:(FSCharacteristicType)key;
- (void)setCharacteristic:(NSString *)characteristic forKey:(FSCharacteristicType)key;
- (void)reset;													// reverts all characteristic values back to their last-saved values


#pragma mark - Parents
- (void)addParent:(FSPerson *)parent withLineage:(FSLineageType)lineage;	// You must marry two parents or sometimes one won't be returned in the pedigree (fetchAncestors:) call.
- (void)removeParent:(FSPerson *)parent;
- (NSArray *)motherAndFather;									// returns 2 parents no matter what. Will create new persons and add as parents if it has to.


#pragma mark - Children
- (void)addChild:(FSPerson *)child withLineage:(FSLineageType)lineage;
- (void)removeChild:(FSPerson *)child;


#pragma mark - Marriages
- (void)addMarriage:(FSMarriage *)marriage;
- (void)removeMarriage:(FSMarriage *)marriage;
- (FSMarriage *)marriageWithSpouse:(FSPerson *)spouse;			// Returns nil if there is no marriage with the spouse


#pragma mark - Events
- (void)addEvent:(FSEvent *)event;
- (void)removeEvent:(FSEvent *)event;
- (NSArray *)loggedEventsOfType:(FSPersonEventType)type;

@property (nonatomic, strong) NSDateComponents	*birthDate;		/*  These are for convenience.       */
@property (nonatomic, strong) NSString			*birthPlace;	/*  Does the same thing as           */
@property (nonatomic, strong) NSDateComponents	*deathDate;		/*  creating an event and            */
@property (nonatomic, strong) NSString			*deathPlace;	/*  adding it with addEvent:         */


#pragma mark - Misc
- (NSArray *)duplicatesWithResponse:(MTPocketResponse **)response;		// returns possible duplicates of this person (to potentially be merged)
- (void)addUnofficialOrdinanceWithType:(FSOrdinanceType)type date:(NSDate *)date templeCode:(NSString *)templeCode;


#pragma mark - Keys
+ (NSArray *)characteristics;									// An array of all person characteristics. (e.g. for displaying in a UI list)
+ (NSArray *)lineageTypes;										// An array of the lineange types a relationship can have


@end

