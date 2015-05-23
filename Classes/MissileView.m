//
//  MissileController.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 11/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MissileView.h"

@implementation MissileView

- (void)awakeFromNib 
{
	USBLauncher = [[USBMissileControl alloc] init];
	NSLog(@"Missile Control Initialised");
	
	if ([[self window] firstResponder] == self) { 
		NSLog(@"We have FirstResponder status");
	}
}

- (BOOL)acceptsFirstResponder
{
	NSLog(@"acceptsFirstResponder");
	return YES;
}

- (BOOL)canBecomeKeyWindow
{
	NSLog(@"canBecomeKeyWindow");
	return YES;
}

- (BOOL)becomeFirstResponder
{
	NSLog(@"becomeFirstResponder");
	return YES;
}

- (BOOL)needsPanelToBecomeKey
{
	NSLog(@"needsPanelToBecomeKey");
    return YES;
}


- (IBAction)btn_upLeft:(id)sender;
{
	[USBLauncher controlLauncher:launcherLeftUp];
}
- (IBAction)btn_up:(id)sender;
{
	[USBLauncher controlLauncher:launcherUp];
}
- (IBAction)btn_upRight:(id)sender;
{
	[USBLauncher controlLauncher:launcherRightUp];
}
- (IBAction)btn_left:(id)sender;
{
	[USBLauncher controlLauncher:launcherLeft];
}
- (IBAction)btn_fire:(id)sender;
{
	[USBLauncher controlLauncher:launcherFire];
}
- (IBAction)btn_right:(id)sender;
{
	[USBLauncher controlLauncher:launcherRight];
}
- (IBAction)btn_downLeft:(id)sender;
{
	[USBLauncher controlLauncher:launcherLeftDown];
}
- (IBAction)btn_down:(id)sender;
{
	[USBLauncher controlLauncher:launcherDown];
}
- (IBAction)btn_downRight:(id)sender;
{
	[USBLauncher controlLauncher:launcherRightDown];
}
- (IBAction)btn_safety:(id)sender;
{
}

- (void)mouseUp:(NSEvent *)theEvent;
{
	NSLog(@"Mouse is UP!");
    [USBLauncher controlLauncher:launcherStop];
}

- (void)mouseDown:(NSEvent *)theEvent;
{
	NSLog(@"Mouse is Down! - don't care - do nothing");
}


- (void)keyDown:(NSEvent *)event;
{
    BOOL handled = NO;
    NSString * characters;
	unichar key;
    // get the pressed key
    //characters = [event charactersIgnoringModifiers];
	characters = [event characters];
	key = [characters characterAtIndex:0];
	
	//NSLog(@"Key pressed %u", key);
    	
	switch (key) {
		case    49: //left numeric keypad 1
			handled = YES;
			[USBLauncher controlLauncher:launcherLeftDown];
			break;
		case 63233: //down arrow
		case    50: //left numeric keypad 2
			handled = YES;
			[USBLauncher controlLauncher:launcherDown];
			break;
		case    51: //left numeric keypad 3
			handled = YES;
			[USBLauncher controlLauncher:launcherRightDown];
			break;
		case 63234: //left arrow
		case    52: //left numeric keypad 4
			handled = YES;
			[USBLauncher controlLauncher:launcherLeft];
			break;
		case    53: //left numeric keypad 5
			handled = YES;
			[USBLauncher controlLauncher:launcherFire];
			break;
		case 63235: //Right arrow
		case    54: //Right numeric keypad 6
			handled = YES;
			[USBLauncher controlLauncher:launcherRight];
			break;
		case    55: //left numeric keypad 7
			handled = YES;
			[USBLauncher controlLauncher:launcherLeftUp];
			break;
		case 63232: //down up
		case    56: //left numeric keypad 8
			handled = YES;
			[USBLauncher controlLauncher:launcherUp];
			break;
		case    57: //left numeric keypad 9
			handled = YES;
			[USBLauncher controlLauncher:launcherRightUp];
			break;
	}
	
    if (!handled)
        [super keyDown:event];
	
}

- (void)keyUp:(NSEvent *)event;
{
//	NSLog(@"Key Up");
    [USBLauncher controlLauncher:launcherStop];
}

/*
-(void)keyDown:(NSEvent *)theEvent
{
//	unichar ESC = 0x1b;
	NSString* chars = [theEvent characters];
	unichar KEY = [chars characterAtIndex:0];
	
	switch (KEY)
	{
		case ((unichar)0x1b): // ESC
			break;
		case ((unichar)'h'):
			[self flipHorizontal];
			break;
		case ((unichar)'x'):
		{
		}
			break;
		case ((unichar)'y'):
		{
		}
			break;
		case ((unichar)'r'):
		{
		}
			break;
		case ((unichar)'v'):
			break;
		default:
//			[super keyDown];
			break;
	}
}

*/


@end
