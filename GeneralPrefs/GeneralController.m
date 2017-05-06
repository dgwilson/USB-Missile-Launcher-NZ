#import "GeneralController.h"

@implementation GeneralController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[GeneralController alloc] init], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"GeneralPaneView" owner:self];
		[self loadPrefsValues];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"General";
}


- (NSImage *)paneIcon
{
    return [[NSImage alloc] initWithContentsOfFile: [[NSBundle bundleForClass:[self class]] pathForImageResource:@"GeneralPrefs"]];
}


- (NSString *)paneToolTip
{
    return @"General Preferences";
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
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    
	[prefs setFloat:[autoLockInterval floatValue] forKey:@"autoLockInterval"];
	[prefs setBool:[cameraDisabled state] forKey:@"cameraDisabled"];
	[prefs setBool:[reverseArrowKeys state] forKey:@"reverseArrowKeys"];
	[prefs setBool:[debugCommands state] forKey:@"debugCommands"];
    [prefs synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"PrefsChanged" object: nil];
}

- (IBAction)revertPrefs:(id)sender
{
    [self loadPrefsValues];
}

- (void)loadPrefsValues
{
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	
    [autoLockInterval setFloatValue:[prefs floatForKey:@"autoLockInterval"]];
	[cameraDisabled setState:[prefs floatForKey:@"cameraDisabled"]];
	[reverseArrowKeys setState:[prefs floatForKey:@"reverseArrowKeys"]];
	[debugCommands setState:[prefs floatForKey:@"debugCommands"]];

}


@end
