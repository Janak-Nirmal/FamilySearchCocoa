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
#import "FSAuth.h"
#import "FSURL.h"
#import <MF_Base64Additions.h>


@interface FSArtifactTests ()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) FSPerson *person;
@end


@implementation FSArtifactTests


- (void)setUp
{
	[FSURL setSandboxed:NO];

	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:PRODUCTION_DEV_KEY];
	[auth loginWithUsername:PRODUCTION_USERNAME password:PRODUCTION_PASSWORD];
	_sessionID = auth.sessionID;

	_person = [FSPerson personWithSessionID:_sessionID identifier:PRODUCTION_PERSON_ID]; 
}

- (void)testArtifacts
{
	MTPocketResponse *response = nil;

	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *imagePath = [bundle pathForResource:@"arthur-young" ofType:@"png"];

    // upload
	FSArtifact *artifact = [FSArtifact artifactWithData:[NSData dataWithContentsOfFile:imagePath] MIMEType:FSArtifactMIMETypeImagePNG sessionID:_sessionID];
	response = [artifact save];
	STAssertTrue(response.success, nil);
    STAssertNotNil(artifact.category, nil);
    STAssertNotNil(artifact.description, nil);
    STAssertNotNil(artifact.identifier, nil);
    STAssertNotNil(artifact.MIMEType, nil);
    STAssertNotNil(artifact.screeningStatus, nil);
    STAssertNotNil(artifact.status, nil);
    STAssertNotNil(artifact.thumbnails[FSArtifactThumbnailStyleNormalKey], nil);
    STAssertNotNil(artifact.thumbnails[FSArtifactThumbnailStyleIconKey], nil);
    STAssertNotNil(artifact.thumbnails[FSArtifactThumbnailStyleSquareKey], nil);
    STAssertNotNil(artifact.title, nil);

    // fetch
    FSArtifact *fetchedArtifact = [FSArtifact artifactWithIdentifier:artifact.identifier sessionID:_sessionID];
    response = [fetchedArtifact fetch];
    STAssertTrue(response.success, nil);
    STAssertNotNil(fetchedArtifact.category, nil);
    STAssertNotNil(fetchedArtifact.description, nil);
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
	NSString *imagePath = [bundle pathForResource:@"arthur-young" ofType:@"png"];

    // create artifact
	FSArtifact *artifact = [FSArtifact artifactWithData:[NSData dataWithContentsOfFile:imagePath] MIMEType:FSArtifactMIMETypeImagePNG sessionID:_sessionID];

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

//- (void)testPortraitArtifacts
//{
//    MTPocketResponse *response = nil;
//
//   	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
//	NSString *imagePath = [bundle pathForResource:@"arthur-young" ofType:@"png"];
//
//    // create artifact
//	FSArtifact *artifact = [FSArtifact artifactWithData:[NSData dataWithContentsOfFile:imagePath] MIMEType:FSArtifactMIMETypeImagePNG sessionID:_sessionID];
//
//    // add tag
//    FSArtifactTag *tag = [FSArtifactTag tagWithPerson:_person title:@"Don Kirk" rect:CGRectMake(0, 0, 60, 88)];
//    [artifact addTag:tag];
//	response = [artifact save];
//	STAssertTrue(response.success, nil);
//    STAssertNotNil(tag.identifier, nil);
//
//    // set tag as portrait
//    response = [tag saveAsPortraitOfPerson];
//    STAssertTrue(response.success, nil);
//
//    // get portrait for person
//    FSArtifact *portrait = [FSArtifact portraitArtifactForPerson:_person response:&response];
//    STAssertTrue(response.success, nil);
//    STAssertNotNil(portrait, nil);
//}


@end
