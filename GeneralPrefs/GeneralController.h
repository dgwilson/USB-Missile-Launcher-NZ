#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface GeneralController : NSObject <SS_PreferencePaneProtocol> {

    IBOutlet id autoLockInterval;
	IBOutlet id cameraDisabled;
	IBOutlet id reverseArrowKeys;
	IBOutlet id debugCommands;
	IBOutlet NSView *prefsView;
}

- (IBAction)applyPrefs:(id)sender;
- (IBAction)revertPrefs:(id)sender;
- (void)loadPrefsValues;
	
@end
