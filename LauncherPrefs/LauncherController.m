#import "LauncherController.h"

@implementation LauncherController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[LauncherController alloc] init] autorelease], nil];
	
}


- (NSView *)paneView
{
    BOOL loaded = YES;

    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"LauncherPaneView" owner:self];
		[self loadPrefsValues];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Launcher";
}


- (NSImage *)paneIcon
{
    return [[[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForImageResource:@"LauncherPrefs"]] autorelease];
}


- (NSString *)paneToolTip
{
    return @"Launcher Preferences";
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}

- (IBAction)defaultPrefs:(id)sender;
{
	NSUserDefaults* prefs = [[NSUserDefaults standardUserDefaults] retain];

    //USB Missile Launcher - Original Launcher - also code for the Striker II (includes the Laser)
	// #define kUSBMissileVendorID		0x1130	4400
	// #define kUSBMissileProductID		0x0202	514
	[prefs setObject:@"4400" forKey:@"launcher1_VendorId"];
	[prefs setObject:@"514" forKey:@"launcher1_ProductId"];
	[prefs setObject:@"OrigLauncher" forKey:@"launcher1_type"];

	//USB Rocket Launcher c/- ThinkGeek - DreamCheeky
	// #define kUSBRocketVendorID		0x1941	6465
	// #define kUSBRocketProductID		0x8021	32801
	[prefs setObject:@"6465" forKey:@"launcher2_VendorId"];
	[prefs setObject:@"32801" forKey:@"launcher2_ProductId"];
	[prefs setObject:@"DreamRocket" forKey:@"launcher2_type"];

	//USB Rocket Launcher c/- DreamCheeky - DreamRocketII (aka RocketBaby)
	//#define kUSBRocketBabyVendorID	0xa81	// 2689
	//#define kUSBRocketBabyProductID	0x701	// 1793
	[prefs setObject:@"2689" forKey:@"launcher3_VendorId"];
	[prefs setObject:@"1793" forKey:@"launcher3_ProductId"];
	[prefs setObject:@"DreamRocketII" forKey:@"launcher3_type"];
	
    [prefs synchronize];
	[prefs release];
    [self loadPrefsValues];
	
    [[NSNotificationCenter defaultCenter] postNotificationName: @"PrefsChanged" object: nil];
	
}

- (IBAction)applyPrefs:(id)sender
{
	NSUserDefaults* prefs = [[NSUserDefaults standardUserDefaults] retain];
    
	[prefs setObject:[launcher1_VendorId stringValue] forKey:@"launcher1_VendorId"];
	[prefs setObject:[launcher1_ProductId stringValue] forKey:@"launcher1_ProductId"];
	[prefs setObject:[launcher1_type titleOfSelectedItem] forKey:@"launcher1_type"];
	
	[prefs setObject:[launcher2_VendorId stringValue] forKey:@"launcher2_VendorId"];
	[prefs setObject:[launcher2_ProductId stringValue] forKey:@"launcher2_ProductId"];
	[prefs setObject:[launcher2_type titleOfSelectedItem] forKey:@"launcher2_type"];
	
	[prefs setObject:[launcher3_VendorId stringValue] forKey:@"launcher3_VendorId"];
	[prefs setObject:[launcher3_ProductId stringValue] forKey:@"launcher3_ProductId"];
	[prefs setObject:[launcher3_type titleOfSelectedItem] forKey:@"launcher3_type"];
	
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
	// NSPopUpButton - needs to be loaded and this seems like a good place to do it
	// [launcher1_type addItemWithTitle:@"xx"]
	
	NSArray * itemTitles;
	itemTitles = [NSArray arrayWithObjects:@"OrigLauncher", @"DreamRocket", @"StrikerII", @"DreamRocketII", @"OICStorm", @"Satzuma", @"c-enter", @"unknown", nil];
	[launcher1_type removeAllItems];
	[launcher1_type addItemsWithTitles:itemTitles];
	[launcher2_type removeAllItems];
	[launcher2_type addItemsWithTitles:itemTitles];
	[launcher3_type removeAllItems];
	[launcher3_type addItemsWithTitles:itemTitles];
	
	
	
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];

	[launcher1_VendorId setStringValue:[prefs stringForKey:@"launcher1_VendorId"]];
	[launcher1_ProductId setStringValue:[prefs stringForKey:@"launcher1_ProductId"]];
	[launcher1_type selectItemWithTitle:[prefs stringForKey:@"launcher1_type"]];

	[launcher2_VendorId setStringValue:[prefs stringForKey:@"launcher2_VendorId"]];
	[launcher2_ProductId setStringValue:[prefs stringForKey:@"launcher2_ProductId"]];
	[launcher2_type selectItemWithTitle:[prefs stringForKey:@"launcher2_type"]];

	[launcher3_VendorId setStringValue:[prefs stringForKey:@"launcher3_VendorId"]];
	[launcher3_ProductId setStringValue:[prefs stringForKey:@"launcher3_ProductId"]];
	[launcher3_type selectItemWithTitle:[prefs stringForKey:@"launcher3_type"]];

}


@end
