//
//  private.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/22/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSPerson.h"
#import "FSAuth.h"
#import "FSMarriage.h"
#import "FSEvent.h"
#import "FSURL.h"
#import "FSOrdinance.h"
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
	id key1Result = [obj valueForComplexKeyPath:key1];
	id key2Result = [obj valueForComplexKeyPath:key2];
	return key1Result ? key1Result : key2Result;
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
- (id)initWithSessionID:(NSString *)sessionID;
- (NSURL *)urlWithModule:(NSString *)module
				 version:(NSUInteger)version
				resource:(NSString *)resource
			 identifiers:(NSArray *)identifiers
				  params:(FSQueryParameter)params
					misc:(NSString *)misc;
@end




@interface FSPerson ()
@property (strong, nonatomic)	NSString	*sessionID;
@property (readonly)			BOOL		isMale;
- (void)populateFromPersonDictionary:(NSDictionary *)person;
- (void)removeMarriage:(FSMarriage *)marriage;
- (void)addOrReplaceOrdinance:(FSOrdinance *)ordinance;
- (BOOL)isSamePerson:(FSPerson *)person;
@end




@interface FSMarriage ()
@property (strong, nonatomic)	FSURL				*url;
@property (strong, nonatomic)	NSMutableDictionary	*properties;
@property (nonatomic)			NSInteger			version;
@property (getter = isChanged)	BOOL				changed;	// is newly created or updated and needs to be updated on the server
@property (getter = isDeleted)	BOOL				deleted;	// has been deleted and needs to be deleted from the server
+ (FSMarriage *)marriageWithHusband:(FSPerson *)husband wife:(FSPerson *)wife;
- (MTPocketResponse *)destroy;
@end




@interface FSEvent()
@property (readonly)						NSString	*localIdentifier;
@property (nonatomic, getter = isDeleted)	BOOL		deleted;	// has been deleted and needs to be deleted from the server
@property (nonatomic, getter = isChanged)	BOOL		changed;
@property (nonatomic, getter = isSelected)	BOOL		selected;	// is selected for the person summary
@end




@interface FSOrdinance ()
@property (strong, nonatomic) NSString *identifier;
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
@property (strong, nonatomic)	NSString			*identifier;
@property (strong, nonatomic)	FSPropertyType		key;
@property (strong, nonatomic)	NSString			*value;
@property (strong, nonatomic)	NSString			*title;
@property (strong, nonatomic)	NSString			*lineage;
@property (strong, nonatomic)	NSDateComponents	*date;
@property (strong, nonatomic)	NSString			*place;
@property (readonly)			NSString			*previousValue;
@property (readonly)			BOOL				isChanged;
- (void)reset;
- (void)markAsSaved;
@end


