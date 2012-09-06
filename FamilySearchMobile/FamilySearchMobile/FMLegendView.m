//
//  FMLegendView.m
//  FamilySearchMobile
//
//  Created by Adam Kirk on 8/31/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FMLegendView.h"
#import "constants.h"


@interface FMLegendView ()
@property NSUInteger	totalGenerations;
@property CGFloat		generationWidth;
@property CGRect		innerRect;
@property CGContextRef	context;
@property dispatch_queue_t animationQueue;
@end




@implementation FMLegendView

- (void)awakeFromNib
{
	_animationQueue = dispatch_queue_create("org.familysearch.animation", 0);
}

- (void)drawRect:(CGRect)rect
{
	if (!_rootPerson || !_centeredPerson) return;

	_innerRect			= CGRectInset(rect, 20, 20);
	_totalGenerations	= (_centeredGeneration - 1) + GENERATIONS;
	_generationWidth	= _innerRect.size.width / _totalGenerations;

	_context = UIGraphicsGetCurrentContext();
	CGContextSetShouldAntialias(_context, NO);
	CGContextSetLineWidth(_context, 1.0);
	CGContextSetStrokeColorWithColor(_context, [UIColor blackColor].CGColor);
	CGPoint rootPoint = CGPointMake(_innerRect.origin.x, _innerRect.origin.y + _innerRect.size.height / 2.0);
	CGContextMoveToPoint(_context,	rootPoint.x, rootPoint.y);

	[self drawPerson:_rootPerson generation:1 point:rootPoint onScreen:NO];
}

- (void)drawPerson:(FSPerson *)person generation:(NSUInteger)generation point:(CGPoint)point onScreen:(BOOL)onScreen
{
	if (onScreen)
		CGContextSetStrokeColorWithColor(_context, [UIColor redColor].CGColor);
	else
		CGContextSetStrokeColorWithColor(_context, [UIColor blackColor].CGColor);

	dispatch_async(_animationQueue, ^{

		for (NSInteger i = 1; i <= 10; i++) {
			CGFloat percent = i / 10.0;
			dispatch_async(dispatch_get_main_queue(), ^{
				CGContextMoveToPoint(		_context,	point.x,								point.y );
				CGContextAddLineToPoint(	_context,	point.x + (_generationWidth * percent),	point.y	);
				CGContextStrokePath(		_context);
			});
			[NSThread sleepForTimeInterval:0.05];
		}

	   CGFloat	spacing	= _innerRect.size.height / pow(2.0, generation);
	   for (FSPerson *parent in person.parents) {

		   CGPoint parentPoint;
		   if ([parent.gender isEqualToString:@"Male"])
			   parentPoint = CGPointMake(point.x + _generationWidth, point.y - (spacing / 2.0) );
		   else
			   parentPoint = CGPointMake(point.x + _generationWidth, point.y + (spacing / 2.0) );

		   for (NSInteger i = 1; i <= 10; i++) {
			   CGFloat percent = i / 10.0;
			   dispatch_async(dispatch_get_main_queue(), ^{
				   CGContextMoveToPoint(	_context,	parentPoint.x,	point.y					);
				   CGContextAddLineToPoint(	_context,	parentPoint.x,	parentPoint.y * percent	);
				   CGContextStrokePath(		_context);
			   });
			   [NSThread sleepForTimeInterval:0.05];
		   }

		   dispatch_async(dispatch_get_main_queue(), ^{
			   [self drawPerson:parent generation:generation + 1 point:parentPoint onScreen:(onScreen || person == _centeredPerson) ];
		   });
	   }

	});
}

@end
