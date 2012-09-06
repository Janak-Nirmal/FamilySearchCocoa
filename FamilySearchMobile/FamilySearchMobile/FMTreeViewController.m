//
//  FMViewController.m
//  FamilySearchMobile
//
//  Created by Adam Kirk on 8/27/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FMTreeViewController.h"
#import "constants.h"
#import <QuartzCore/QuartzCore.h>
#import <FSAuth.h>
#import <FSEvent.h>
#import <UIControl+MTControl.h>
#import <NSDate+MTDates.h>
#import "FMBranchView.h"
#import "FMLoginViewController.h"
#import "FMLegendView.h"


#define ALL_CONTROL_STATES UIControlStateNormal | UIControlStateSelected | UIControlStateHighlighted | UIControlStateDisabled

#define BUTTON_HEIGHT		30.0
#define BUTTON_WIDTH		200.0
#define BUTTON_SPACING		50.0
#define GENERATION_SPACING	20.0
#define TOTAL_WIDTH			((BUTTON_WIDTH + GENERATION_SPACING) * GENERATIONS)
#define TOTAL_HEIGHT		(((BUTTON_HEIGHT + BUTTON_SPACING) * pow( 2.0, GENERATIONS - 1 )) - BUTTON_SPACING)
#define INITIAL_ZOOM		0.66
#define SCROLL_INSET		300
#define LABEL_TAG			1122





@interface FMTreeViewController ()
@property (strong, nonatomic) IBOutlet UIScrollView *treeScrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet FMLegendView *legendView;
@property (nonatomic) dispatch_queue_t queue;
@end




@implementation FMTreeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	_queue = dispatch_queue_create("org.familysearch.mobiletest", 0);

	_containerView.frame = CGRectMake(0, 0, TOTAL_WIDTH, TOTAL_HEIGHT);
	_treeScrollView.contentSize = _containerView.frame.size;
	_treeScrollView.contentInset = UIEdgeInsetsMake(SCROLL_INSET, SCROLL_INSET, SCROLL_INSET, SCROLL_INSET);
	_treeScrollView.scrollsToTop = NO;
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
	[_treeScrollView setZoomScale:INITIAL_ZOOM];
	_treeScrollView.contentOffset = CGPointMake(0, -50);

//	if (_centeredPerson) {
//		_legendView.hidden = NO;
//		_legendView.layer.cornerRadius = 6.0;
//		_legendView.rootPerson = _rootPerson;
//		_legendView.centeredPerson = _centeredPerson;
//		_legendView.centeredGeneration = _centeredGeneration;
//	}

	NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:@"LoginUsername"];
	NSString *password = [[NSUserDefaults standardUserDefaults] stringForKey:@"LoginPassword"];

	if ((username && password) && !_sessionID) {
		[_spinner startAnimating];
		dispatch_async(_queue, ^{
			FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:DEV_KEY sandboxed:NO];
			MTPocketResponse *response = [auth sessionIDFromLoginWithUsername:username password:password];

			dispatch_async(dispatch_get_main_queue(), ^{

				if (response.success) {
					[_spinner stopAnimating];
					_sessionID = response.body;
					_rootPerson = _centeredPerson = [FSPerson currentUserWithSessionID:_sessionID];
					_centeredGeneration = 1;
					[_centeredPerson fetch];
					[self loadTree:_centeredPerson];
				}
				else
					[self performSegueWithIdentifier:@"LoginSegue" sender:self];
			});
		});
	}
	else if (_sessionID)
		[self loadTree:_centeredPerson];
	else
		[self performSegueWithIdentifier:@"LoginSegue" sender:self];
}

- (void)viewDidUnload
{
	[self setTreeScrollView:nil];
	[self setSpinner:nil];
	[self setContainerView:nil];
	[self setLegendView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

- (void)loadTree:(FSPerson *)center
{
	[_spinner startAnimating];

	for (UIView *v in _containerView.subviews) {
		[v removeFromSuperview];
	}

	self.navigationItem.title = [NSString stringWithFormat:@"%@'s Family Tree", center.name];

	dispatch_async(_queue, ^{
		MTPocketResponse *response = [center fetchAncestors:GENERATIONS];
		if (response.success) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[_spinner stopAnimating];
				[self animateLeaf: @{ @"Person" : center, @"DecendentButton" : [NSNull null], @"Generation" : @1 } ];
			});
		}
	});
}

- (void)animateLeaf:(NSDictionary *)leaf
{
	// extract leaf info
	FSPerson	*person				= [leaf objectForKey:@"Person"];
	UIButton	*decendentButton	= [leaf objectForKey:@"DecendentButton"];
	NSUInteger	generation			= [[leaf objectForKey:@"Generation"] unsignedIntegerValue];

	if (generation > GENERATIONS) return;

	// create the new leaf
	UIButton *personButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	if ([person.gender isEqualToString:@"Male"])
		[personButton setBackgroundImage:[UIImage imageNamed:@"male_button"] forState:UIControlStateNormal];
	else
		[personButton setBackgroundImage:[UIImage imageNamed:@"female_button"] forState:UIControlStateNormal];

	personButton.clipsToBounds = NO;
	[personButton.layer setCornerRadius:6.0];
	[personButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[personButton.titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
	[personButton setTitle:person.name forState:UIControlStateNormal];
	[_containerView addSubview:personButton];

	[personButton touchDown:^(UIEvent *event) {
		FMTreeViewController *treeViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Tree"];
		treeViewController.rootPerson = _rootPerson;
		treeViewController.centeredPerson = person;
		treeViewController.centeredGeneration = (_centeredGeneration - 1) + generation;
		treeViewController.sessionID = _sessionID;
		[self.navigationController pushViewController:treeViewController animated:YES];
	}];


	// add the branch view
	CGFloat height	= (TOTAL_HEIGHT / pow(2.0, generation + 1.0)) * 2.0;
	CGFloat width	= GENERATION_SPACING + 10.0;
	CGFloat x		= BUTTON_WIDTH - 5.0;
	CGFloat y		= - (height / 2.0) + (BUTTON_HEIGHT / 2.0);

	FMBranchView *branchView = [[FMBranchView alloc] initWithFrame:CGRectMake(round(x), round(y), round(width), round(height))];
	branchView.alpha = 0;
	[personButton addSubview:branchView];

	// add the birth label
	for (FSEvent *event in person.events) {
		if ([event.type isEqualToString:FSPersonEventTypeBirth]) {
			UILabel *birthLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, BUTTON_HEIGHT, BUTTON_WIDTH, BUTTON_HEIGHT / 2.0)];
			birthLabel.opaque			= NO;
			birthLabel.backgroundColor	= [UIColor clearColor];
			birthLabel.font				= [UIFont systemFontOfSize:12];
			birthLabel.text				= [NSString stringWithFormat:@"Born: %@",[event.date stringFromDateWithFormat:@"dd MMM yyyy"]];
			birthLabel.alpha			= 0;
			birthLabel.tag				= LABEL_TAG;
			[personButton addSubview:birthLabel];
		}
	}

	// set the destination geometry of the new leaf
	CGRect frame = CGRectMake(GENERATION_SPACING, (TOTAL_HEIGHT / 2.0) - (BUTTON_HEIGHT / 2.0), BUTTON_WIDTH, BUTTON_HEIGHT);
	if ([decendentButton isKindOfClass:[UIButton class]]) {
		personButton.frame = decendentButton.frame;
		frame.origin.x = decendentButton.frame.origin.x + BUTTON_WIDTH + GENERATION_SPACING;
		CGFloat vSpacing = TOTAL_HEIGHT / pow(2, generation);
		if ([person.gender isEqualToString:@"Male"])
			frame.origin.y = decendentButton.frame.origin.y - vSpacing;
		else
			frame.origin.y = decendentButton.frame.origin.y + vSpacing;
	}
	else {
		personButton.frame = frame;
		for (FSPerson *parent in person.parents)
			[self animateLeaf: @{ @"Person" : parent, @"DecendentButton" : personButton, @"Generation" : @(generation + 1) } ];
		[UIView animateWithDuration:2 animations:^{
			branchView.alpha = 1;
		}];
		return;
	}

	// animate the leaf out. when its done create the next leafs
	// TODO: add easing
	CGFloat animationDuration = (((arc4random() % 10) + 1) / 10.0) * 0.5;
	[UIView animateWithDuration:animationDuration animations:^{
		CGRect step1 = frame;
		step1.origin.y = decendentButton.frame.origin.y;
		personButton.frame = step1;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:animationDuration animations:^{
			personButton.frame = frame;
		} completion:^(BOOL finished) {
			for (FSPerson *parent in person.parents)
				[self animateLeaf: @{ @"Person" : parent, @"DecendentButton" : personButton, @"Generation" : @(generation + 1) } ];
			[UIView animateWithDuration:1 animations:^{
				branchView.alpha = 1;
			}];
		}];
	}];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return _containerView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	CGFloat zoomPercent = MIN(1.0, ((scrollView.zoomScale - 1.0) / 0.2));
	for (UIView *button in _containerView.subviews)
		for (UIView *label in button.subviews)
			if (label.tag == LABEL_TAG) {
				if (scrollView.zoomScale > 1) {
					// && [[(UIButton *)button titleLabel].text isEqualToString:@"Arthur Lyman Bray"]
					// get visible rect
					CGRect visibleRect;
					visibleRect.origin = scrollView.contentOffset;
					visibleRect.size = scrollView.bounds.size;
					float theScale = 1.0 / scrollView.zoomScale;
					visibleRect.origin.x *= theScale;
					visibleRect.origin.y *= theScale;
					visibleRect.size.width *= theScale;
					visibleRect.size.height *= theScale;
					CGPoint viewCenter = CGPointMake(visibleRect.origin.x + ( visibleRect.size.width / 2.0), visibleRect.origin.y + (visibleRect.size.height / 2.0));

					// figure distance from center
					CGPoint buttonCenter = CGPointMake(button.frame.origin.x + ( button.frame.size.width / 2.0), button.frame.origin.y + (button.frame.size.height / 2.0));
					CGFloat deltaX = abs(buttonCenter.x - viewCenter.x);
					CGFloat deltaY = abs(buttonCenter.y - viewCenter.y);
					CGFloat distance = sqrtf( powf(deltaX, 2) + powf(deltaY, 2) );
					distance = distance > 0 ? distance : 0.00001;
					deltaX = visibleRect.size.width / 2.0;
					deltaY = visibleRect.size.height / 2.0;
					CGFloat maxDistance = sqrtf( powf(deltaX, 2) + powf(deltaY, 2) );
					CGFloat distancePercent = MAX(0, 1.0 - ((distance * 2) / maxDistance));
//					NSLog(@"maxDistance: %.2f", maxDistance);
//					NSLog(@"distance: %.2f", distance);

					label.alpha = distancePercent * zoomPercent;
				}
				else
					label.alpha = 0;
			}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[(FMLoginViewController *)segue.destinationViewController setCompletionBlock:^(NSString *sessionID) {
		if (sessionID) {
			_sessionID = sessionID;
			_rootPerson = _centeredPerson = [FSPerson currentUserWithSessionID:_sessionID];
			_centeredGeneration = 1;
			[_centeredPerson fetch];
			[self loadTree:_centeredPerson];
		}
		[self dismissViewControllerAnimated:YES completion:nil];
	}];
}

@end
