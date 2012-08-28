//
//  FSURL.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/28/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSURL.h"

@implementation FSURL

static BOOL __sandboxed = YES;

+ (void)setSandboxed:(BOOL)sandboxed
{
	__sandboxed = sandboxed;
}

+ (NSURL *)authURL
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.familysearch.org/identity/v2/",	(__sandboxed ? @"sandbox" : @"api")]];
}

+ (NSURL *)treeURL
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.familysearch.org/familytree/v2/",	(__sandboxed ? @"sandbox" : @"api")]];
}

@end
