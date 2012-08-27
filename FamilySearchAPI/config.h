//
//  Config.h
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/16/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#if defined(DEBUG)
	#define SANDBOXED	YES
#elif defined(TEST)
	#define SANDBOXED	YES
#else
	#define SANDBOXED	YES // change this to NO when you're ready to release your app.
#endif

#define AUTH_URL	[NSURL URLWithString:[NSString stringWithFormat:@"https://%@.familysearch.org/identity/v2/",	(SANDBOXED ? @"sandbox" : @"api")]]
#define TREE_URL	[NSURL URLWithString:[NSString stringWithFormat:@"https://%@.familysearch.org/familytree/v2/",	(SANDBOXED ? @"sandbox" : @"api")]]
