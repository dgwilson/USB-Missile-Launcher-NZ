//
//  AboutWindowController.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 15/06/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import "AboutWindowController.h"


@implementation AboutWindowController

@synthesize applicationName;
@synthesize applicationVersion;
@synthesize applicationIcon;
@synthesize applicationText;

- (id) init 
{	
	if ( ! (self = [super initWithWindowNibName: @"AboutWindow"]) ) {
		NSLog(@"init failed in AboutWindowController");
		return nil;
	} // end if
	
	return self;
}

- (void)windowDidLoad 
{
	
	// Application Name
	NSString * name = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	[applicationName setStringValue:name];
	
	// Application Version
	NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	[applicationVersion setStringValue:version];

	// Load and display Credits.rtf
	NSSize contentSize = [applicationText contentSize];
	NSTextView * theTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	
	[theTextView setHorizontallyResizable:YES];
	[theTextView setVerticallyResizable:YES];
	[theTextView setAutoresizingMask:(NSViewMaxXMargin | NSViewMinXMargin | NSViewMaxYMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable)];
		
	NSData *theRTFData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"]];
	[theTextView replaceCharactersInRange:NSMakeRange(0, [[theTextView string] length]) withRTF:theRTFData];
	[applicationText setDocumentView:theTextView];
	
	// Load and display Application Icon
	[applicationIcon setImage:[NSImage imageNamed:@"NSApplicationIcon"]];

}

@end
