//
//  FSURL.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 8/28/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSURL.h"
#import "private.h"


#define IN_MASK(a, b) ((a & b) == b)
#define ALL_OR_NONE(a, b, c) (IN_MASK(a, b) ? @"all" : (c ? c : @"none"))




FSQueryParameter defaultQueryParameters()
{
	return FSQNames | FSQGenders | FSQEvents | FSQValues | FSQAssertions | FSQIdentifiers;
}

FSQueryParameter familyQueryParameters()
{
	return FSQFamilies | FSQChildren | FSQParents;
}

NSString *queryStringWithParameters(FSQueryParameter parameters)
{
	NSString *string = [NSString stringWithFormat:@"names=%@&genders=%@&events=%@&characteristics=%@&exists=%@&values=%@&ordinances=%@&assertions=%@&families=%@&children=%@&parents=%@&personas=%@&properties=%@&identifiers=%@&dispositions=%@&contributors=%@",
						ALL_OR_NONE(parameters, FSQNames,			nil),
						ALL_OR_NONE(parameters, FSQGenders,			nil),
						ALL_OR_NONE(parameters, FSQEvents,			nil),
						ALL_OR_NONE(parameters, FSQCharacteristics,	nil),
						ALL_OR_NONE(parameters, FSQExists,			nil),
						ALL_OR_NONE(parameters, FSQValues,			@"summary"),
						ALL_OR_NONE(parameters, FSQOrdinances,		nil),
						ALL_OR_NONE(parameters, FSQAssertions,		nil),
						ALL_OR_NONE(parameters, FSQFamilies,		nil),
						ALL_OR_NONE(parameters, FSQChildren,		nil),
						ALL_OR_NONE(parameters, FSQParents,			nil),
						ALL_OR_NONE(parameters, FSQPersonas,		nil),
						ALL_OR_NONE(parameters, FSQProperties,		nil),
						ALL_OR_NONE(parameters, FSQIdentifiers,		nil),
						ALL_OR_NONE(parameters, FSQDispositions,	@"affirming"),
						ALL_OR_NONE(parameters, FSQContributors,	nil)];

	return string;
}








@implementation FSURL


static BOOL __sandboxed = YES;

+ (void)setSandboxed:(BOOL)sandboxed
{
	__sandboxed = sandboxed;
}

static NSString *__sessionID = nil;

+ (void)setSessionID:(NSString *)sessionID
{
    __sessionID = sessionID;
}

+ (NSURL *)urlWithModule:(NSString *)module
				 version:(NSUInteger)version
				resource:(NSString *)resource
			 identifiers:(NSArray *)identifiers
				  params:(FSQueryParameter)params
					misc:(NSString *)misc
{
	if ([identifiers isKindOfClass:[NSString class]]) identifiers = @[ identifiers ];

	NSMutableString *url = [NSMutableString stringWithFormat:@"https://%@.familysearch.org", (__sandboxed ? @"sandbox" : @"api")];
	[url appendFormat:@"/%@", module];
	if (version > 0) [url appendFormat:@"/v%u", version];
	[url appendFormat:@"/%@", resource];
	if (identifiers && identifiers.count > 0) [url appendFormat:@"/%@", [identifiers componentsJoinedByString:@","]];
	[url appendString:@"?"];

	NSMutableArray *paramsArray = [NSMutableArray array];
	if (params)		[paramsArray addObject:queryStringWithParameters(params)];
	if (misc)		[paramsArray addObject:misc];

	if (__sessionID) [paramsArray addObject:[NSString stringWithFormat:@"sessionId=%@", __sessionID]];
	[paramsArray addObject:@"agent=akirk-at-familysearch-dot-org/1.0"];
	[url appendString:[paramsArray componentsJoinedByString:@"&"]];

	return [NSURL URLWithString:url];
}


@end
