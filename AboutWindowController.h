//
//  AboutWindowController.h
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 15/06/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AboutWindowController : NSWindowController

{
	NSTextField * applicationName;
	NSTextField * applicationVersion;
	NSImageView * applicationIcon;
	NSScrollView * applicationText;
}

@property (nonatomic, retain) IBOutlet NSTextField * applicationName;
@property (nonatomic, retain) IBOutlet NSTextField * applicationVersion;
@property (nonatomic, retain) IBOutlet NSImageView * applicationIcon;
@property (nonatomic, retain) IBOutlet NSScrollView * applicationText;



@end
