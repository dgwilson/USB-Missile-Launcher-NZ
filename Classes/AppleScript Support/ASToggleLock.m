//
//  ASToggleLock.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 11/04/07.
//  Copyright 2007 David G. Wilson. All rights reserved.
//

#import "ASToggleLock.h"


@implementation ASToggleLock

//NSScriptCommand override
- (id)performDefaultImplementation;
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"ASToggleLock" object: nil]; //this is your Cocoa call
	return nil;
}

@end
