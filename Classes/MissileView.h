//
//  MissileController.h
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 11/06/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "USBMissileControl.h"

@interface MissileView : NSView
{

	USBMissileControl * USBLauncher;
	
	IBOutlet id btn_safety;
	
}

- (BOOL)acceptsFirstResponder;
- (BOOL)becomeFirstResponder;


- (IBAction)btn_upLeft:(id)sender;
- (IBAction)btn_up:(id)sender;
- (IBAction)btn_upRight:(id)sender;
- (IBAction)btn_left:(id)sender;
- (IBAction)btn_fire:(id)sender;
- (IBAction)btn_right:(id)sender;
- (IBAction)btn_downLeft:(id)sender;
- (IBAction)btn_down:(id)sender;
- (IBAction)btn_downRight:(id)sender;

- (IBAction)btn_safety:(id)sender;

- (void)mouseUp:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)keyDown:(NSEvent *)event;

@end
