/* AppController */

#import <Cocoa/Cocoa.h>
#import "SS_PrefsController.h"
#import "AboutWindowController.h"
//#import "FeedbackWindowController.h"
#import "AVRecorderDocument.h"

@interface AppController : NSObject
{
	AboutWindowController * aboutWindowController;
//	FeedbackWindowController * feedbackWindowController;
    SS_PrefsController			*prefs;
	
	AVRecorderDocument *			videoDocument;
	NSTextField *		mCaptureToField;
	NSTextField *		mMessagesField;
	NSButton	*	videoWindowButton;
	bool						bVideoAdded;
}

@property (nonatomic, retain) AVRecorderDocument *			videoDocument;
@property (nonatomic, retain) IBOutlet NSButton	*	videoWindowButton;
@property (nonatomic, retain) IBOutlet NSTextField *		mCaptureToField;
@property (nonatomic, retain) IBOutlet NSTextField *		mMessagesField;

- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;

- (IBAction)showDeveloperMessage:(id)sender;
- (IBAction)showPrefs:(id)sender;
- (void)setDreamCheekyIcon:(id)sender;
- (void)setMissileLauncherIcon:(id)sender;

- (BOOL)isHostReachable;
- (IBAction)checkForUpdates:(id)sender;
- (void)checkVersion:(BOOL)quiet;
- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB;
- (NSArray *)splitVersion:(NSString *)version;
- (int)getCharType:(NSString *)character;

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key;

@end
