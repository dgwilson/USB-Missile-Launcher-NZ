//
//  MissileResponder.h
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 11/06/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AsyncSocket;
@class MTMessageBroker;

@interface MissileResponder : NSWindow <NSNetServiceDelegate>
{

//	USBMissileControl * USBLauncherControl;
//	USBJoyStickControl * USBJoystickController; 
	Boolean			    launcherLocked;
	NSTimer			  * timer;
	float				timerDurationFromAppleScript;
	IBOutlet NSDrawer * buttonControlPanel;
	//NSWindow		  * mainWindow;
	NSTimer		      * reLockTime;
	float				autoLockInterval;
	NSTimeInterval		autoLockTime;
	Boolean				launcherCommandInProgress;
	NSString		  * launchSoundPath;
	NSString		  * klaxonSoundPath;
	BOOL			    soundOn;
	BOOL				reverseArrowKeys_BOOL;
	
	NSButton	      * btn_upLeft;
	NSButton	      * btn_up;
	NSButton	      * btn_upRight;
	NSButton	      * btn_left;
	NSButton	      * btn_fire;
	NSButton		  * btn_fire3;
	NSButton	      * btn_right;
	NSButton	      * btn_downLeft;
	NSButton	      * btn_down;
	NSButton	      * btn_downRight;
	NSButton		  * btn_dgw;
	NSButton		  * btn_prime;
	IBOutlet id safetyButton;
	
	IBOutlet id launcherStatus;
	IBOutlet id launcherMessage;
	
	NSNetService *netService;
    AsyncSocket *listeningSocket;
    AsyncSocket *connectionSocket;
    MTMessageBroker *messageBroker;
}

@property (readwrite, retain) AsyncSocket *listeningSocket;
@property (readwrite, retain) AsyncSocket *connectionSocket;
@property (readwrite, retain) MTMessageBroker *messageBroker;

- (void)awakeFromNib;
- (void)prefsCreate;
- (void)prefsChanged;
- (void)usbConnect;
- (void)usbConnectIssue;
- (void)usbDisConnect;
- (void)usbError;

- (void)DGWtimerSet;
- (void)DGWtimerReached:(NSTimer *)inTimer;
- (void)resetLockTimer;
- (void)setSafety;
- (void)finishCommandInProgress;
- (void)playKlaxon:(id)sender;

- (IBAction)btn_upLeft:(id)sender;
- (IBAction)btn_up:(id)sender;
- (IBAction)btn_upRight:(id)sender;
- (IBAction)btn_left:(id)sender;
- (IBAction)btn_fire:(id)sender;
- (IBAction)btn_fire3:(id)sender;
- (IBAction)btn_right:(id)sender;
- (IBAction)btn_downLeft:(id)sender;
- (IBAction)btn_down:(id)sender;
- (IBAction)btn_downRight:(id)sender;
- (IBAction)btn_ABORT:(id)sender;
- (IBAction)btn_park:(id)sender;
- (IBAction)btn_test:(id)sender;
- (IBAction)btn_safety:(id)sender;
- (IBAction)btn_dgw:(id)sender;
- (IBAction)btn_laser:(id)sender;
- (IBAction)btn_prime:(id)sender;

- (IBAction)menu_safety:(id)sender;

- (void)keyDown:(NSEvent *)event;
- (void)keyUp:(NSEvent *)event;

- (void)LauncherDisabledMessage;

- (void)joystickInput:(NSNotification*)notification;

// AppleScript Commands
//- (id)initWithCommandDescription:(NSScriptCommandDescription *)commandDesc;
//- (id)ASToggleLockTest:(NSScriptCommand*)command;
- (id)ASAbort;
- (id)ASToggleLock;
- (id)ASLeft:(NSNotification *)notification;
- (id)ASRight:(NSNotification *)notification;
- (id)ASUp:(NSNotification *)notification;
- (id)ASDown:(NSNotification *)notification;
- (id)ASUpLeft:(NSNotification *)notification;
- (id)ASUpRight:(NSNotification *)notification;
- (id)ASDownLeft:(NSNotification *)notification;
- (id)ASDownRight:(NSNotification *)notification;

-(void)startService;
-(void)stopService;


@end
