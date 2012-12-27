//
//  private.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/22/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSPerson.h"
#import "FSUser.h"
#import "FSMarriage.h"
#import "FSEvent.h"
#import "FSURL.h"
#import "FSOrdinance.h"
#import "FSArtifact.h"
#import <NSObject+MTJSONUtils.h>


#define DATE_FORMAT @"dd MMM yyyy"


static inline void raiseException(NSString *name, NSString *reason)
{
	[[NSException exceptionWithName:name reason:reason userInfo:nil] raise];
}

static inline void raiseParamException(NSString *paramName)
{
	raiseException(@"Required paramater was nil", [NSString stringWithFormat:@"'%@' cannot be nil.", paramName]);
}

static inline id objectForPreferredKeys(id obj, NSString *key1, NSString *key2)
{
	id key1Result = NILL([obj valueForKeyPath:key1]);
	id key2Result = NILL([obj valueForKeyPath:key2]);
	return key1Result ? key1Result : key2Result;
}

// These flags prioritize where "selected" attributes are coming from and which take precedence.
// For example: if you set a name as local summary, you have to call fetch before you can save it
// as the summary remotely. In calling fetch, you don't want the current remote summary overwriting
// the newly set local selected summary value.
typedef enum {
	FSSummaryLocalNO,	// Think of this as a "solid" NO; it absolutely not the summary
	FSSummaryLocalYES,	// "solid" YES. This is the most recently set summary so no matter what the summary is on the server, this overrides it
	FSSummaryRemoteNO,	// This of this as a "soft" NO; This will not be set if the current value is a local YES.
	FSSummaryRemoteYES	// "soft" YES. When finding the summary value, the solid yes will be chosen before this.
} FSSummary;


static inline BOOL summaryFlagCanOverwriteFlag(FSSummary flag1, FSSummary flag2)
{
	BOOL solidYes	= flag1 == FSSummaryLocalYES;										// A local	YES can overwrite anything
	BOOL solidNo	= flag1 == FSSummaryLocalNO		&& flag2 != FSSummaryRemoteYES;		// A local	NO	can overwrite anything except a remote YES
	BOOL softYes	= flag1 == FSSummaryRemoteYES	&& flag2 != FSSummaryLocalYES;		// A remote YES can overwrite anything except a local YES
	BOOL softNo		= flag1 == FSSummaryRemoteNO	&& flag2 == FSSummaryRemoteYES;		// A remote NO	can overwrite only a remote YES
	return solidYes || solidNo || softYes || softNo;
}

// This function just makes sure that even though a NO can overwrite a YES, it won't be preferred above a YES
static inline BOOL summaryFlagChosenBeforeFlag(FSSummary flag1, FSSummary flag2)
{
	if (flag1 == FSSummaryLocalNO	&& flag2 == FSSummaryLocalYES)	return NO;			// A local	YES will be chosen before a local NO
	if (flag1 == FSSummaryRemoteNO	&& flag2 == FSSummaryRemoteYES) return NO;			// A remote YES will be chosen before a remote NO
	return summaryFlagCanOverwriteFlag(flag1, flag2);
}


// FSQueryParameter (Bitwise OR these together to generate a query string)
typedef enum { 
	FSQNames				= 1UL << 1,
	FSQGenders				= 1UL << 2,
	FSQEvents				= 1UL << 3,
	FSQCharacteristics		= 1UL << 4,
	FSQExists				= 1UL << 5,
	FSQValues				= 1UL << 6,
	FSQOrdinances			= 1UL << 7,
	FSQAssertions			= 1UL << 8,
	FSQFamilies				= 1UL << 9,
	FSQChildren				= 1UL << 10,
	FSQParents				= 1UL << 11,
	FSQPersonas				= 1UL << 12,
	FSQProperties			= 1UL << 13,
	FSQIdentifiers			= 1UL << 14,
	FSQDispositions			= 1UL << 15,
	FSQContributors			= 1UL << 16
} FSQueryParameter;

FSQueryParameter defaultQueryParameters();
FSQueryParameter familyQueryParameters();

@interface FSURL ()
+ (void)setSessionID:(NSString *)sessionID;
+ (NSURL *)urlWithModule:(NSString *)module
				 version:(NSUInteger)version
				resource:(NSString *)resource
			 identifiers:(NSArray *)identifiers
				  params:(FSQueryParameter)params
					misc:(NSString *)misc;
@end




@interface FSPerson ()
@property (readonly)			BOOL            isMale;
@property (strong, nonatomic)   NSMutableArray  *taggedPersonIDs;   // TODO
- (void)populateFromPersonDictionary:(NSDictionary *)person;
- (void)removeMarriage:(FSMarriage *)marriage;
- (void)addOrReplaceOrdinance:(FSOrdinance *)ordinance;
- (BOOL)isSamePerson:(FSPerson *)person;
@end




@interface FSMarriage ()
@property (strong, nonatomic)	NSMutableDictionary	*characteristics;
@property (nonatomic)			NSInteger			version;
@property (getter = isChanged)	BOOL				changed;	// is newly created or updated and needs to be updated on the server
@property (getter = isDeleted)	BOOL				deleted;	// has been deleted and needs to be deleted from the server
- (MTPocketResponse *)destroy;
@end




@interface FSEvent()
@property (readonly)						NSString	*localIdentifier;
@property (nonatomic, getter = isDeleted)	BOOL		deleted;	// has been deleted and needs to be deleted from the server
@property (nonatomic, getter = isChanged)	BOOL		changed;
@property (nonatomic)						FSSummary	summary;	// is selected for the person summary
@end




@interface FSOrdinance ()
@property (strong, nonatomic) NSString *identifier;					// currently not being used because the server returns nothing
@property (nonatomic) BOOL userAdded;
+ (FSOrdinance *)ordinanceWithType:(FSOrdinanceType)type;
- (void)setStatus:(FSOrdinanceStatus)status;
- (void)setDate:(NSDate *)date;
- (void)setTempleCode:(NSString *)templeCode;
- (void)setOfficial:(BOOL)official;
- (void)setCompleted:(BOOL)completed;
- (void)setReservable:(BOOL)reservable;
- (void)setBornInTheCovenant:(BOOL)bornInTheCovenant;
- (void)setNotes:(NSString *)notes;
- (void)addPerson:(FSPerson *)person;
- (BOOL)isEqualToOrdinance:(FSOrdinance *)ordinance;
@end





@interface FSProperty : NSObject
@property (strong, nonatomic)				NSString *identifier;
@property (strong, nonatomic)				FSPropertyType type;
@property (strong, nonatomic)				NSString *value;
@property (nonatomic)						FSSummary summary;
+ (FSProperty *)propertyWithType:(FSPropertyType)type withValue:(NSString *)value identifier:(NSString *)identifier summary:(FSSummary)summary;
@end




@interface FSCharacteristic : NSObject
@property (strong, nonatomic)	NSString				*identifier;
@property (strong, nonatomic)	FSCharacteristicType	key;
@property (strong, nonatomic)	NSString				*value;
@property (strong, nonatomic)	NSString				*title;
@property (strong, nonatomic)	NSString				*lineage;
@property (strong, nonatomic)	NSDateComponents		*date;
@property (strong, nonatomic)	NSString				*place;
@property (readonly)			NSString				*previousValue;
@property (readonly)			BOOL					isChanged;
- (void)reset;
- (void)markAsSaved;
@end


