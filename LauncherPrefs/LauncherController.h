#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface LauncherController : NSObject <SS_PreferencePaneProtocol> {

    IBOutlet id					launcher1_VendorId;
	IBOutlet id					launcher1_ProductId;
	IBOutlet NSPopUpButton *	launcher1_type;
	IBOutlet id					launcher2_VendorId;
	IBOutlet id					launcher2_ProductId;
	IBOutlet NSPopUpButton *	launcher2_type;
	IBOutlet id					launcher3_VendorId;
	IBOutlet id					launcher3_ProductId;
	IBOutlet NSPopUpButton *	launcher3_type;
	
	IBOutlet NSView *prefsView;
}

- (IBAction)defaultPrefs:(id)sender;
- (IBAction)applyPrefs:(id)sender;
- (IBAction)revertPrefs:(id)sender;
- (void)loadPrefsValues;
	
@end
