//
//  FSUser.h
//  FSUser
//
//  Created by Adam Kirk on 8/2/12.
//  Copyright (c) 2012 FamilySearch.org. All rights reserved.
//

@class MTPocketResponse, FSPerson;


extern NSString *const FSUserInfoIDKey;
extern NSString *const FSUserInfoMembershipIDKey;
extern NSString *const FSUserInfoStakeKey;
extern NSString *const FSUserInfoTempleDistrictKey;
extern NSString *const FSUserInfoWardKey;
extern NSString *const FSUserInfoNameKey;
extern NSString *const FSUserInfoUsernameKey;

// @YES or @NO
extern NSString *const FSUserPermissionAccess;
extern NSString *const FSUserPermissionView;
extern NSString *const FSUserPermissionModify;
extern NSString *const FSUserPermissionViewLDSInformation;
extern NSString *const FSUserPermissionModifyLDSInformation;
extern NSString *const FSUserPermissionAccessLDSInterface;
extern NSString *const FSUserPermissionAccessDiscussionForums;




@interface FSUser : NSObject

@property (strong, nonatomic) NSString      *username;
@property (strong, nonatomic) NSDictionary  *info;
@property (strong, nonatomic) NSDictionary  *permissions;
@property (readonly, getter=isLoggedIn) BOOL loggedIn;

- (id)initWithUsername:(NSString *)username password:(NSString *)password developerKey:(NSString *)devKey;
- (MTPocketResponse *)login;
+ (FSUser *)currentUser;            // You have to log in first before this is not nil.
- (MTPocketResponse *)fetch;
- (FSPerson *)treePerson;
- (MTPocketResponse *)logout;

@end
