//
//  FSSearch.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 9/6/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <MTPocket.h>


typedef enum {
	FSSearchRelativeTypeSelf,
	FSSearchRelativeTypeMother,
	FSSearchRelativeTypeFather,
	FSSearchRelativeTypeSpouse
} FSSearchRelativeType;


// Person Search Criteria
typedef NSString * FSSearchCriteria;
#define FSSearchCriteriaName				@"name"						// NSString
#define FSSearchCriteriaGivenName			@"givenName"				// NSString
#define FSSearchCriteriaFamilyName			@"familyName"				// NSString
#define FSSearchCriteriaGender				@"gender"					// NSString		@"Male" or @"Female"
#define FSSearchCriteriaBirthDate			@"birthDate"				// NSDate
#define FSSearchCriteriaBirthPlace			@"birthPlace"				// NSString
#define FSSearchCriteriaDeathDate			@"deathDate"				// NSDate
#define FSSearchCriteriaDeathPlace			@"deathPlace"				// NSString
#define FSSearchCriteriaMarriageDate		@"marriageDate"				// NSDate
#define FSSearchCriteriaMarriagePlace		@"marriagePlace"			// NSString


@class FSSearchResults;





@interface FSSearch : NSObject

@property (nonatomic) NSUInteger batchSize;			// Default: 10

#pragma mark - Criteria
- (void)addValue:(NSString *)value forCriteria:(FSSearchCriteria)criteria onRelative:(FSSearchRelativeType)relative matchingExactly:(BOOL)exact;

#pragma mark - Get Results
- (FSSearchResults *)results;

#pragma mark - Keys
+ (NSArray *)criteriaKeys;

@end






@interface FSSearchResults : NSMutableArray

@property (readonly) NSUInteger numberOfResults;

- (MTPocketResponse *)next;							// Returns the next set of paginated results

@end




