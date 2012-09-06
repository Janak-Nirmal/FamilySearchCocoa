//
//  FMLegendView.h
//  FamilySearchMobile
//
//  Created by Adam Kirk on 8/31/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <FSPerson.h>

@interface FMLegendView : UIView
@property (strong, nonatomic) FSPerson *rootPerson;
@property (strong, nonatomic) FSPerson *centeredPerson;
@property NSUInteger centeredGeneration;
@end
