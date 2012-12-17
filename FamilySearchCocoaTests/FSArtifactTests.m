//
//  FSArtifactTests.m
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 11/5/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSArtifactTests.h"
#import "FSPerson.h"
#import "FSArtifact.h"
#import "constants.h"
#import "FSUser.h"
#import "FSURL.h"
#import <MF_Base64Additions.h>


@interface FSArtifactTests ()
@property (strong, nonatomic) NSString  *sessionID;
@property (strong, nonatomic) FSPerson  *person;
@end


@implementation FSArtifactTests


- (void)setUp
{
	[FSURL setSandboxed:NO];

    FSUser *user = [[FSUser alloc] initWithDeveloperKey:PRODUCTION_DEV_KEY];
	[user loginWithUsername:PRODUCTION_USERNAME password:PRODUCTION_PASSWORD];
    _sessionID = user.sessionID;

	_person = [FSPerson personWithSessionID:_sessionID identifier:PRODUCTION_PERSON_ID];
}

- (void)testArtifacts
{
	MTPocketResponse *response = nil;

	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *imagePath = [bundle pathForResource:@"arthur-young" ofType:@"jpg"];

    // upload
	FSArtifact *artifact = [FSArtifact artifactWithData:[NSData dataWithContentsOfFile:imagePath] MIMEType:FSArtifactMIMETypeImagePNG sessionID:_sessionID];
    artifact.title = @"test";
    artifact.description = @"testdescription";
    artifact.originalFilename = @"unit_test.jpg";
	response = [artifact save];
	STAssertTrue(response.success, nil);
    STAssertNotNil(artifact.category, nil);
    STAssertNotNil(artifact.identifier, nil);
    STAssertNotNil(artifact.MIMEType, nil);
    STAssertNotNil(artifact.screeningStatus, nil);
    STAssertNotNil(artifact.status, nil);
    STAssertNotNil(artifact.thumbnails[FSArtifactThumbnailStyleNormalKey], nil);
    STAssertNotNil(artifact.thumbnails[FSArtifactThumbnailStyleIconKey], nil);
    STAssertNotNil(artifact.thumbnails[FSArtifactThumbnailStyleSquareKey], nil);
    STAssertTrue([artifact.title isEqualToString:@"test"], nil);
    STAssertTrue([artifact.description isEqualToString:@"testdescription"], nil);


    // fetch
    FSArtifact *fetchedArtifact = [FSArtifact artifactWithIdentifier:artifact.identifier sessionID:_sessionID];
    response = [fetchedArtifact fetch];
    STAssertTrue(response.success, nil);
    STAssertNotNil(fetchedArtifact.category, nil);
    STAssertNotNil(fetchedArtifact.identifier, nil);
    STAssertNotNil(fetchedArtifact.MIMEType, nil);
    STAssertNotNil(fetchedArtifact.screeningStatus, nil);
    STAssertNotNil(fetchedArtifact.status, nil);
    STAssertNotNil(fetchedArtifact.thumbnails[FSArtifactThumbnailStyleNormalKey], nil);
    STAssertNotNil(fetchedArtifact.thumbnails[FSArtifactThumbnailStyleIconKey], nil);
    STAssertNotNil(fetchedArtifact.thumbnails[FSArtifactThumbnailStyleSquareKey], nil);
    STAssertNotNil(fetchedArtifact.title, nil);

    // update
    NSString *testTitle = @"Adam Kirk";
    artifact.title = testTitle;
    NSString *testDesc = @"This is a picture of my great grandfather";
    artifact.description = testDesc;
    response = [artifact save];
    STAssertTrue(response.success, nil);
    fetchedArtifact = [FSArtifact artifactWithIdentifier:artifact.identifier sessionID:_sessionID];
    response = [fetchedArtifact fetch];
    STAssertTrue(response.success, nil);
    STAssertTrue([fetchedArtifact.title isEqualToString:testTitle], nil);
    STAssertTrue([fetchedArtifact.description isEqualToString:testDesc], nil);

    // delete
    response = [artifact destroy];
    STAssertTrue(response.success, nil);
}

- (void)testTagging
{
	MTPocketResponse *response = nil;

	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *imagePath = [bundle pathForResource:@"arthur-young" ofType:@"jpg"];

    // create artifact
	FSArtifact *artifact = [FSArtifact artifactWithData:[NSData dataWithContentsOfFile:imagePath] MIMEType:FSArtifactMIMETypeImagePNG sessionID:_sessionID];
    artifact.originalFilename = @"unit_test.jpg";

    // add tag
    FSArtifactTag *tag = [FSArtifactTag tagWithPerson:_person title:@"Don Kirk" rect:CGRectMake(0, 0, 60, 88)];
    [artifact addTag:tag];
	response = [artifact save];
	STAssertTrue(response.success, nil);
    STAssertNotNil(tag.identifier, nil);

    // fetch artifacts tagged for person
    NSArray *artifacts = [FSArtifact artifactsForPerson:_person category:nil response:&response];
    STAssertTrue(response.success, nil);
    STAssertTrue(artifacts.count > 0, nil);

    // remove tag
    [artifact removeTag:tag];
    response = [artifact save];
    STAssertTrue(response.success, nil);

    // delete artifact (clean up, so the server doesn't get cluttered)
    response = [artifact destroy];
    STAssertTrue(response.success, nil);
}

- (void)testPortraitArtifacts
{
    MTPocketResponse *response = nil;

   	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *imagePath = [bundle pathForResource:@"arthur-young" ofType:@"jpg"];

    // create artifact
	FSArtifact *artifact = [FSArtifact artifactWithData:[NSData dataWithContentsOfFile:imagePath] MIMEType:FSArtifactMIMETypeImagePNG sessionID:_sessionID];

    // add tag
    FSArtifactTag *tag = [FSArtifactTag tagWithPerson:_person title:@"Don Kirk" rect:CGRectMake(0, 0, 1, 1)];
    [artifact addTag:tag];
	response = [artifact save];
	STAssertTrue(response.success, nil);
    STAssertNotNil(tag.identifier, nil);

    // set tag as portrait
    FSArtifact *portraitArtifact = [tag artifactFromSavingTagAsPortraitWithResponse:&response];
    STAssertTrue(response.success, nil);
    STAssertNotNil(portraitArtifact, nil);

    // give the server time to process the image
    [NSThread sleepForTimeInterval:10];
    
    // get portrait for person
    FSArtifact *portrait = [FSArtifact portraitArtifactForPerson:_person response:&response];
    STAssertTrue(response.success, nil);
    STAssertNotNil(portrait, nil);
}

- (void)testFetchUsersArtifacts
{
    MTPocketResponse *response = nil;

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *imagePath = [bundle pathForResource:@"arthur-young" ofType:@"jpg"];

    // create artifact
	FSArtifact *artifact = [FSArtifact artifactWithData:[NSData dataWithContentsOfFile:imagePath] MIMEType:FSArtifactMIMETypeImagePNG sessionID:_sessionID];
    artifact.originalFilename = @"unit_test.jpg";

    // add tag
    FSArtifactTag *tag = [FSArtifactTag tagWithPerson:_person title:@"Don Kirk" rect:CGRectMake(0, 0, 60, 88)];
    [artifact addTag:tag];
	response = [artifact save];
	STAssertTrue(response.success, nil);
    STAssertNotNil(tag.identifier, nil);

    NSArray *artifacts = [FSArtifact artifactsUploadedByCurrentUserWithSessionID:_sessionID response:&response];
    STAssertTrue(response.success, nil);
    STAssertTrue(artifacts.count > 0, nil);
}

//- (void)test
//{
//    NSURL *url = [NSURL URLWithString:@"https://api.familysearch.org/artifactmanager/users/unknown/taggedPersons?maxRecords=50&sessionId=USYS2AEBA31662BF5B6AF91E0D53F89907DB_ses002.app.prod.id.fsglobal.net&agent=akirk-at-familysearch-dot-org/1.0"];
//    MTPocketResponse *response = [MTPocketRequest objectAtURL:url method:MTPocketMethodGET format:MTPocketFormatJSON body:nil];
//    if (response.success) {
//        for (NSDictionary *taggedPerson in response.body[@"taggedPerson"]) {
//            NSString *identifier = taggedPerson[@"id"];
//            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.familysearch.org/artifactmanager/persons/%@?sessionId=USYS2AEBA31662BF5B6AF91E0D53F89907DB_ses002.app.prod.id.fsglobal.net&agent=akirk-at-familysearch-dot-org/1.0", identifier ]];
//            response = [MTPocketRequest objectAtURL:url method:MTPocketMethodDELETE format:MTPocketFormatJSON body:nil];
//        }
//    }
//}


@end
