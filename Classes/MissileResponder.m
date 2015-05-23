//
//  MissileResponder.m
//  USB Missile Launcher NZ
//
//  Created by David G. Wilson on 11/06/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

#import "MissileResponder.h"
#import <Scripting/Scripting.h>

#import "AsyncSocket.h"
#import "MTMessageBroker.h"
#import "MTMessage.h"


#define kDefaultLaunchPath		@"RocketLaunch.wav"
#define kDefaultKlaxonPath		@"Nuclear Silo Launch Klaxon.mp3"

@implementation MissileResponder

@synthesize listeningSocket;
@synthesize connectionSocket;
@synthesize messageBroker;

/* (id)init;
{
	self = [super init];
	return self;
}*/

- (void)awakeFromNib 
{
//	NSLog(@"MissileResponder:awakeFromNib");
	NSUserDefaults* prefs = [[NSUserDefaults standardUserDefaults] retain];
	int preferencesVersion;
	preferencesVersion = [prefs integerForKey:@"preferencesVersion"];
	if (preferencesVersion == 14)
	{
		NSLog(@"Preference Version OK");
		[prefs release];
	} else 
	{
		if (preferencesVersion == 13)
		{
			NSLog(@"Preference Version change has occurred - Updating");
			NSRunAlertPanel(NSLocalizedString(@"Preference version change.", @"Title of alert when a the preferences have changed or did not exist."),
							NSLocalizedString(@"Please review the application preference settings. Thank you for downloading and running this software.", @"Alert text."),
							NSLocalizedString(@"OK", @"OK"), nil, nil);		
		} else
		{
			NSLog(@"No preferences exist - Creating");
		}
		
		[prefs release];
		[self prefsCreate];
	}

	// Setup for joystick input
	//	NSLog(@"MissileResponder: - See if there are any alternative input devices attached (Joysticks)");
	USBJoystickController = [[USBJoyStickControl alloc] initHIDNotifications];
	
	[btn_upLeft setPeriodicDelay:0.2 interval:0.2];
	[btn_up setPeriodicDelay:0.2 interval:0.2];
	[btn_upRight setPeriodicDelay:0.2 interval:0.2];
	[btn_left setPeriodicDelay:0.2 interval:0.2];
	[btn_fire setPeriodicDelay:0.2 interval:0.2];
	[btn_right setPeriodicDelay:0.2 interval:0.2];
	[btn_downLeft setPeriodicDelay:0.2 interval:0.2];
	[btn_down setPeriodicDelay:0.2 interval:0.2];
	[btn_downRight setPeriodicDelay:0.2 interval:0.2];
	
	timer = nil;
	
	//autoLockInterval = 30;
	//NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	//autoLockInterval = [prefs floatForKey:@"autoLockInterval"];
	//NSLog(@"autoLockInterval=%f", autoLockInterval);
	[self prefsChanged];
	
	//[[NSNotificationCenter defaultCenter] postNotificationName: @"PrefsChanged" object: nil];
	//- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(NSString *)notificationName object:(id)anObject
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(prefsChanged)
												 name: @"PrefsChanged"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(usbConnect)
												 name: @"usbConnect"
											   object: nil
	 ];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(usbConnectIssue)
												 name: @"usbConnectIssue"
											   object: nil
	 ];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(usbDisConnect)
												 name: @"usbDisConnect"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(usbError)
												 name: @"usbError"
											   object: nil
	 ];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(finishCommandInProgress)
												 name: @"finishCommandInProgress"
											   object: nil
		];

	// Added for JoyStick Support
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(joystickInput:)
												 name: @"joystickInput"
											   object: nil
		];

	// Added for AppleScript Support
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASAbort)
												 name: @"ASAbort"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASToggleLock)
												 name: @"ASToggleLock"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASLeft:)
												 name: @"ASLeft"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASRight:)
												 name: @"ASRight"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASUp:)
												 name: @"ASUp"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASDown:)
												 name: @"ASDown"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASUpLeft:)
												 name: @"ASUpLeft"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASUpRight:)
												 name: @"ASUpRight"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASDownLeft:)
												 name: @"ASDownLeft"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASDownRight:)
												 name: @"ASDownRight"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(ASFire)
												 name: @"ASFire"
											   object: nil
		];

	
	USBLauncherControl = [[USBMissileControl alloc] init];
	//NSLog(@"Missile Control Initialised");
	
	if ([USBLauncherControl confirmMissileLauncherConnected] == NO)
	{
		[launcherMessage setStringValue:NSLocalizedString(@"Missile Launcher is NOT connected", nil)];
		[launcherStatus setStringValue:NSLocalizedString(@"Launcher Not Connected", nil)];
	}
	else
	{
		//[launcherMessage setStringValue:@"USB Launcher connected"];
		[launcherStatus setStringValue:NSLocalizedString(@"Launcher Status: Disabled", nil)];
		//[launcherStatus setStringValue:@"Launcher Status: Dyslexic"];
	}
	launcherLocked = YES;
	launcherCommandInProgress = NO;
	
	// Bonjour Networking
	[self startService];
}

- (void)prefsCreate;
{
	NSUserDefaults* prefs = [[NSUserDefaults standardUserDefaults] retain];

	// what would be best would be to call this routine in each of the preferences modules
	// - (IBAction)defaultPrefs:(id)sender;

    [prefs setInteger:14 forKey:@"preferencesVersion"];
	
	// General Preferences
	[prefs setFloat:50.0 forKey:@"autoLockInterval"];
	[prefs setBool:TRUE forKey:@"soundOn"];
	[prefs setObject:@"" forKey:@"launchSound"];
	[prefs setObject:@"" forKey:@"klaxonSound"];

	// Sound Preferences
	[prefs setBool:TRUE forKey:@"soundOn"];
	[prefs setObject:@"" forKey:@"launchSound"];
	[prefs setObject:@"" forKey:@"klaxonSound"];

	// Joystick Preferences
	[prefs setFloat:20 forKey:@"joystickSensitivity"];
	[prefs setFloat:0 forKey:@"joystickFireButtonMatrix"];
	
	// Launcher Preferences
	[prefs setObject:@"4400" forKey:@"launcher1_VendorId"];
	[prefs setObject:@"514" forKey:@"launcher1_ProductId"];
	[prefs setObject:@"OrigLauncher" forKey:@"launcher1_type"];

	[prefs setObject:@"6465" forKey:@"launcher2_VendorId"];
	[prefs setObject:@"32801" forKey:@"launcher2_ProductId"];
	[prefs setObject:@"DreamRocket" forKey:@"launcher2_type"];
	
	[prefs setObject:@"2689" forKey:@"launcher3_VendorId"];
	[prefs setObject:@"1793" forKey:@"launcher3_ProductId"];
	[prefs setObject:@"DreamRocketII" forKey:@"launcher3_type"];
	
    [prefs synchronize];
	[prefs release];
}

- (void)prefsChanged;
{
	//NSLog(@"Preferences Changed!");
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	autoLockInterval = [prefs floatForKey:@"autoLockInterval"];
	//NSLog(@"autoLockInterval=%f", autoLockInterval);

	launchSoundPath = [prefs stringForKey:@"launchSound"];
	klaxonSoundPath = [prefs stringForKey:@"klaxonSound"];

	// setup the rocket launch sound!
	if (([launchSoundPath isEqualToString:@""]) || (launchSoundPath == nil))
	{
		rocketSound = [NSSound soundNamed:kDefaultLaunchPath];
		//NSLog(@"rocketSound - builtin loaded");
	} else {
		//rocketSound = [NSSound soundNamed:launchSoundPath];
		rocketSound = [[NSSound alloc] initWithContentsOfFile:launchSoundPath byReference:NO];
		//NSLog(@"rocketSound - loaded");
	}
		
	// setup the klaxon sound
	if (([klaxonSoundPath isEqualToString:@""]) || (klaxonSoundPath == nil))
	{
		nuclearKlaxon = [NSSound soundNamed:kDefaultKlaxonPath];
		//NSLog(@"nuclearKlaxon - builtin loaded");
	} else {
		//nuclearKlaxon = [NSSound soundNamed:klaxonSoundPath];
		nuclearKlaxon = [[NSSound alloc] initWithContentsOfFile:klaxonSoundPath byReference:NO];
		//NSLog(@"nuclearKlaxon - loaded");
	}

	//rocketSound = [NSSound soundNamed:@"RocketLaunch.wav"];
	//nuclearKlaxon = [NSSound soundNamed:@"Nuclear Silo Launch Klaxon.wav"];
	//[nuclearKlaxon play];
	
	soundOn = [prefs boolForKey:@"soundOn"];
	reverseArrowKeys_BOOL = [prefs floatForKey:@"reverseArrowKeys"];
	
	[self resetLockTimer];
	
}

#pragma mark -
#pragma mark Message Window Updates

- (void)usbConnect;
{
//	NSLog(@"sending USB Launcher Connected to main window");
	[launcherMessage setStringValue:NSLocalizedString(@"USB Launcher Connected", nil)];
}
- (void)usbConnectIssue;
{
	//	NSLog(@"sending USB Launcher Connected to main window");
	[launcherMessage setStringValue:NSLocalizedString(@"There was a problem connecting the launcher, please refer to the console log for more details", nil)];
}
- (void)usbDisConnect;
{
	[launcherMessage setStringValue:NSLocalizedString(@"USB Launcher Disconnected", nil)];
}
- (void)usbError;
{
	[launcherMessage setStringValue:NSLocalizedString(@"USB connection error - launcher disconnected, please refer to the console log for more details", nil)];
}

#pragma mark -
#pragma mark Window Draw Handling

- (BOOL)needsPanelToBecomeKey
{
//	NSLog(@"USB Missile Launcher NZ : MissileResponser.m : needsPanelToBecomeKey");
    return YES;
}

- (BOOL)becomesKeyOnlyIfNeeded
{
//	NSLog(@"USB Missile Launcher NZ : MissileResponser.m : becomesKeyOnlyIfNeeded");
    return YES;
}

#pragma mark -
#pragma mark Event Handling

- (void)DGWtimerSet;
{
	if (timer != nil) 
	{
		if ([timer isValid])
		{
			[timer invalidate];
			//NSLog(@"Timer invalidated");
		}
	}
//	NSLog(@"Timer started begin: %f", timerDurationFromAppleScript);
	if (timerDurationFromAppleScript == 0)
		timerDurationFromAppleScript = 0.25;
	timer = nil;
	timer = [NSTimer scheduledTimerWithTimeInterval:timerDurationFromAppleScript
											 target:self
										   selector:@selector(DGWtimerReached:)
										   userInfo:nil
											repeats:NO];
//	NSLog(@"Timer started   end: %f", timerDurationFromAppleScript);
	return;
}

- (void)DGWtimerReached:(NSTimer *)inTimer;
{
//	NSLog(@"DGWTimerReached - sending launcher stop command");
	[USBLauncherControl controlLauncher:launcherStop];
	[timer invalidate];
	timer = nil;
	timerDurationFromAppleScript = 0.25;
	//NSLog(@"Timer stopped");
}


- (IBAction)btn_upLeft:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (reverseArrowKeys_BOOL)
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRightUp]];
		} else 
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeftUp]];
		}
		[self resetLockTimer];
//		if (sender != self) 
		{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	}
}
- (IBAction)btn_up:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherUp]];
		[self resetLockTimer];
//		if (sender != self) 
		{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	}
}
- (IBAction)btn_upRight:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (reverseArrowKeys_BOOL)
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeftUp]];
		} else
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRightUp]];			
		}
		[self resetLockTimer];
//		if (sender != self) 
		{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	}
}
- (IBAction)btn_left:(id)sender;
{
	//NSLog(@"btn_left %@", sender);
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (reverseArrowKeys_BOOL)
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRight]];
		} else
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeft]];
		}
		[self resetLockTimer];
//		if (sender != self) 
		{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	}
}
- (IBAction)btn_fire:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (soundOn)
		{
			[rocketSound play];
		}
		[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherFire]];
		[self resetLockTimer];
	}
}
- (IBAction)btn_fire3:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		[launcherMessage setStringValue:NSLocalizedString(@"Triple Fire Engaged", nil)];
		[nuclearKlaxon play];
		[self performSelector:@selector(btn_fire:) withObject:self afterDelay:0.0];
		[self performSelector:@selector(btn_fire:) withObject:self afterDelay:7.0];
		[self performSelector:@selector(btn_fire:) withObject:self afterDelay:14.0];
	}
}
- (IBAction)btn_right:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (reverseArrowKeys_BOOL)
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeft]];
		} else
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRight]];
		}
		[self resetLockTimer];
//		if (sender != self) 
		{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	}
}
- (IBAction)btn_downLeft:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (reverseArrowKeys_BOOL)
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRightDown]];
		} else
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeftDown]];
		}
		[self resetLockTimer];
//		if (sender != self) 
		{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	}
}
- (IBAction)btn_down:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherDown]];
		[self resetLockTimer];
//		if (sender != self) 
		{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	}
}
- (IBAction)btn_downRight:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (reverseArrowKeys_BOOL)
		{		
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeftDown]];
		} else
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRightDown]];			
		}
		[self resetLockTimer];
//		if (sender != self) 
		{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	}
}

- (IBAction)btn_prime:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherPrime]];
	}		
}

- (IBAction)btn_safety:(id)sender;
{
//	NSLog(@"btn_safety has changed %d", [sender floatValue]);
	if ([USBLauncherControl confirmMissileLauncherConnected] == NO)
	{
		[launcherMessage setStringValue:NSLocalizedString(@"Missile Launcher is NOT connected", nil)];
		[launcherStatus setStringValue:NSLocalizedString(@"Launcher Not Connected", nil)];
		[buttonControlPanel close:self];
		[sender setFloatValue:0];
	}
	else
	{
		if ([sender floatValue] == 0)
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherStop]];
			launcherLocked = YES;
			[launcherStatus setStringValue:NSLocalizedString(@"Launcher Status: Disabled", nil)];
			[buttonControlPanel close:self];
			if (reLockTime != nil) 
			{
				[launcherMessage setStringValue:NSLocalizedString(@"Launcher locked automatically", nil)];
				if ([reLockTime isValid])
				{
					[reLockTime invalidate];
					[reLockTime release];
					reLockTime = nil;
				}
			}
			
		}
		else
		{
			launcherLocked = NO;
			[launcherStatus setStringValue:NSLocalizedString(@"Launcher Status: Enabled", nil)];
			[launcherMessage setStringValue:@""];
			[buttonControlPanel open:self];
			
			[launcherMessage setStringValue:NSLocalizedString(@"AutoLocking enabled", nil)];
			[self resetLockTimer];
		}
	}
}
- (IBAction)btn_ABORT:(id)sender;
{
	//NSLog(@"btn_ABORT");
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		[launcherMessage setStringValue:NSLocalizedString(@"Abort activated - command termination in progress", nil)];
		[USBLauncherControl controlLauncher:launcherStop];
		[self finishCommandInProgress];
	}
}

- (IBAction)btn_park:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (launcherCommandInProgress) 
		{
			[launcherMessage setStringValue:NSLocalizedString(@"Error: Command in progress!", nil)];
		} else {
			launcherCommandInProgress = YES;
			//[launcherMessage setStringValue:@"Relocating launcher to top left"];
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherPark]];
			
			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Relocating launcher to top left", nil) afterDelay:0.0];
			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Relocating launcher to middle", nil) afterDelay:7.0];
			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Test Complete", nil) afterDelay:13.0];
			
			[self performSelector:@selector(playKlaxon:) withObject:self afterDelay:0.0];
			//[self performSelector:@selector(playKlaxon:) withObject:self afterDelay:9.0];
			
		}
	}
}

- (IBAction)btn_test:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (launcherCommandInProgress) 
		{
			[launcherMessage setStringValue:NSLocalizedString(@"Error: Command in progress!", nil)];
		} else {
			launcherCommandInProgress = YES;
			//[launcherMessage setStringValue:@"Relocating launcher to top left"];
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherPark]];
			
			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Relocating launcher to top left", nil) afterDelay:0.0];
			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Relocating launcher to middle", nil) afterDelay:7.0];
			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Test Complete", nil) afterDelay:13.0];
			
			[self performSelector:@selector(playKlaxon:) withObject:self afterDelay:0.0];
			//[self performSelector:@selector(playKlaxon:) withObject:self afterDelay:9.0];
			
			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Look Out - triple fire", nil) afterDelay:26.0];
			[self performSelector:@selector(playKlaxon:) withObject:self afterDelay:26.0];
			[self performSelector:@selector(btn_fire:) withObject:self afterDelay:26.0];
			[self performSelector:@selector(btn_fire:) withObject:self afterDelay:34.0];
			[self performSelector:@selector(btn_fire:) withObject:self afterDelay:42.0];
		}
	}
}

- (IBAction)btn_dgw:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (launcherCommandInProgress) 
		{
			[launcherMessage setStringValue:NSLocalizedString(@"Error: Command in progress!", nil)];
		} else {
			launcherCommandInProgress = YES;
			//[launcherMessage setStringValue:@"Relocating launcher to top left"];
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherPark]];

			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Relocating launcher to top left", nil) afterDelay:0.0];
			[launcherMessage performSelector:@selector(setStringValue:) withObject:NSLocalizedString(@"Relocating launcher to middle", nil) afterDelay:7.0];

			[self performSelector:@selector(playKlaxon:) withObject:self afterDelay:0.0];
			//[self performSelector:@selector(playKlaxon:) withObject:self afterDelay:9.0];
			
		}
	}
	
}

- (IBAction)btn_laser:(id)sender;
{
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLaserToggle]];
	}
	[self resetLockTimer];
	if (sender != self) 
	{ [self DGWtimerSet]; } // issue launcher stop command after 0.1 seconds
	
}

- (void)finishCommandInProgress;
{
	launcherCommandInProgress = NO;
	// NSLog(@"finishCommandInProgress - set to NO");
	[launcherMessage setStringValue:NSLocalizedString(@"Test Complete", nil)];
}

- (void)playKlaxon:(id)sender;
{
	if (soundOn) 
	{
		//NSLog(@"Make Klaxon noise!");
		[nuclearKlaxon play];
	}
}

- (void)resetLockTimer;
{
	if (reLockTime != nil) 
	{
		if ([reLockTime isValid])
		{
			[reLockTime invalidate];
			[reLockTime release];
			reLockTime = nil;
		}
	}
	if (autoLockInterval > 0) 
	{
		autoLockTime = autoLockInterval;
		reLockTime = [[NSTimer scheduledTimerWithTimeInterval:autoLockTime
											 target:self
										   selector:@selector(setSafety)
										   userInfo:nil
											repeats:NO] retain];
	} else {
		[launcherMessage setStringValue:@"AutoLocking disabled"];
	}
}

- (void)setSafety;
{
	[safetyButton setFloatValue:0];
	[self btn_safety:safetyButton];
}

- (IBAction)menu_safety:(id)sender;
{
	if ([safetyButton floatValue] == 0)
	{
		[safetyButton setFloatValue:1];
	} else {
		[safetyButton setFloatValue:0];
	}
	[self btn_safety:safetyButton];
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
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		switch (key) {
			case    49: // numeric keypad 1
				handled = YES;
				if (reverseArrowKeys_BOOL)
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRightDown]];
				} else
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeftDown]];
				}
				break;
			case 63233: //down arrow
			case    50: // numeric keypad 2
				handled = YES;
				[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherDown]];
				break;
			case    51: // numeric keypad 3
				handled = YES;
				if (reverseArrowKeys_BOOL)
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeftDown]];
					
				} else
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRightDown]];
				}
				break;
			case 63234: //left arrow
			case    52: // numeric keypad 4
				handled = YES;
				if (reverseArrowKeys_BOOL)
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRight]];
				} else
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeft]];
				}
				break;
			case    53: // numeric keypad 5
				handled = YES;
				[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherFire]];
				if (soundOn)
				{
					[rocketSound play];
				}
				break;
			case 63235: //Right arrow
			case    54: // numeric keypad 6
				handled = YES;
				if (reverseArrowKeys_BOOL)
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeft]];
				} else
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRight]];
				}
				break;
			case    55: // numeric keypad 7
				handled = YES;
				if (reverseArrowKeys_BOOL)
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRightUp]];					
				} else
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeftUp]];	
				}
				break;
			case 63232: //down up
			case    56: // numeric keypad 8
				handled = YES;
				[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherUp]];
				break;
			case    57: // numeric keypad 9
				handled = YES;
				if (reverseArrowKeys_BOOL)
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherLeftUp]];
				} else
				{
					[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherRightUp]];
				}
				break;
		}
		[self resetLockTimer];
	}
    if (!handled)
        [super keyDown:event];
	
}

- (void)keyUp:(NSEvent *)event;
{
//	NSLog(@"Key Up");
// keyUp sends a STOP to the missile launcher. It will therefore stop (abort) the fire sequence as well	

    NSString * characters;
	unichar key;
    // get the pressed key
	characters = [event characters];
	key = [characters characterAtIndex:0];
	
	if (launcherLocked)
	{
		[self LauncherDisabledMessage];
	} else {
		if (key == 53) // numeric keypad 5
		{		
			// do nothing - the abort sequence is handled by the launcher code
		} else 
		{
			[USBLauncherControl controlLauncher:[NSNumber numberWithInt:launcherStop]];
		}
	}
}

- (void)LauncherDisabledMessage;
{
	[launcherMessage setStringValue:NSLocalizedString(@"Launcher is Disabled, Release Safety First", nil)];
}

- (void)joystickInput:(NSNotification*)notification;
{
	int	action;
	
	//NSLog(@"joystickInput: action %@", notification);
	//	if ([[[notification userInfo] valueForKey:@"Action"] intValue] == 1)
	//	{
	//		NSLog(@"joystickInput: action 1 confirmed");			
	//	}
	
	action = [[[notification userInfo] valueForKey:@"Action"] intValue];
	//NSLog(@"Requested Action = %d", action);

	//     |  16  | 8 | 4 | 2 | 1 |
	//     |------|---|---|---|---|
	//     |   0  | 0 | 0 | 0 | 1 |    1 - Up
	//     |   0  | 0 | 0 | 1 | 0 |    2 - Down
	//     |   0  | 0 | 1 | 0 | 0 |    4 - Left
	//     |   0  | 0 | 1 | 0 | 1 |    5 - Up / Left
	//     |   0  | 0 | 1 | 1 | 0 |    6 - Down / left
	//     |   0  | 1 | 0 | 0 | 0 |    8 - Right
	//     |   0  | 1 | 0 | 0 | 1 |    9 - Up / Right
	//     |   0  | 1 | 0 | 1 | 0 |   10 - Down / Right
	//     |   1  | 0 | 0 | 0 | 0 |   16 - Fire
	
	if (action == 0)
	{
		[self btn_ABORT:self];
	}
	
	if (action-16 >= 0)
	{
		action = action - 16;
		[self btn_fire:self];
	}
	if (action-10 >= 0)
	{
		action = action - 10;
		[self btn_downRight:self];
	}	
	if (action-9 >= 0)
	{
		action = action - 9;
		[self btn_upRight:self];
	}
	if (action-8 >= 0)
	{
		action = action - 8;
		[self btn_right:self];
	}
	if (action-6 >= 0)
	{
		action = action - 6;
		[self btn_downLeft:self];
	}
	if (action-5 >= 0)
	{
		action = action - 5;
		[self btn_upLeft:self];
	}
	if (action-4 >= 0)
	{
		action = action - 4;
		[self btn_left:self];
	}
	if (action-2 >= 0)
	{
		action = action - 2;
		[self btn_down:self];
	}
	if (action-1 >= 0)
	{
		action = action - 1;
		[self btn_up:self];
	}
	if (action != 0)
	{
		// action should have a value of zero at this point
		[self btn_ABORT:self];
	}
	
}

#pragma mark -
#pragma mark AppleScript routines

// AppleScript Commands

//- (id)initWithCommandDescription:(NSScriptCommandDescription *)commandDesc;
//{
//	NSLog(@"initWithCommandDescription: %@", commandDesc);
//	return self;
//}

//- (id)ASToggleLockTest:(NSScriptCommand*)command;
//{
//	NSLog(@"ASToggleLock: %@", command);
//	[self btn_safety:self];
//	return nil;
//}

- (id)ASAbort;
{
	[self btn_ABORT:self];
	return nil;
}
- (id)ASToggleLock;
{
	[self menu_safety:self];
	return nil;
}
- (id)ASLeft:(NSNotification *)notification;
{
//	NSLog(@"ASLeft has been called \n %@", notification);
	id				moveTimerSeconds = [[notification userInfo] objectForKey:@"moveTimerSeconds"];
	long			moveTimerSecondsValue = [moveTimerSeconds longValue];
//	NSLog(@"ASLeft has been called moveTimerSecondsValue %d", moveTimerSecondsValue);
//	NSLog(@"Left   moveTimerSecondsValue %d", moveTimerSecondsValue);		
	timerDurationFromAppleScript = moveTimerSecondsValue;
	[self btn_left:self];
//	[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	return nil;
}
- (id)ASRight:(NSNotification *)notification;
{
	id				moveTimerSeconds = [[notification userInfo] objectForKey:@"moveTimerSeconds"];
	long			moveTimerSecondsValue = [moveTimerSeconds longValue];
//	NSLog(@"Right  moveTimerSecondsValue %d", moveTimerSecondsValue);		
	timerDurationFromAppleScript = moveTimerSecondsValue;
	[self btn_right:self];
//	[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	return nil;
}
- (id)ASUp:(NSNotification *)notification;
{
	id				moveTimerSeconds = [[notification userInfo] objectForKey:@"moveTimerSeconds"];
	long			moveTimerSecondsValue = [moveTimerSeconds longValue];
//	NSLog(@"Up     moveTimerSecondsValue %d", moveTimerSecondsValue);		
	timerDurationFromAppleScript = moveTimerSecondsValue;
	[self btn_up:self];
//	[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	return nil;
}
- (id)ASDown:(NSNotification *)notification;
{
	id				moveTimerSeconds = [[notification userInfo] objectForKey:@"moveTimerSeconds"];
	long			moveTimerSecondsValue = [moveTimerSeconds longValue];
//	NSLog(@"Down   moveTimerSecondsValue %d", moveTimerSecondsValue);		
	timerDurationFromAppleScript = moveTimerSecondsValue;
	[self btn_down:self];
//	[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	return nil;
}
- (id)ASUpLeft:(NSNotification *)notification;
{
	id				moveTimerSeconds = [[notification userInfo] objectForKey:@"moveTimerSeconds"];
	long			moveTimerSecondsValue = [moveTimerSeconds longValue];
	timerDurationFromAppleScript = moveTimerSecondsValue;
	[self btn_upLeft:self];
//	[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	return nil;
}
- (id)ASUpRight:(NSNotification *)notification;
{
	id				moveTimerSeconds = [[notification userInfo] objectForKey:@"moveTimerSeconds"];
	long			moveTimerSecondsValue = [moveTimerSeconds longValue];
	timerDurationFromAppleScript = moveTimerSecondsValue;
	[self btn_upRight:self];
//	[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	return nil;
}
- (id)ASDownLeft:(NSNotification *)notification;
{
	id				moveTimerSeconds = [[notification userInfo] objectForKey:@"moveTimerSeconds"];
	long			moveTimerSecondsValue = [moveTimerSeconds longValue];
	timerDurationFromAppleScript = moveTimerSecondsValue;
	[self btn_downLeft:self];
//	[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	return nil;
}
- (id)ASDownRight:(NSNotification *)notification;
{
	id				moveTimerSeconds = [[notification userInfo] objectForKey:@"moveTimerSeconds"];
	long			moveTimerSecondsValue = [moveTimerSeconds longValue];
	timerDurationFromAppleScript = moveTimerSecondsValue;
	[self btn_downRight:self];
//	[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:timerDurationFromAppleScript]];
	return nil;
}
- (id)ASFire;
{
	[self btn_fire:self];
	return nil;
}

#pragma mark -
#pragma mark Bonjour Networking and Message Handling

-(void)startService {
    // Start listening socket
    NSError *error;
    self.listeningSocket = [[[AsyncSocket alloc]initWithDelegate:self] autorelease];
    if ( ![self.listeningSocket acceptOnPort:0 error:&error] ) {
        NSLog(@"Failed to create listening socket");
        return;
    }
    
    // Advertise service with bonjour
    NSString *serviceName = [NSString stringWithFormat:@"USB Missile Launcher NZ on %@", [[NSProcessInfo processInfo] hostName]];
    netService = [[NSNetService alloc] initWithDomain:@"" type:@"_usbmissilelaunchernz._tcp." name:serviceName port:self.listeningSocket.localPort];
    netService.delegate = self;
    [netService publish];
	NSLog(@"%@ Bonjour service _usbmissilelaunchernz._tcp. has been published", NSStringFromSelector(_cmd));
}

-(void)stopService {
    self.listeningSocket = nil;
    self.connectionSocket = nil;
    self.messageBroker.delegate = nil;
    self.messageBroker = nil;
    [netService stop]; 
    [netService release];    
    [super dealloc];
}

-(void)dealloc {
    [self stopService];
    [super dealloc];
}

-(void)sendAcknowledgement:(NSString *)response
{
	//    NSLog(@"%@ : %@", NSStringFromSelector(_cmd), command);
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[[MTMessage alloc] init] autorelease];
    newMessage.tag = 101;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];	
}

#pragma mark Socket Callbacks
-(BOOL)onSocketWillConnect:(AsyncSocket *)sock {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
    if ( self.connectionSocket == nil ) {
        self.connectionSocket = sock;
        return YES;
    }
    return NO;
}

-(void)onSocketDidDisconnect:(AsyncSocket *)sock {
	NSLog(@"%@", NSStringFromSelector(_cmd));
    if ( sock == self.connectionSocket ) {
        self.connectionSocket = nil;
        self.messageBroker = nil;
    }
}

-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	NSLog(@"%@", NSStringFromSelector(_cmd));
    MTMessageBroker *newBroker = [[[MTMessageBroker alloc] initWithAsyncSocket:sock] autorelease];
    newBroker.delegate = self;
    self.messageBroker = newBroker;
	[self sendAcknowledgement:@"Communications acknowledged. Your missles are ready for Launch."];
}

#pragma mark MTMessageBroker Delegate Methods

-(void)messageBrokerDidDisconnectUnexpectedly:(MTMessageBroker *)server
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
	self.connectionSocket = nil;
	self.messageBroker = nil;	
}

-(void)messageBroker:(MTMessageBroker *)server didReceiveMessage:(MTMessage *)message {
//	NSLog(@"%@", NSStringFromSelector(_cmd));
    if ( message.tag == 100 ) {
//        textView.string = [[[NSString alloc] initWithData:message.dataContent encoding:NSUTF8StringEncoding] autorelease];
		NSString * remoteCommand = [[[NSString alloc] initWithData:message.dataContent encoding:NSUTF8StringEncoding] autorelease];
//		NSLog(@"%@ --> incoming Command >%@<", NSStringFromSelector(_cmd), remoteCommand);
		
		// if there is no launcher connected, then there's not much point trying to execute a command against a launcher.
		if ([USBLauncherControl confirmMissileLauncherConnected] == NO)
		{
			[self sendAcknowledgement:NSLocalizedString(@"Missile Launcher is NOT connected", nil)];
			return;
		}
			
		if (NSOrderedSame == [remoteCommand compare:@"Unlock"])
		{
			[self menu_safety:self];
			[self sendAcknowledgement:@"Unlock Received, Engage Target."];
			return;
		}
		if (NSOrderedSame == [remoteCommand compare:@"Lock"])
		{
			[self menu_safety:self];
			[self sendAcknowledgement:@"Lock Received."];
			return;
		}
		
		// no point continuing from this point either if the launcher is locked.
		if (launcherLocked)
		{
			[self sendAcknowledgement:@"Launcher is locked, command igmored."];
			return;
		}
		
		if (NSOrderedSame == [remoteCommand compare:@"Up"])
		{
			[self btn_up:self];
			[self sendAcknowledgement:@"Up Received."];
			return;
		}
		if (NSOrderedSame == [remoteCommand compare:@"UpLeft"])
		{
			[self btn_upLeft:self];
			[self sendAcknowledgement:@"UpLeft Received."];
			return;
		}
		if (NSOrderedSame == [remoteCommand compare:@"UpRight"])
		{
			[self btn_upRight:self];
			[self sendAcknowledgement:@"UpRight Received."];
			return;
		}
		if (NSOrderedSame == [remoteCommand compare:@"Down"])
		{
			[self btn_down:self];
			[self sendAcknowledgement:@"Down Received."];
			return;
		}
		if (NSOrderedSame == [remoteCommand compare:@"DownLeft"])
		{
			[self btn_downLeft:self];
			[self sendAcknowledgement:@"DownLeft Received."];
			return;
		}		
		if (NSOrderedSame == [remoteCommand compare:@"DownRight"])
		{
			[self btn_downRight:self];
			[self sendAcknowledgement:@"DownRight Received."];
			return;
		}		
		if (NSOrderedSame == [remoteCommand compare:@"Left"])
		{
			[self btn_left:self];
			[self sendAcknowledgement:@"Left Received."];
			return;
		}
		if (NSOrderedSame == [remoteCommand compare:@"Right"])
		{
			[self btn_right:self];
			[self sendAcknowledgement:@"Right Received."];
			return;
		}
		if (NSOrderedSame == [remoteCommand compare:@"Fire"])
		{
			[self btn_fire:self];
			[self sendAcknowledgement:@"Fire Received."];
			return;
		}
		
		// Otherwise
		[self sendAcknowledgement:[NSString stringWithFormat:@"Command '%@'is unknown.", remoteCommand]];
		NSLog(@"%@ Unknown command received from server '%@'", NSStringFromSelector(_cmd), remoteCommand);
    }
}

#pragma mark Net Service Delegate Methods
-(void)netService:(NSNetService *)aNetService didNotPublish:(NSDictionary *)dict {
    NSLog(@"Failed to publish: %@", dict);
}

@end
