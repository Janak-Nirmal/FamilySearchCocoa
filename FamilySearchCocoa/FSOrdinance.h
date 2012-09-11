//
//  FSOrdinance.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//


// Ordinance Types
typedef NSString * FSOrdinanceType;
#define FSOrdinanceTypeBaptism				@"Baptism"
#define FSOrdinanceTypeConfirmation			@"Confirmation"
#define FSOrdinanceTypeInitiatory			@"Initiatory"
#define FSOrdinanceTypeEndowment			@"Endowment"
#define FSOrdinanceTypeSealingToParents		@"Sealing to Parents"
#define FSOrdinanceTypeSealingToSpouse		@"Sealing to Spouse"

typedef enum {
	FSOrdinanceInventoryTypePersonal,
	FSOrdinanceInventoryTypeChurch
} FSOrdinanceInventoryType;




@interface FSOrdinance : NSObject

@property (readonly)			NSString		*identifier;
@property (readonly)			FSOrdinanceType type;
@property (nonatomic)			BOOL			official;
@property (strong, nonatomic)	NSDate			*date;
@property (strong, nonatomic)	NSString		*templeCode;

#pragma mark - Constructor
// obtain marriage objects from the FSPerson `ordinances` property.

@end
