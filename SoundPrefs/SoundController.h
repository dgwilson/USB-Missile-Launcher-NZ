#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface SoundController : NSObject <SS_PreferencePaneProtocol> {

	BOOL				soundStatus;
	NSString			*myPath;
	
    IBOutlet NSView *prefsView;
	IBOutlet NSTextField *launchSoundPath;
	IBOutlet NSTextField *klaxonSoundPath;
	IBOutlet id soundOn;
	IBOutlet id soundOff;

}

- (IBAction)applyPrefs:(id)sender;
- (IBAction)revertPrefs:(id)sender;
- (IBAction)defaultPrefs:(id)sender;
- (IBAction)findLaunchSound:(id)sender;
- (IBAction)findWarningKlaxon:(id)sender;
- (IBAction)playLaunch:(id)sender;
- (IBAction)playKlaxon:(id)sender;
- (void)loadPrefsValues;

- (void)DGWlaunchPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)DGWklaxonPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end
