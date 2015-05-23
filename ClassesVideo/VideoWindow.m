//
//  VideoWindow.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 26/04/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VideoWindow.h"


@implementation VideoWindow

- (id)init;
{
	self = [super init];
	if (self) {
		NSLog(@"VideoWindow: init");
	}
	return self;
}

- (void)awakeFromNib 
{
	NSLog(@"VideoWindow:awakeFromNib - time to start work for the day");
}	

- (BOOL)windowShouldClose:(id)sender
{
	return YES;
}

- (BOOL)isReleasedWhenClosed;
{
	return YES;
}

- (void)close;
{
//	[super close];
	[self orderOut:self];
}

@end
