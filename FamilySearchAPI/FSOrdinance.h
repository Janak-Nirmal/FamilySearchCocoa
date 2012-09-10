//
//  FSOrdinance.h
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//


// Ordinance Types
typedef NSString * FSOrdinanceType;
#define FSOrdinanceTypeBaptism			@"baptism"
#define FSOrdinanceTypeConfirmation		@"confirmation"
#define FSOrdinanceTypeInitiatory		@"initiatory"
#define FSOrdinanceTypeEndowment		@"endowment"
#define FSOrdinanceTypeSealing			@"sealingToSpouse"

typedef enum {
	FSOrdinanceInventoryTypePersonal,
	FSOrdinanceInventoryTypeChurch
} FSOrdinanceInventoryType;


@interface FSOrdinance : NSObject

@end
