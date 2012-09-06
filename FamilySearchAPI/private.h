//
//  private.h
//  FamilySearchAPI
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


#define DATE_FORMAT @"dd MMM yyyy"


static inline void raiseException(NSString *name, NSString *reason)
{
	[[NSException exceptionWithName:name reason:reason userInfo:nil] raise];
}

static inline void raiseParamException(NSString *paramName)
{
	raiseException(@"Required paramater was nil", [NSString stringWithFormat:@"'%@' cannot be nil.", paramName]);
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
@property (strong, nonatomic) NSString *sessionID;
- (void)populateFromPersonDictionary:(NSDictionary *)person;
@end




@interface FSMarriage ()
@property (strong, nonatomic)	FSURL				*url;
@property (strong, nonatomic)	NSMutableDictionary	*properties;
@property (nonatomic)			NSInteger			version;
@property (getter = isChanged)	BOOL				changed;	// is newly created or updated and needs to be updated on the server
@property (getter = isDeleted)	BOOL				deleted;	// has been deleted and needs to be deleted from the server
+ (FSMarriage *)marriageWithHusband:(FSPerson *)husband wife:(FSPerson *)wife;
@end




@interface FSEvent()
@property (readonly)			NSString			*localIdentifier;
@property (getter = isDeleted)	BOOL				deleted;	// has been deleted and needs to be deleted from the server
@end




@interface FSProperty : NSObject
@property (strong, nonatomic)	NSString			*identifier;
@property (strong, nonatomic)	FSPropertyType		key;
@property (strong, nonatomic)	NSString			*value;
@property (strong, nonatomic)	NSString			*title;
@property (strong, nonatomic)	NSString			*lineage;
@property (strong, nonatomic)	NSDate				*date;
@property (strong, nonatomic)	NSString			*place;
@property (readonly)			NSString			*previousValue;
@property (readonly)			BOOL				isChanged;
- (void)reset;
- (void)markAsSaved;
@end