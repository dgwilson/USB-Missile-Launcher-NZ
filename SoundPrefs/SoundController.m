#import "SoundController.h"

@implementation SoundController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[SoundController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"SoundPaneView" owner:self];
		[self loadPrefsValues];
    }
    
    if (loaded) {
		//configW = prefsView;
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Sound";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"SoundPrefs"]] autorelease];
}


- (NSString *)paneToolTip
{
    return @"Sound Preferences";
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}

- (IBAction)applyPrefs:(id)sender
{
	NSUserDefaults* prefs = [[NSUserDefaults standardUserDefaults] retain];
    
	//[prefs setFloat:[autoLockInterval floatValue] forKey:@"autoLockInterval"];
	[prefs setBool:[soundOn state] forKey:@"soundOn"];
	[prefs setObject:[launchSoundPath stringValue] forKey:@"launchSound"];
	[prefs setObject:[klaxonSoundPath stringValue] forKey:@"klaxonSound"];

    [prefs synchronize];
	[prefs release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"PrefsChanged" object: nil];
}

- (IBAction)revertPrefs:(id)sender
{
    [self loadPrefsValues];
}

- (void)loadPrefsValues
{
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	
	if ([prefs boolForKey:@"soundOn"])
	{
		[soundOn  setState:YES];
		[soundOff setState:NO];
	} else
	{
		[soundOn  setState:NO];
		[soundOff setState:YES];
	}

	//[launchSoundPath setStringValue:@"noValue set by me"];
	//[klaxonSoundPath setStringValue:@"noValue set by me"];

	[launchSoundPath setStringValue:[prefs stringForKey:@"launchSound"]];
	[klaxonSoundPath setStringValue:[prefs stringForKey:@"klaxonSound"]];
	
	//NSLog(@"loadPrefsValues - %@", [launchSoundPath stringValue]);
	//NSLog(@"loadPrefsValues - %@", [klaxonSoundPath stringValue]);
		
}

- (IBAction)defaultPrefs:(id)sender;
{
	NSUserDefaults* prefs = [[NSUserDefaults standardUserDefaults] retain];
    
	//[prefs setFloat:[autoLockInterval floatValue] forKey:@"autoLockInterval"];
	[prefs setBool:TRUE forKey:@"soundOn"];
	[prefs setObject:@"" forKey:@"launchSound"];
	[prefs setObject:@"" forKey:@"klaxonSound"];
	
    [prefs synchronize];
	[prefs release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"PrefsChanged" object: nil];
	
	[self loadPrefsValues];
	
}
- (IBAction)findLaunchSound:(id)sender;
{
	//NSLog(@"findLaunchSound button pressed");
	
	//Presents a sheet Open panel on a given window, docWindow. The receiver displays the files 
	//in directory (an absolute directory path), and allows selection of ones that match the types 
	//in fileTypes (an NSArray of file extensions and/or HFS file types). If directory is nil the 
	//directory is the same directory used in the previous invocation of the panel. 
	//Passing nil for directory is probably the best choice for most situations. 
	//If all files in a directory should be selectable in the browser, fileTypes should be nil. 
	//The filename argument specifies a particular file in directory that is selected 
	//when the Open panel is presented to the user; otherwise, filename should be nil. 
	//When the modal session is ended, didEndSelector is invoked on the modalDelegate, 
	//passing contextInfo as an argument. modalDelegate is not the same as a delegate assigned to the panel. 
	//Modal delegates in sheets are temporary and the relationship only lasts until the sheet is dismissed
	
	//didEndSelector should have the following signature:
	//- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
	//The value passed as returnCode will be either NSCancelButton or NSOKButton.
	
	NSMutableArray * fileTypes = [[NSMutableArray alloc] init];
	//[fileTypes addObject:@"snd"];
	[fileTypes addObject:@"wav"];
	[fileTypes addObject:@"aiff"];
	[fileTypes addObject:@"aif"];
	[fileTypes addObject:@"mp3"];
	[fileTypes addObject:@"m4a"];
	[fileTypes addObject:@"m4v"];
		
	NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
	[openPanel setFloatingPanel:YES];
	[openPanel setAllowsMultipleSelection:NO];

	[openPanel beginForDirectory:nil
							file:nil
						   types:fileTypes
				//modalForWindow:configW
				modelessDelegate:self
				  didEndSelector:@selector(DGWlaunchPanelDidEnd:returnCode:contextInfo:)
					 contextInfo:nil];
	
	//NSLog(@"findLaunchSound returned from file dialog box");
	return;
}

- (IBAction)findWarningKlaxon:(id)sender;
{
	//NSLog(@"findLaunchSound button pressed");
	
	//Presents a sheet Open panel on a given window, docWindow. The receiver displays the files 
	//in directory (an absolute directory path), and allows selection of ones that match the types 
	//in fileTypes (an NSArray of file extensions and/or HFS file types). If directory is nil the 
	//directory is the same directory used in the previous invocation of the panel. 
	//Passing nil for directory is probably the best choice for most situations. 
	//If all files in a directory should be selectable in the browser, fileTypes should be nil. 
	//The filename argument specifies a particular file in directory that is selected 
	//when the Open panel is presented to the user; otherwise, filename should be nil. 
	//When the modal session is ended, didEndSelector is invoked on the modalDelegate, 
	//passing contextInfo as an argument. modalDelegate is not the same as a delegate assigned to the panel. 
	//Modal delegates in sheets are temporary and the relationship only lasts until the sheet is dismissed
	
	//didEndSelector should have the following signature:
	//- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
	//The value passed as returnCode will be either NSCancelButton or NSOKButton.
	
	NSMutableArray * fileTypes = [[NSMutableArray alloc] init];
	//[fileTypes addObject:@"snd"];
	[fileTypes addObject:@"wav"];
	[fileTypes addObject:@"aiff"];
	[fileTypes addObject:@"aif"];
	[fileTypes addObject:@"mp3"];
	[fileTypes addObject:@"m4a"];
	[fileTypes addObject:@"m4v"];
	
	NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
	[openPanel setFloatingPanel:YES];
	[openPanel setAllowsMultipleSelection:NO];

	[openPanel beginForDirectory:nil
							file:nil
						   types:fileTypes
				//modalForWindow:configW
				modelessDelegate:self
				  didEndSelector:@selector(DGWklaxonPanelDidEnd:returnCode:contextInfo:)
					 contextInfo:nil];
	
	//NSLog(@"findLaunchSound returned from file dialog box");
	return;
}

- (void)DGWlaunchPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	//NSLog(@"DGWlaunchPanelDidEnd - called");
	if (returnCode == NSOKButton) 
	{
		myPath = [[NSString alloc] init]; 
		myPath = [panel filename];
		myPath = [myPath stringByStandardizingPath];
		//NSLog(@"DGWlaunchPanelDidEnd - %@", myPath);

		[launchSoundPath setStringValue:myPath];
		//NSLog(@"DGWlaunchPanelDidEnd - %@", [launchSoundPath stringValue]);
	}
	return;
}

- (void)DGWklaxonPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	//NSLog(@"DGWklaxonPanelDidEnd - called");
	if (returnCode == NSOKButton) 
	{
		myPath = [[NSString alloc] init];
		myPath = [panel filename];
		myPath = [myPath stringByStandardizingPath];
		//NSLog(@"DGWklaxonPanelDidEnd - %@", myPath);
		
		[klaxonSoundPath setStringValue:myPath];
		//NSLog(@"DGWklaxonPanelDidEnd - %@", [klaxonSoundPath stringValue]);
	}
	return;
}

- (IBAction)playLaunch:(id)sender;
{
	NSSound		*launchSound;
	launchSound = [[NSSound alloc] initWithContentsOfFile:[launchSoundPath stringValue] byReference:NO];
	[launchSound play];
	[launchSound release];
}

- (IBAction)playKlaxon:(id)sender;
{
	NSSound		*klaxonSound;
	klaxonSound = [[NSSound alloc] initWithContentsOfFile:[klaxonSoundPath stringValue] byReference:NO];
	[klaxonSound play];
	[klaxonSound release];
}


@end
