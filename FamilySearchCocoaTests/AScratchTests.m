//
//  AScratchTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 9/7/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "AScratchTests.h"
#import "FSURL.h"
#import "FSAuth.h"
#import "FSPerson.h"
#import "constants.h"
#import <NSDate+MTDates.h>


@interface AScratchTests ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end

@implementation AScratchTests


//- (void)setUp
//{
//	[FSURL setSandboxed:NO];
//
//	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:PRODUCTION_DEV_KEY];
//	[auth loginWithUsername:PRODUCTION_USERNAME password:PRODUCTION_PASSWORD];
//	_sessionID = auth.sessionID;
//
//	_person = [FSPerson currentUserWithSessionID:_sessionID];
//	MTPocketResponse *response = [_person fetch];
//	STAssertTrue(response.success, nil);
//}
//
//- (void)testCurrentUserFetch
//{
//	MTPocketResponse *response = nil;
//
//    response = [_person fetchAncestors:9];
//
//    if (response.success) {
//        FSPerson *parent            = [_person.parents lastObject];
//        FSPerson *grandparent       = [parent.parents lastObject];
//        FSPerson *greatGrandParent  = [grandparent.parents lastObject];
//        FSPerson *ggGrandParent     = [greatGrandParent.parents lastObject];
//        FSPerson *gggGrandParent    = [ggGrandParent.parents lastObject];
//
//        response = [gggGrandParent fetch];
//    }
//}

@end
