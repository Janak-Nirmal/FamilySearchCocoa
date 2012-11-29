//
//  FSArtifact.h
//  FamilySearchCocoa
//
//  Created by Adam Kirk on 11/5/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//


/*
 This service is new and under developemnt, so do not use this API yet.
*/



#import <MTPocket.h>

@class FSPerson, FSArtifact;



typedef NSString * FSArtifactMIMEType;
#define FSArtifactMIMETypeImagePNG          @"image/png"
#define	FSArtifactMIMETypeImageJPEG         @"image/jpeg"
#define FSArtifactMIMETypeImageTIFF         @"image/tiff"
#define FSArtifactMIMETypeImageGIF          @"image/gif"
#define FSArtifactMIMETypeTextPlain         @"text/plain"
#define FSArtifactMIMETypeTextXML           @"text/xml"
#define FSArtifactMIMETypeTextHTML          @"text/html"
#define FSArtifactMIMETypeVideoMPEG         @"video/mpeg"
#define FSArtifactMIMETypeAudioMPEG         @"audio/mpeg"


typedef NSString * FSArtifactCategory;
#define FSArtifactCategoryUnknown           @"UNKNOWN"
#define FSArtifactCategoryAudio             @"AUDIO"
#define FSArtifactCategoryDocument          @"DOCUMENT"
#define FSArtifactCategoryImage             @"IMAGE"
#define FSArtifactCategoryVideo             @"VIDEO"
#define FSArtifactCategoryStory             @"STORY"
#define FSArtifactCategoryAny               @"ANY"


extern NSString *const FSArtifactThumbnailStyleNormalKey;
extern NSString *const FSArtifactThumbnailStyleIconKey;
extern NSString *const FSArtifactThumbnailStyleSquareKey;





@interface FSArtifactTag : NSObject
@property (readonly, nonatomic) NSString    *identifier;
@property (readonly, nonatomic) FSPerson	*person;
@property (readonly, nonatomic)	NSString	*title;
@property (readonly, nonatomic) CGRect		rect;       // These are percentage values not pixels
+ (FSArtifactTag *)tagWithPerson:(FSPerson *)person title:(NSString *)title rect:(CGRect)rect;
- (MTPocketResponse *)saveAsPortraitOfPerson;
@end




@interface FSArtifact : NSObject

@property (readonly, nonatomic) NSString			*identifier;
@property (readonly, nonatomic) NSData              *data;
@property (readonly, nonatomic) NSString			*MIMEType;
@property (strong,	 nonatomic) NSString			*title;
@property (readonly, nonatomic) NSString			*status;
@property (readonly, nonatomic) NSString            *screeningStatus;
@property (strong,	 nonatomic) NSString			*description;
@property (strong,	 nonatomic) FSArtifactCategory	category;
@property (readonly, nonatomic) NSDictionary        *thumbnails;
@property (readonly, nonatomic) CGSize				size;


#pragma mark - Creating Artifacts
+ (FSArtifact *)artifactWithData:(NSData *)data MIMEType:(FSArtifactMIMEType)MIMEType sessionID:(NSString *)sessionID;              // For creating and uploading a new artifact
+ (FSArtifact *)artifactWithIdentifier:(NSString *)identifier sessionID:(NSString *)sessiongID;                                     // For fetching an existing artifact
+ (NSArray *)artifactsForPerson:(FSPerson *)person category:(FSArtifactCategory)category response:(MTPocketResponse **)response;    // This will block, do not call on main thread.
+ (FSArtifact *)portraitArtifactForPerson:(FSPerson *)person response:(MTPocketResponse **)response;                                // This will block, do not call on main thread.

#pragma mark - Syncing
- (MTPocketResponse *)save;
- (MTPocketResponse *)fetch;
- (MTPocketResponse *)destroy;

#pragma mark - Tagging
- (NSArray *)tags;
- (void)addTag:(FSArtifactTag *)tag;
- (void)removeTag:(FSArtifactTag *)tag;

@end


