//
//  FMLoginViewController.m
//  FamilySearchMobile
//
//  Created by Adam Kirk on 8/30/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FMLoginViewController.h"
#import <FSAuth.h>
#import "constants.h"


@interface FMLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end



@implementation FMLoginViewController

- (IBAction)loginButtonTapped:(id)sender
{	
	NSString *username = _usernameTextField.text;
	NSString *password = _passwordTextField.text;
	if (!username || [username isEqualToString:@""]) {
		_errorLabel.text = @"You must enter a username";
		return;
	}
	if (!password || [password isEqualToString:@""]) {
		_errorLabel.text = @"You must enter a password";
		return;
	}

	[_spinner startAnimating];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:DEV_KEY sandboxed:SANDBOXED];
		MTPocketResponse *response = [auth sessionIDFromLoginWithUsername:username password:password];

		dispatch_async(dispatch_get_main_queue(), ^{
			[_spinner stopAnimating];

			if (response.success) {

				if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LoginKeepMeLoggedIn"]) {
					[[NSUserDefaults standardUserDefaults] setObject:username forKey:@"LoginUsername"];
					[[NSUserDefaults standardUserDefaults] setObject:password forKey:@"LoginPassword"];
				}

				_completionBlock(response.body);
			}
			else {
				_errorLabel.text = @"Could not log in";
			}
		});
	});
}

- (IBAction)keepMeLoggedInChanged:(id)sender {
	if ([(UISwitch *)sender isOn]) {
		[[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"LoginKeepMeLoggedIn"];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:@NO forKey:@"LoginKeepMeLoggedIn"];
	}
}

- (IBAction)cancelTouched:(id)sender {
	_completionBlock(nil);
}

- (void)viewDidUnload {
	[self setUsernameTextField:nil];
	[self setPasswordTextField:nil];
	[self setSpinner:nil];
	[self setErrorLabel:nil];
	[super viewDidUnload];
}

@end
