//
//  FMLoginViewController.h
//  FamilySearchMobile
//
//  Created by Adam Kirk on 8/30/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FMLoginViewController : UIViewController
@property (strong, nonatomic) void (^completionBlock)(NSString *sessionID);
@end
