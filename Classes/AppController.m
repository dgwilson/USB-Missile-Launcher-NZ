//
//  AppController.m
//  USB Missile Launcher NZ
//
//  Created by David G. Wilson on 11/06/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

#import "AppController.h"
//#import "VideoDebugMacros.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <AVFoundation/AVFoundation.h>

#define kDefaultRecordPath		@"~/Desktop/USB Missile Launcher NZ.mov"

enum {
		kNumberType,
		kStringType,
		kPeriodType
};

@implementation AppController

@synthesize videoDocument;
@synthesize videoWindowButton;
@synthesize mCaptureToField;
@synthesize mMessagesField;


- (id)init
{
	bool	b_kext_Present;
	
    self = [super init];

	unsigned major, minor, bugFix;
    [self getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
    NSLog(@"OS Version - %u.%u.%u", major, minor, bugFix);
	NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSLog(@"Application release >%@<", currVersionNumber);

	// gestaltUserVisibleMachineName
	// gestaltUSBVersion
	//	if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;

//	OSErr err;
//	SInt32 usbVersion;
//    if ((err = Gestalt(gestaltUSBVersion, &usbVersion)) == noErr)
//	{
//		NSLog(@"USB Version >%ld<", usbVersion);
//	}
//	else
//		NSLog(@"Unable to obtain USB version: %ld", (long)err);
	
	
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:@"/Library/Extensions/USB Missile Launcher All Drivers.kext"])
	{
		b_kext_Present = true;
		NSLog(@"Found - /Library/Extensions/USB Missile Launcher All Drivers.kext");
	} else {
		b_kext_Present = false;
		NSLog(@"WARNING: Critical Support file not found - /Library/Extensions/USB Missile Launcher All Drivers.kext");
	}

	if (!b_kext_Present)
	{
		NSLog(@"WARNING: Critical Support file not found : Launcher performance may be degraded without these files");
//		NSLog(@"WARNING: Critical Support file not found : Displaying warning message to user");
		NSRunAlertPanel(@"USB Missile Launcher NZ",
						@"A critical support file was not found, details of the error can be found in the console.log file. To correct this error you should install this software using the application installer. If you continue to run this program, the launcher may not function as expected.", nil, nil, nil);
	}

	
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* defaultPrefs = [NSMutableDictionary dictionary];
	
    [defaultPrefs setObject:[NSNumber numberWithFloat:50.0] forKey:@"autoLockInterval"];

    [userDefaults registerDefaults:defaultPrefs];
    [userDefaults synchronize];

#pragma mark Developer Message
	
	NSUserDefaults* devUserDefaults = [NSUserDefaults standardUserDefaults];
	if (![devUserDefaults boolForKey:@"developerMessage"])
	{
		[self showDeveloperMessage:self];
		[devUserDefaults setBool:TRUE forKey:@"developerMessage"];
		[devUserDefaults synchronize];
	}

#pragma mark Video set up
	
	[mCaptureToField setStringValue:[kDefaultRecordPath stringByExpandingTildeInPath]];
	
	// Launch Video Window depending on user preference setting
	NSUserDefaults* myPrefs = [NSUserDefaults standardUserDefaults];
	if (![myPrefs floatForKey:@"cameraDisabled"])
	{
		if (NSClassFromString(@"AVCaptureSession") != nil)
		{
			videoDocument = [[AVRecorderDocument alloc] init];
			[videoDocument makeWindowControllers];
			[videoDocument showWindows];
		}
	}
		
	
	// need to set up an application notification for changing launcher icons
	// this can call an icon changing procedure
	// the USB connection code can detect which launcher is connected and set the
	// call the notification to set the icon appropriately - if both are set use the origional icon.
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(setMissileLauncherIcon:)
												 name: @"setMissileLauncherIcon"
											   object: nil
		];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(setDreamCheekyIcon:)
												 name: @"setDreamCheekyIcon"
											   object: nil
		];

	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(setDreamCheekyIOCIcon:)
												 name: @"setDreamCheekyIOCIcon"
											   object: nil
	 ];
	
	
	//NSLog(@"AppController init end");
    return self;
}

#pragma mark - system version

- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) goto fail;
    if (systemVersion < 0x1040)
    {
        if (major) *major = ((systemVersion & 0xF000) >> 12) * 10 +
            ((systemVersion & 0x0F00) >> 8);
        if (minor) *minor = (systemVersion & 0x00F0) >> 4;
        if (bugFix) *bugFix = (systemVersion & 0x000F);
    }
    else
    {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) goto fail;
        if (major) *major = versionMajor;
        if (minor) *minor = versionMinor;
        if (bugFix) *bugFix = versionBugFix;
    }
    
    return;
    
fail:
    NSLog(@"Unable to obtain system version: %ld", (long)err);
    if (major) *major = 10;
    if (minor) *minor = 0;
    if (bugFix) *bugFix = 0;
}

#pragma mark - About

- (IBAction)showAbout:(id)sender; 
{
	if (! aboutWindowController ) {
		aboutWindowController = [[AboutWindowController alloc] init];
	} // end if
	
	[aboutWindowController showWindow:self];
	
} // end showTheWindow


#pragma mark - open Video window

- (IBAction)openVideoDocument:(id)sender
{
	if (NSClassFromString(@"AVCaptureSession") != nil)
	{
		videoDocument = [[AVRecorderDocument alloc] init];
		[videoDocument makeWindowControllers];
		[videoDocument showWindows];
	}
	else
	{
		[videoWindowButton setEnabled:FALSE];
		NSAlert *alert = [NSAlert alertWithMessageText:@"Video display requires Mac OS 10.7 (Lion)"
										 defaultButton:@"OK"
									   alternateButton:@""
										   otherButton:@""
							 informativeTextWithFormat:@"Video display requires Mac OS 10.7 (Lion). Please upgrade and try again."];
		[alert runModal];
	}
}

#pragma mark - Feedback

- (IBAction)showFeedback:(id)sender; 
{
//	if (! feedbackWindowController ) {
//		feedbackWindowController = [[FeedbackWindowController alloc] init];
//	} // end if
//	
//	[feedbackWindowController showWindow:self];
	
} // end showTheWindow

#pragma mark - Icon changes

- (void)setDreamCheekyIcon:(id)sender;
{
	NSImage * myImage;
	myImage = [NSImage imageNamed: @"DreamCheeky_Launcher.psd"];
	[NSApp setApplicationIconImage: myImage];
}

- (void)setDreamCheekyIOCIcon:(id)sender;
{
	NSImage * myImage;
	myImage = [NSImage imageNamed: @"DreamCheeky IOC Launcher No Shadow.psd"];
	[NSApp setApplicationIconImage: myImage];
}

- (void)setMissileLauncherIcon:(id)sender;
{
	NSImage * myImage;
	myImage = [NSImage imageNamed: @"USBMissileLauncher.psd"];
	[NSApp setApplicationIconImage: myImage];
}
		
#pragma mark - Developer Message

- (IBAction)showDeveloperMessage:(id)sender;
{
	NSRunAlertPanel(@"USB Missile Launcher NZ", 
					@"Please see the built in HELP or README file for details on how to configure this software to work with your launcher. You must set your launcher preferences for USB VendorID and USB ProductID and launcher type, then quit and restart this application.", nil, nil, nil);
}

#pragma mark - Preferences

- (IBAction)showPrefs:(id)sender
{
#pragma unused(sender)
    if (!prefs) {
        prefs = [[SS_PrefsController alloc] init];
        // Set which panes are included, and their order.
		//[prefs setDebug:YES];
		[prefs setAlwaysShowsToolbar:YES];
		//        [prefs setPanesOrder:[NSArray arrayWithObjects:@"General", @"Sound", @"Joystick", @"Launcher", @"Updating", nil]];
        [prefs setPanesOrder:[NSArray arrayWithObjects:@"General", @"Sound", @"Joystick", @"Launcher", nil]];
    }
    
    // Show the preferences window.
    [prefs showPreferencesWindow];
}


#pragma mark - Application Stuff

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#pragma mark - unused(n)	
	//NSLog(@"applicationDidFinishLaunching");

    // Check to see if the user wants to check for updates on launch
//    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"UpdateLaunch"])
//    {
        [self checkVersion:TRUE]; // Indicates to not show feedback if there is NOT a new version
//    }

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)windowShouldClose:(id)sender
{
	return NO;
}

#pragma mark - Application Version Checking

- (IBAction)checkForUpdates:(id)sender;
{
	[self checkVersion:FALSE];
}

// Check and see if our host is actually up. Note the imported framework.
- (BOOL)isHostReachable 
{
    const char *host = "homepages.paradise.net.nz";
    BOOL isValid, result = 0;
    SCNetworkConnectionFlags flags = 0;
    isValid = SCNetworkCheckReachabilityByName(host, &flags);
    if (isValid && ((flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired))) 
    {
        result = YES;
    }
    return result;
}


/*________________________________________________________________________________________
*/

/*
 -- Just saving this code somewhere
 
	This usually just fails for me when there is no network. Don't forget
	to change the URL's and names for your specific need.
 
 The file should be of the format:
 
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
	<key>USB Missile Launcher NZ</key>
	<string>1.4b</string>
	</dict>
	</plist>
 */

- (void)checkVersion:(BOOL)quiet 
{
	NSComparisonResult		compareResult;
	
	if ([self isHostReachable])
	{
		NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
		NSLog(@"checkVersion current >%@<", currVersionNumber);
		NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://homepages.paradise.net.nz/dgwilson/software/version.xml"]];
		NSString *latestVersionNumber = [productVersionDict valueForKey:@"USB Missile Launcher NZ"];
		NSLog(@"checkVersion latest  >%@<", latestVersionNumber);
		
		if([productVersionDict count] > 0 ) { // did we get anything?

			// - (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB
			compareResult = [self compareVersion:latestVersionNumber toVersion:currVersionNumber];
			if (compareResult == NSOrderedAscending)
			{
				NSLog(@"checkVersion: A later version of the software has been released");
			}
			if (compareResult == NSOrderedDescending)
			{
				NSLog(@"checkVersion: Beta WARNING - the version you are using is higher than the latest release version online");  // the version you are using is higher than the latest release version online
			}
			if (compareResult == NSOrderedSame)
			{
				NSLog(@"checkVersion: Version match - all good");
			}
			
			if((compareResult == NSOrderedSame) && (!quiet))
			{
				// tell user software is up to date
				NSRunAlertPanel(NSLocalizedString(@"Your Software is up-to-date", @"Title of alert when a the user's software is up to date."),
								NSLocalizedString(@"You have the most recent version of USB Missile Launcher NZ.", @"Alert text when the user's software is up to date."),
								NSLocalizedString(@"OK", @"OK"), nil, nil);
			}
			else if (compareResult == NSOrderedAscending)
			{
				// tell user to download a new version
				//NSString * myMessage = [NSString stringWithFormat:NSLocalizedString(@"A new version of USB Missile Launcher NZ is available (version %@). Would you like to download the new version now?", nil), latestVersionNumber];
				NSString * myMessage = [NSLocalizedString(@"A new version of USB Missile Launcher NZ is available (version %@). Would you like to download the new version now?", nil) stringByReplacingOccurrencesOfString:@"%@" withString:latestVersionNumber];
				
				NSUInteger button = NSRunAlertPanel(NSLocalizedString(@"A New Version is Available", nil),
											 @"%@",
											 NSLocalizedString(@"OK", @"OK"),
											 NSLocalizedString(@"Cancel", @"Cancel"), nil, myMessage);
				if(NSOKButton == button)
				{
					//[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://homepages.paradise.net.nz/dgwilson"]];
					
					[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.versiontracker.com/dyn/moreinfo/macosx/30149"]];
				}
			}
		} else {
			if (!quiet) {
				// tell user error occured
				NSRunAlertPanel(NSLocalizedString(@"Version Check has Failed", @"Title of alert when the version check has failed."),
								NSLocalizedString(@"An error occurred whilst trying to retrieve the current version number from the internet.", @"Alert text when the when the version check has failed."),
								NSLocalizedString(@"OK", @"OK"), nil, nil);
			}
		}
	}
	else
	{
		if (quiet == FALSE)
        {
            NSRunAlertPanel(NSLocalizedString(@"There was an error connecting to the server.", nil),  
							NSLocalizedString(@"Either you do not have the internet or the server is down for maintenance.", nil), 
							NSLocalizedString(@"Close", nil), nil, nil); // Localize it if you want.
        }
	}
}

/*________________________________________________________________________________________
 */

- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB
{
    NSArray *partsA = [self splitVersion:versionA];
    NSArray *partsB = [self splitVersion:versionB];
    
    NSString *partA, *partB;
    NSUInteger i, n, typeA, typeB, intA, intB;
    
    n = MIN([partsA count], [partsB count]);
    for (i = 0; i < n; ++i) {
        partA = [partsA objectAtIndex:i];
        partB = [partsB objectAtIndex:i];
        
        typeA = [self getCharType:partA];
        typeB = [self getCharType:partB];
        
        // Compare types
        if (typeA == typeB) {
            // Same type; we can compare
            if (typeA == kNumberType) {
                intA = [partA intValue];
                intB = [partB intValue];
                if (intA > intB) {
                    return NSOrderedAscending;
                } else if (intA < intB) {
                    return NSOrderedDescending;
                }
            } else if (typeA == kStringType) {
                NSComparisonResult result = [partA compare:partB];
                if (result != NSOrderedSame) {
                    return result;
                }
            }
        } else {
            // Not the same type? Now we have to do some validity checking
            if (typeA != kStringType && typeB == kStringType) {
                // typeA wins
                return NSOrderedAscending;
            } else if (typeA == kStringType && typeB != kStringType) {
                // typeB wins
                return NSOrderedDescending;
            } else {
                // One is a number and the other is a period. The period is invalid
                if (typeA == kNumberType) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }
        }
    }
    // The versions are equal up to the point where they both still have parts
    // Lets check to see if one is larger than the other
    if ([partsA count] != [partsB count]) {
        // Yep. Lets get the next part of the larger
        // n holds the value we want
        NSString *missingPart;
        int missingType, shorterResult, largerResult;
        
        if ([partsA count] > [partsB count]) {
            missingPart = [partsA objectAtIndex:n];
            shorterResult = NSOrderedDescending;
            largerResult = NSOrderedAscending;
        } else {
            missingPart = [partsB objectAtIndex:n];
            shorterResult = NSOrderedAscending;
            largerResult = NSOrderedDescending;
        }
        
        missingType = [self getCharType:missingPart];
        // Check the type
        if (missingType == kStringType) {
            // It's a string. Shorter version wins
            return shorterResult;
        } else {
            // It's a number/period. Larger version wins
            return largerResult;
        }
    }
    
    // The 2 strings are identical
    return NSOrderedSame;
}

- (NSArray *)splitVersion:(NSString *)version
{
    NSMutableArray *parts = [NSMutableArray array];
	NSUInteger partStart = 0;
	while (partStart < [version length]) {
		NSRange dotRange = [version rangeOfString:@"." options:0 range:NSMakeRange(partStart, [version length] - partStart)];
		if (dotRange.location == NSNotFound)
			break;
		[parts addObject:[version substringWithRange:NSMakeRange(partStart, dotRange.location - partStart)]];
		partStart = dotRange.location + dotRange.length;
	};
	//Add last part
	if (partStart < [version length])
		[parts addObject:[version substringFromIndex:partStart]];
	return parts;
}

/*- (NSArray *)oldSplitVersion:(NSString *)version
{
    NSString *character;
    NSMutableString *s;
    int i, n, oldType, newType;
    NSMutableArray *parts = [NSMutableArray array];
    if ([version length] == 0) {
        // Nothing to do here
        return parts;
    }
    s = [[[version substringToIndex:1] mutableCopy] autorelease];
    oldType = [self getCharType:s];
    n = [version length] - 1;
    for (i = 1; i <= n; ++i) {
        character = [version substringWithRange:NSMakeRange(i, 1)];
        newType = [self getCharType:character];
        if (oldType != newType || oldType == kPeriodType) {
            // We've reached a new segment
			NSString* sCopy = [s copy];
            [parts addObject:sCopy];
			[sCopy release];
            [s setString:character];
        } else {
            // Add character to string and continue
            [s appendString:character];
        }
        oldType = newType;
    }
    
    // Add the last part onto the array
    [parts addObject:[s copy]];
    return parts;
}*/

- (int)getCharType:(NSString *)character
{
    if ([character isEqualToString:@"."]) {
        return kPeriodType;
    } else if ([character isEqualToString:@"0"] || [character intValue] != 0) {
        return kNumberType;
    } else {
        return kStringType;
    }
}


#pragma mark - AppleScript stuff

//@interface NSObject(NSApplicationScriptingDelegation)
//
//// Return YES if the receiving delegate object can respond to key value coding messages for a specific keyed attribute, to-one relationship, or to-many relationship.  Return NO otherwise.
//- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;
//
//@end

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;
{
//	NSLog(@"delegateHandlesKey %@", key);
    if ([key isEqual:@"lockToggle"]) {
        return YES;
    } else {
        return NO;
    }
}


@end
