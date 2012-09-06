//
//  FMBranchView.m
//  FamilySearchMobile
//
//  Created by Adam Kirk on 8/29/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FMBranchView.h"

@implementation FMBranchView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.opaque = NO;
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGContextSetShouldAntialias(context, NO);
	CGContextSetLineWidth(context, 1.0);
	CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);

	CGContextMoveToPoint(	context,	0										, round(self.frame.size.height / 2.0	));
	CGContextAddLineToPoint(context,	round(self.frame.size.width / 2.0	)	, round(self.frame.size.height / 2.0	));
	CGContextAddLineToPoint(context,	round(self.frame.size.width / 2.0	)	, 1);
	CGContextAddLineToPoint(context,	round(self.frame.size.width			)	, 1);
	CGContextMoveToPoint(	context,	round(self.frame.size.width / 2.0	)	, round(self.frame.size.height / 2.0	));
	CGContextAddLineToPoint(context,	round(self.frame.size.width / 2.0	)	, round(self.frame.size.height - 1		));
	CGContextAddLineToPoint(context,	round(self.frame.size.width			)	, round(self.frame.size.height - 1		));

	CGContextStrokePath(context);
}


@end
