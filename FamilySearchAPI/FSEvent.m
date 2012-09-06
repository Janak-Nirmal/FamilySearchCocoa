//
//  FSEvent.m
//  FamilySearchAPI
//
//  Created by Adam Kirk on 8/21/12.
//  Copyright (c) 2012 FamilySearch. All rights reserved.
//

#import "FSEvent.h"
#import "private.h"


NSString *randomStringWithLength(NSInteger length)
{
	unichar string[length];
	for (NSInteger i = 0; i < length; i++) {
		unichar r = (arc4random() % 25) + 65;
		string[i] = r;
	}
	return [[NSString stringWithCharacters:string length:length] lowercaseString];
}


@implementation FSEvent

- (id)initWithType:(FSPersonEventType)type identifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _type				= type;
		_identifier			= identifier;
		_localIdentifier	= randomStringWithLength(5);
		_deleted			= NO;
    }
    return self;
}

+ (FSEvent *)eventWithType:(FSPersonEventType)type identifier:(NSString *)identifier
{
	return [[FSEvent alloc] initWithType:type identifier:identifier];
}

- (BOOL)isEqualToEvent:(FSEvent *)event
{
	if (self == event || [self.type isEqualToString:event.type]) // TODO: this needs to be more precise. (e.g. mutliple Mission events)
		return YES;
	return NO;
}

@end
