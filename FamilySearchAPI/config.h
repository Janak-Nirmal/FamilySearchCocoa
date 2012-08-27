//
//  Config.h
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/16/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

BOOL __fs_sandboxed = YES;

#define AUTH_URL(sandboxed)	[NSURL URLWithString:[NSString stringWithFormat:@"https://%@.familysearch.org/identity/v2/",	(sandboxed ? @"sandbox" : @"api")]]
#define TREE_URL(sandboxed)	[NSURL URLWithString:[NSString stringWithFormat:@"https://%@.familysearch.org/familytree/v2/",	(sandboxed ? @"sandbox" : @"api")]]
