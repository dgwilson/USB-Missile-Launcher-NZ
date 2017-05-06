//
//  MissileControlView.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 1/05/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MissileControlView.h"


@implementation MissileControlView

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect 
{
    // Drawing code here.

//	NSImage * backgroundImage = nil;

//	NSString *myImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"wires" ofType:@"gif"];
	/*
	NSString *myImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Nevigate" ofType:@"png"];
	if (myImagePath) 
	{
		backgroundImage = [[[NSImage alloc] initByReferencingFile:myImagePath] autorelease];
		
//		[backgroundImage setScalesWhenResized: YES];
//		[backgroundImage setSize: rect.size];
//		[backgroundImage drawInRect:rect 
//						   fromRect:rect 
//						  operation:NSCompositeSourceOver 
//						   fraction: 0.6];
		[backgroundImage setScalesWhenResized: YES];
		[backgroundImage setSize: [self bounds].size];
		[backgroundImage drawInRect:NSMakeRect(0, 0, [self bounds].size.width, [self bounds].size.height) 
						   fromRect:NSMakeRect(0, 0, backgroundImage.size.width, backgroundImage.size.height)
						  operation:NSCompositeSourceOver 
						   fraction: 0.6];
		
//		[myImage drawInRect:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height) 
//				   fromRect:NSMakeRect(0, 0, [myImage size].width, [myImage size].height) 
//				  operation:NSCompositeSourceOver 
//				   fraction:0.8];
	}
	//[super drawRect:rect];
	 
	 */
}


@end
