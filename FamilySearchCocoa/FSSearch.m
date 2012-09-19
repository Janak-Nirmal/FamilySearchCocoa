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
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) NSMutableArray *criteria;
@end





@interface FSSearchResults ()
- (id)initWithSessionID:(NSString *)sessionID;
@property (strong, nonatomic)	NSMutableArray	*backingStore;
@property (strong, nonatomic)	NSString		*sessionID;
@property (strong, nonatomic)	FSURL			*url;
@property (strong, nonatomic)	NSString		*contextID;
@property (nonatomic)			NSUInteger		currentIndex;
@property (nonatomic)			NSUInteger		batchSize;
@property (nonatomic)			NSMutableArray	*criteria;
@end





@implementation FSSearch

- (id)initWithSessionID:(NSString *)sessionID
{
    self = [super init];
    if (self) {
		_sessionID		= sessionID;
        _criteria		= [NSMutableArray array];
		_batchSize		= 10;
    }
    return self;
}

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

- (FSSearchResults *)results
{
	FSSearchResults *results = [[FSSearchResults alloc] initWithSessionID:_sessionID];
	results.batchSize = _batchSize;
	results.criteria = _criteria;
	return results;
}

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

- (id)initWithSessionID:(NSString *)sessionID
{
    self = [super init];
    if (self) {
		_backingStore	= [NSMutableArray array];
		_sessionID		= sessionID;
        _currentIndex	= 0;
		_url			= [[FSURL alloc] initWithSessionID:_sessionID];
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

	NSURL *url = [_url urlWithModule:@"familytree"
							 version:2
							resource:@"search"
						 identifiers:nil
							  params:0
								misc:[params componentsJoinedByString:@"&"]];

	MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];

	if (response.success) {
		
		[self removeAllObjects];
		
		NSDictionary *search = [response.body valueForComplexKeyPath:@"searches[first]"];
		_contextID		= search[@"contextId"];
		_totalResults	= [search[@"partial"] integerValue];
		
		NSArray *searches = [search valueForComplexKeyPath:@"search"];
		for (NSDictionary *searchDictionary in searches) {
			NSDictionary *personDictionary = searchDictionary[@"person"];
			FSPerson *person = [FSPerson personWithSessionID:_sessionID identifier:personDictionary[@"id"]];
			[person populateFromPersonDictionary:personDictionary];

			// Add parents
			NSArray *parents = personDictionary[@"parent"];
			for (NSDictionary *parentDictionary in parents) {
				FSPerson *parent = [FSPerson personWithSessionID:_sessionID identifier:parentDictionary[@"id"]];
				[parent populateFromPersonDictionary:parentDictionary];
				[person addParent:parent withLineage:FSLineageTypeBiological];
			}

			// Add children
			NSArray *children = personDictionary[@"child"];
			for (NSDictionary *childDictionary in children) {
				FSPerson *child = [FSPerson personWithSessionID:_sessionID identifier:childDictionary[@"id"]];
				[child populateFromPersonDictionary:childDictionary];
				[person addChild:child withLineage:FSLineageTypeBiological];
			}

			// Add spouses
			NSArray *spouses = personDictionary[@"spouse"];
			for (NSDictionary *spouseDictionary in spouses) {
				FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:spouseDictionary[@"id"]];
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