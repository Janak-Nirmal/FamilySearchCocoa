//
//  FSOrdinance.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSOrdinance.h"
#import "private.h"

@implementation FSOrdinance

- (id)initWithType:(FSOrdinanceType)type identifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _type		= type;
		_identifier	= identifier;
		
    }
    return self;
}

+ (FSOrdinance *)ordinanceWithType:(FSOrdinanceType)type identifier:(NSString *)identifier
{
	return [[FSOrdinance alloc] initWithType:type identifier:identifier];
}

@end
