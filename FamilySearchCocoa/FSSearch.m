//
//  FSSearch.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 9/6/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <NSDate+MTDates.h>
#import <NSObject+MTJSONUtils.h>
#import "FSSearch.h"
#import "private.h"





@interface FSSearch ()
@property (strong, nonatomic) NSMutableArray *criteria;
@end





@interface FSSearchResults ()
@property (strong, nonatomic)	NSMutableArray	*backingStore;
@property (strong, nonatomic)	FSURL			*url;
@property (strong, nonatomic)	NSString		*contextID;
@property (nonatomic)			NSUInteger		currentIndex;
@property (nonatomic)			NSUInteger		batchSize;
@property (nonatomic)			NSMutableArray	*criteria;
@end





@implementation FSSearch




#pragma mark - Create Search

- (id)init
{
    self = [super init];
    if (self) {
        _criteria		= [NSMutableArray array];
		_batchSize		= 10;
    }
    return self;
}




#pragma mark - Criteria

- (void)addValue:(NSString *)value forCriteria:(FSSearchCriteria)criteria onRelative:(FSSearchRelativeType)relative matchingExactly:(BOOL)exact
{
	switch (relative) {
		case FSSearchRelativeTypeSelf:
			break;
		case FSSearchRelativeTypeFather:
			criteria = [NSString stringWithFormat:@"father.%@", criteria];
			break;
		case FSSearchRelativeTypeMother:
			criteria = [NSString stringWithFormat:@"mother.%@", criteria];
			break;
		case FSSearchRelativeTypeSpouse:
			criteria = [NSString stringWithFormat:@"spouse.%@", criteria];
			break;
		default:
			break;
	}
	if (exact && ![criteria isEqualToString:FSSearchCriteriaGender]) criteria = [NSString stringWithFormat:@"%@.exact", criteria];
	[_criteria addObject: @{ @"Criteria" : criteria, @"Value" : value } ];
}




#pragma mark - Get Results

- (FSSearchResults *)results
{
	FSSearchResults *results = [[FSSearchResults alloc] init];
	results.batchSize = _batchSize;
	results.criteria = _criteria;
	return results;
}




#pragma mark - Keys

+ (NSArray *)criteriaKeys
{
	return @[
		FSSearchCriteriaName,
		FSSearchCriteriaGivenName,
		FSSearchCriteriaFamilyName,
		FSSearchCriteriaGender,
		FSSearchCriteriaBirthDate,
		FSSearchCriteriaBirthPlace,
		FSSearchCriteriaDeathDate,
		FSSearchCriteriaDeathPlace,
		FSSearchCriteriaMarriageDate,
		FSSearchCriteriaMarriagePlace
	];
}

@end










@implementation FSSearchResults

- (id)init
{
    self = [super init];
    if (self) {
		_backingStore	= [NSMutableArray array];
        _currentIndex	= 0;
		_contextID		= nil;
    }
    return self;
}

- (MTPocketResponse *)next
{
	NSMutableArray *params = [NSMutableArray array];
	[params addObject:[NSString stringWithFormat:@"maxResults=%u", _batchSize]];
	[params addObject:[NSString stringWithFormat:@"startIndex=%u", _currentIndex]];
	
	if (_contextID) {
		[params addObject:[NSString stringWithFormat:@"contextId=%@", _contextID]];
	}
	else {
		for (NSDictionary *criteriaDictionary in _criteria) {
			NSString	*criteriaKey	= criteriaDictionary[@"Criteria"];
			id			value			= criteriaDictionary[@"Value"];

			NSString *formattedValue = (NSString *)value;
			if ([value isKindOfClass:[NSDate class]]) {
				formattedValue = [(NSDate *)value stringFromDateWithFormat:DATE_FORMAT];
			}
			[params addObject:[NSString stringWithFormat:@"%@=%@", criteriaKey, formattedValue]];
		}
	}

	NSURL *url = [FSURL urlWithModule:@"familytree"
                              version:2
                             resource:@"search"
                          identifiers:nil
                               params:0
                                 misc:[params componentsJoinedByString:@"&"]];

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;


	if (response.success) {
		
		[self removeAllObjects];
		
		NSDictionary *search = NILL([response.body valueForComplexKeyPath:@"searches[first]"]);
		_contextID			= search[@"contextId"];
		_numberOfResults	= [search[@"partial"] integerValue];
		
		NSArray *searches = NILL([search valueForKeyPath:@"search"]);
		for (NSDictionary *searchDictionary in searches) {
			NSDictionary *personDictionary = searchDictionary[@"person"];
			FSPerson *person = [FSPerson personWithIdentifier:personDictionary[@"id"]];
			[person populateFromPersonDictionary:personDictionary];

			// Add parents
			NSArray *parents = personDictionary[@"parent"];
			for (NSDictionary *parentDictionary in parents) {
				FSPerson *parent = [FSPerson personWithIdentifier:parentDictionary[@"id"]];
				[parent populateFromPersonDictionary:parentDictionary];
				[person addParent:parent withLineage:FSLineageTypeBiological];
			}

			// Add children
			NSArray *children = personDictionary[@"child"];
			for (NSDictionary *childDictionary in children) {
				FSPerson *child = [FSPerson personWithIdentifier:childDictionary[@"id"]];
				[child populateFromPersonDictionary:childDictionary];
				[person addChild:child withLineage:FSLineageTypeBiological];
			}

			// Add spouses
			NSArray *spouses = personDictionary[@"spouse"];
			for (NSDictionary *spouseDictionary in spouses) {
				FSPerson *spouse = [FSPerson personWithIdentifier:spouseDictionary[@"id"]];
				[spouse populateFromPersonDictionary:spouseDictionary];
				[person addMarriage:[FSMarriage marriageWithHusband:(spouse.isMale ? spouse : person) wife:(spouse.isMale ? person : spouse)]];
			}

			[self addObject:person];
		}
	}
	
	_currentIndex += _batchSize;
	return response;
}




#pragma mark NSArray

-(NSUInteger)count
{
    return [_backingStore count];
}

-(id)objectAtIndex:(NSUInteger)index
{
    return _backingStore[index];
}

#pragma mark NSMutableArray

-(void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [_backingStore insertObject:anObject atIndex:index];
}

-(void)removeObjectAtIndex:(NSUInteger)index
{
    [_backingStore removeObjectAtIndex:index];
}

-(void)addObject:(id)anObject
{
    [_backingStore addObject:anObject];
}

-(void)removeLastObject
{
    [_backingStore removeLastObject];
}

-(void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    _backingStore[index] = anObject;
}


@end