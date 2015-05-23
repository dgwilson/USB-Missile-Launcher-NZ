//
//  FeedbackWindow.h
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 23/10/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ScriptingBridge/ScriptingBridge.h>

@interface FeedbackWindowController : NSWindowController<SBApplicationDelegate> {

	NSTextView	* feedbackField;
	NSButton * sendUSBCheckBox;
	NSProgressIndicator * USBProgressIndicator;
	NSButton * sendOSCheckBox;
	NSProgressIndicator * OSProgressIndicator;
	
	NSString * outFile;
	NSString * systemProfilerZipPath;
	NSString * ioregFilePath;
	NSString * ioregZipPath;
	
	BOOL getUSBBOOL;
	BOOL getSystemProfilerBOOL;
	
	NSTextField * USBComplete;
	NSTextField * SystemProfilerComplete;
	
	NSButton * sendButton;
}

@property (nonatomic, retain) IBOutlet NSTextView	* feedbackField;
@property (nonatomic, retain) IBOutlet NSButton * sendUSBCheckBox;
@property (nonatomic, retain) IBOutlet NSProgressIndicator * USBProgressIndicator;
@property (nonatomic, retain) IBOutlet NSButton * sendOSCheckBox;
@property (nonatomic, retain) IBOutlet NSProgressIndicator * OSProgressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField * USBComplete;
@property (nonatomic, retain) IBOutlet NSTextField * SystemProfilerComplete;
@property (nonatomic, retain) IBOutlet NSButton * sendButton;

- (IBAction)cancel_Button:(id)sender;
- (IBAction)send_Button:(id)sender;

- (void)getUSBdetails;
- (void)getOSDetails;

@end
