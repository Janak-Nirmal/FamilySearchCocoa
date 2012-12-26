//
//  FSUser.m
//  FSUser
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

#import "FSUser.h"
#import "private.h"
#import <NSObject+MTJSONUtils.h>





@interface FSUser ()
@property (strong, nonatomic) NSString *devKey;
@end







@implementation FSUser

- (id)initWithDeveloperKey:(NSString *)devKey
{
    self = [super init];
    if (self) {
        _devKey = devKey;
    }
    return self;
}

static FSPerson *__treePerson = nil;

- (MTPocketResponse *)loginWithUsername:(NSString *)un password:(NSString *)pw
{
    __treePerson = nil;
    [FSURL setSessionID:nil];
	NSURL *url = [FSURL urlWithModule:@"identity"
                              version:2
                             resource:@"login"
                          identifiers:nil
                               params:0
                                 misc:[NSString stringWithFormat:@"key=%@", _devKey]];

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON username:un password:pw body:nil].send;

	if (response.success) {
		NSString *sessionID = NILL([response.body valueForKeyPath:@"session.id"]);
        [FSURL setSessionID:sessionID];
	}

	return response;
}

- (FSPerson *)treePerson
{
    return __treePerson ? __treePerson : [FSPerson personWithIdentifier:@"me"];
}

- (MTPocketResponse *)fetch
{
	NSURL *url = [FSURL urlWithModule:@"identity"
                              version:2
                             resource:@"user"
                          identifiers:nil
                               params:0
                                 misc:nil];

    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;

	if (response.success) {
        NSDictionary *userDict                  = [response.body[@"users"] lastObject];
        NSMutableDictionary *infoDict           = [NSMutableDictionary dictionary];
        infoDict[FSUserInfoIDKey]               = userDict[FSUserInfoIDKey];
        infoDict[FSUserInfoMembershipIDKey]     = [userDict valueForKeyPath:FSUserInfoMembershipIDKey];
        infoDict[FSUserInfoStakeKey]            = [userDict valueForKeyPath:FSUserInfoStakeKey];
        infoDict[FSUserInfoTempleDistrictKey]   = [userDict valueForKeyPath:FSUserInfoTempleDistrictKey];
        infoDict[FSUserInfoWardKey]             = [userDict valueForKeyPath:FSUserInfoWardKey];
        infoDict[FSUserInfoNameKey]             = [userDict valueForComplexKeyPath:FSUserInfoNameKey];
        infoDict[FSUserInfoUsernameKey]         = userDict[FSUserInfoUsernameKey];
        _info                                   = [NSDictionary dictionaryWithDictionary:infoDict];
	}
    else return response;


	url = [FSURL urlWithModule:@"identity"
                       version:2
                      resource:@"permission"
                   identifiers:nil
                        params:0
                          misc:@"product=FamilyTree"];

    response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;

	if (response.success) {
        NSArray *permissions = response.body[@"permissions"];
        NSMutableDictionary *permissionsDict = [NSMutableDictionary dictionary];
        permissionsDict[FSUserPermissionAccess]                 = @NO;
        permissionsDict[FSUserPermissionView]                   = @NO;
        permissionsDict[FSUserPermissionModify]                 = @NO;
        permissionsDict[FSUserPermissionViewLDSInformation]     = @NO;
        permissionsDict[FSUserPermissionModifyLDSInformation]   = @NO;
        permissionsDict[FSUserPermissionAccessLDSInterface]     = @NO;
        permissionsDict[FSUserPermissionAccessDiscussionForums] = @NO;
        for (NSDictionary *permission in permissions) {
            permissionsDict[permission[@"value"]] = @YES;
        }
        _permissions = [NSDictionary dictionaryWithDictionary:permissionsDict];
    }

	return response;
}

- (MTPocketResponse *)logout
{
	NSURL *url = [FSURL urlWithModule:@"identity" version:2 resource:@"logout" identifiers:nil params:0 misc:nil];
    MTPocketResponse *response = [MTPocketRequest requestForURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil].send;
    if (response.success) {
        __treePerson = nil;
        [FSURL setSessionID:nil];
    }
    return response;
}





@end



NSString *const FSUserInfoIDKey                         = @"id";
NSString *const FSUserInfoMembershipIDKey               = @"member.id";
NSString *const FSUserInfoStakeKey                      = @"member.stake";
NSString *const FSUserInfoTempleDistrictKey             = @"member.templeDistrict";
NSString *const FSUserInfoWardKey                       = @"member.ward";
NSString *const FSUserInfoNameKey                       = @"names[first].value";
NSString *const FSUserInfoUsernameKey                   = @"username";

NSString *const FSUserPermissionAccess                  = @"Access";
NSString *const FSUserPermissionView                    = @"View";
NSString *const FSUserPermissionModify                  = @"Modify";
NSString *const FSUserPermissionViewLDSInformation      = @"View LDS Information";
NSString *const FSUserPermissionModifyLDSInformation    = @"Modify LDS Information";
NSString *const FSUserPermissionAccessLDSInterface      = @"Access LDS Interface";
NSString *const FSUserPermissionAccessDiscussionForums  = @"Access Discussion Forums";

