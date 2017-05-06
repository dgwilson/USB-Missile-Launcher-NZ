#import "JoystickController.h"

@implementation JoystickController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[JoystickController alloc] init], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"JoystickPaneView" owner:self];
		[self loadPrefsValues];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneName
{
    return @"Joystick";
}


- (NSImage *)paneIcon
{
    return [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"JoystickPrefs"]];
}


- (NSString *)paneToolTip
{
    return @"Joystick Preferences";
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
    
	// preference options
	//   +/- 5 = joystick sensitity
	//   maybe button position for different joysticks
	//   reverse xaxis
	//   reverse yaxis
	
	[prefs setFloat:[joystickSensitivity floatValue] forKey:@"joystickSensitivity"];
	[prefs setFloat:[joystickFireButtonMatrix selectedRow] forKey:@"joystickFireButtonMatrix"];
	[prefs setBool:[reverseXAxis state] forKey:@"reverseXAxis"];
	[prefs setBool:[reverseYAxis state] forKey:@"reverseYAxis"];
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
	
    [joystickSensitivity setFloatValue:[prefs floatForKey:@"joystickSensitivity"]];
	[joystickFireButtonMatrix selectCellAtRow:[prefs floatForKey:@"joystickFireButtonMatrix"] column:0];
	[reverseXAxis setState:[prefs floatForKey:@"reverseXAxis"]];
	[reverseYAxis setState:[prefs floatForKey:@"reverseYAxis"]];

}


@end
