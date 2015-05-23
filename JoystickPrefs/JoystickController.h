#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface JoystickController : NSObject <SS_PreferencePaneProtocol> {

    IBOutlet id joystickSensitivity;
	IBOutlet id joystickFireButtonMatrix;
	IBOutlet id reverseXAxis;
	IBOutlet id reverseYAxis;
	IBOutlet NSView *prefsView;
}

- (IBAction)applyPrefs:(id)sender;
- (IBAction)revertPrefs:(id)sender;
- (void)loadPrefsValues;
	
@end
