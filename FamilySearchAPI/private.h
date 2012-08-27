//
//  private.h
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/22/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSMarriage.h"
#import "FSEvent.h"

@interface FSMarriage ()
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