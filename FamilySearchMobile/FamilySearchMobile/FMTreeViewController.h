//
//  FMViewController.h
//  FamilySearchMobile
//
//  Created by Adam Kirk on 8/27/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FSPerson.h>

@interface FMTreeViewController : UIViewController <UIScrollViewDelegate>
@property (strong, nonatomic) FSPerson *rootPerson;
@property (strong, nonatomic) FSPerson *centeredPerson;
@property (strong, nonatomic) NSString *sessionID;
@property NSUInteger centeredGeneration;
@end
