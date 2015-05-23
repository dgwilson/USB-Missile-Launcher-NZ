//
//  FeedbackWindow.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 23/10/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

#import "FeedbackWindowController.h"
#import <CoreServices/CoreServices.h>
#import "Message/NSMailDelivery.h"
#import "ShellTask.h"
#import "Mail.h"

@implementation FeedbackWindowController

@synthesize feedbackField;
@synthesize sendUSBCheckBox;
@synthesize USBProgressIndicator;
@synthesize sendOSCheckBox;
@synthesize OSProgressIndicator;
@synthesize USBComplete;
@synthesize SystemProfilerComplete;
@synthesize sendButton;

- (id)init 
{	
//	NSLog(@"%@ - FeedbackWindowController", NSStringFromSelector(_cmd));

	if ( ! (self = [super initWithWindowNibName: @"FeedbackWindow"]) ) {
		NSLog(@"init failed in FeedbackWindow");
		return nil;
	} // end if
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)windowDidLoad
{
	[self getUSBdetails];
	[self getOSDetails];
}

- (void)showHideSendButton
{
	if (getUSBBOOL && getSystemProfilerBOOL)
	{
		// enable send button
		[sendButton setEnabled:TRUE];
	}
	else
	{
		// disable send button
		[sendButton setEnabled:FALSE];
	}
}

- (BOOL)windowShouldClose:(id)sender;
{
	// do nothing, just want to see if this is called
	//NSLog(@"Feedback Window - windowShouldClose:");
	return YES;
}

- (IBAction)cancel_Button:(id)sender;
{
	//NSLog(@"Feedback Window - Cancel Button");
	//NSWindow *USBLauncherMainWindow = [mAddVideoButton window];
	//[[self window] performClose:sender];
	NSWindow* keyWindow = [NSApp keyWindow];
	[keyWindow orderOut:sender];
}

/* Part of the SBApplicationDelegate protocol.  Called when an error occurs in
 Scripting Bridge method. */
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    [[NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil
         informativeTextWithFormat: @"%@", [error localizedDescription]] runModal];
    return nil;
}

- (IBAction)send_Button:(id)sender;
{
	//NSLog(@"Feedback Window - Send Button");
	
	NSString *	currVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString *	appName           = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleExecutable"];
	NSString *  toMailAddress	  = @"dgwilson@paradise.net.nz";
	NSMutableString  * theBody	  = [[[NSMutableString alloc] initWithString:[feedbackField string]] autorelease];
	NSMutableString  * theSubject = [[[NSMutableString alloc] initWithString:@"Feedback: "] autorelease];
	
	[theSubject appendString:appName];					// add application name
	[theSubject appendString:@" "];
	[theSubject appendString:currVersionNumber];		// add application version
	NSLog(@"E-Mail sent with Subject: %@", theSubject);

	
	MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
	
	/* set ourself as the delegate to receive any errors */
    mail.delegate = self;
	
	/* create a new outgoing message object */
    MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
										 [NSDictionary dictionaryWithObjectsAndKeys:
										  theSubject, @"subject",
										  theBody, @"content",
										  nil]];
	
	/* Handle a nil value gracefully. */
    if(!emailMessage)
        return;
	
	/* add the object to the mail app  */
    [[mail outgoingMessages] addObject: emailMessage];
	
	/* set the sender, show the message */
	//    emailMessage.sender = [self.fromField stringValue];
    emailMessage.visible = YES;
	
	/* create a new recipient and add it to the recipients list */
    MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
									 [NSDictionary dictionaryWithObjectsAndKeys:
									  toMailAddress, @"address",
									  nil]];
	/* Handle a nil value gracefully. */
    if(!theRecipient) {
		[emailMessage release];
        return;
	}
    [emailMessage.toRecipients addObject: theRecipient];
    [theRecipient release];
	
	/* add an attachment, if one was specified */
	if ([sendUSBCheckBox state] && getUSBBOOL)
	{
		NSString *attachmentFilePath = ioregZipPath; //ioregFilePath;
		if ( [attachmentFilePath length] > 0 ) {
			MailAttachment *theAttachment;
			
			/* In Snow Leopard, the fileName property requires an NSString representing the path to the 
			 * attachment.  In Lion, the property has been changed to require an NSURL.   */
			SInt32 osxMinorVersion;
			Gestalt(gestaltSystemVersionMinor, &osxMinorVersion);
			
			/* create an attachment object */
			if(osxMinorVersion >= 7)
				theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
								 [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSURL URLWithString:attachmentFilePath], @"fileName",
								  nil]];
			else
			/* The string we read from the text field is a URL so we must create an NSURL instance with it
			 * and retrieve the old style file path from the NSURL instance. */
				theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
								 [NSDictionary dictionaryWithObjectsAndKeys:
								  [[NSURL URLWithString:attachmentFilePath] path], @"fileName",
								  nil]];
			
			/* Handle a nil value gracefully. */
			if(!theAttachment)
				return;
			
			/* add it to the list of attachments */
			[[emailMessage.content attachments] addObject: theAttachment];
			
			[theAttachment release];
			[ioregFilePath release];
			[ioregZipPath release];
		}
	}
	
	if ([sendOSCheckBox state] && getSystemProfilerBOOL)
	{
		NSString *attachmentFilePath = systemProfilerZipPath; //outFile;
		if ( [attachmentFilePath length] > 0 ) {
			MailAttachment *theAttachment;
			
			/* In Snow Leopard, the fileName property requires an NSString representing the path to the 
			 * attachment.  In Lion, the property has been changed to require an NSURL.   */
			SInt32 osxMinorVersion;
			Gestalt(gestaltSystemVersionMinor, &osxMinorVersion);
			
			/* create an attachment object */
			if(osxMinorVersion >= 7)
				theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
								 [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSURL URLWithString:attachmentFilePath], @"fileName",
								  nil]];
			else
			/* The string we read from the text field is a URL so we must create an NSURL instance with it
			 * and retrieve the old style file path from the NSURL instance. */
				theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
								 [NSDictionary dictionaryWithObjectsAndKeys:
								  [[NSURL URLWithString:attachmentFilePath] path], @"fileName",
								  nil]];
			
			/* Handle a nil value gracefully. */
			if(!theAttachment)
				return;
			
			/* add it to the list of attachments */
			[[emailMessage.content attachments] addObject: theAttachment];
			
			[theAttachment release];
			[outFile release];
			[systemProfilerZipPath release];
		}	
	}


	/* send the message */
    [emailMessage send];
	
    [emailMessage release];

	NSRunAlertPanel(appName, 
					@"Your feedback has been sent to the author.\nFeedback is appreciated.\nThank you", nil, nil, nil);
	
	

//		if(toMailAdd && theSubject && theBody)
//		{
//			NS_DURING
//				if([NSMailDelivery deliverMessage:theBody subject:theSubject to:toMailAdd])
//				{
//					result = YES;
//					NSRunAlertPanel(@"USB Missile Launcher NZ", 
//									@"Your feedback has been sent to the author. Feedback is appreciated. Thank you", nil, nil, nil);
//				}
//			NS_HANDLER
//				NSLog(@"NSMailDelivery: an exception was raised: %@",[localException reason]);
//				NSRunAlertPanel(@"USB Missile Launcher NZ", 
//								@"Unable to send e-mail, Apple mail may not be configured?", nil, nil, nil);
//
//			NS_ENDHANDLER
//		}
			
	NSWindow* keyWindow = [NSApp keyWindow];
	[keyWindow orderOut:sender];

}

- (NSString *)zipFile:(NSString *)inFile
{
	// returns output filename
	NSMutableString * zipCommand = [[[NSMutableString alloc] initWithString:@"zip -r "] autorelease];
	NSString * inFileZipPathtemp = [inFile stringByDeletingPathExtension];
	NSString * inFileZipPath = [inFileZipPathtemp stringByAppendingPathExtension:@"zip"];
	[zipCommand appendString:inFileZipPath];
	[zipCommand appendString:@" "];
	[zipCommand appendString:inFile];
	[ShellTask executeShellCommandSynchronously:zipCommand];

	return inFileZipPath;	// this object is retained - you must released when finished with
}

- (void)getUSBdetails
{
	// ioreg
	
	getUSBBOOL = FALSE;
	[USBComplete setStringValue:@"in progress"];
	[USBProgressIndicator startAnimation:self];
	[self showHideSendButton];

	NSString * ioregString = [ShellTask executeShellCommandSynchronously:@"ioreg -l -w 0"];
	//	NSLog(@"%@ ioreg results = %@", NSStringFromSelector(_cmd), ioregString);
	
	ioregFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat: @"ioreg-%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"txt"]] retain];
	NSLog(@"%@ ioregFilePath = %@", NSStringFromSelector(_cmd), ioregFilePath);
	NSError * error;
	NSURL * ioregURL = [NSURL fileURLWithPath:ioregFilePath isDirectory:NO];
	[ioregString writeToURL:ioregURL atomically:NO encoding:NSUnicodeStringEncoding error:&error];

	ioregZipPath = [self zipFile:ioregFilePath];
	
	getUSBBOOL = TRUE;
	[USBComplete setStringValue:@"Complete"];
	[USBProgressIndicator stopAnimation:self];
	[self showHideSendButton];
}

- (void)getOSDetails
{
	// System Profiler !!!

	getSystemProfilerBOOL = FALSE;
	[SystemProfilerComplete setStringValue:@"in progress"];
	[OSProgressIndicator startAnimation:self];
	[self showHideSendButton];

	NSTask *task = [[[NSTask alloc] init] autorelease]; 
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(taskFinished:)
												 name:NSTaskDidTerminateNotification 
											   object:task];
	
    [task setLaunchPath: @"/bin/sh"]; //we are launching sh, it is wha will process command for us
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]]; //stdin is directed to /dev/null
	
	
	NSArray	*args = [NSArray arrayWithObjects:	@"-l", // -l (lowercase L) tells it to “act as if it had been invoked as a login shell”
					 @"-c", //-c tells sh to execute commands from the next argument
					 @"system_profiler -xml -detaillevel full", //sh will read and execute the commands in this string.
					 nil];
    [task setArguments: args];

	outFile = [[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"SystemProfiler-%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"spx"]] retain];
	NSLog(@"%@ OutputFilePath = %@", NSStringFromSelector(_cmd), outFile);
	[[NSFileManager defaultManager] createFileAtPath:outFile
											contents:nil
										  attributes: nil];
	NSFileHandle * profilerFile = [NSFileHandle fileHandleForWritingAtPath:outFile];
	[task setStandardOutput:profilerFile];
	[task launch];
}

- (IBAction)checkedUSBDetails:(id)sender
{
	if ([sendUSBCheckBox state])
	{
		[self getUSBdetails];
	}
}

- (IBAction)checkedSystemProfilerDetails:(id)sender
{
	if ([sendOSCheckBox state])
	{
		[self getOSDetails];
	}
}

- (void)taskFinished:(NSNotification *)notification
{
	NSLog(@"%@ - task completed for System_Profiler", NSStringFromSelector(_cmd));
	
	systemProfilerZipPath = [self zipFile:outFile];

	getSystemProfilerBOOL = TRUE;
	[SystemProfilerComplete setStringValue:@"Complete"];
	[OSProgressIndicator stopAnimation:self];
	[self showHideSendButton];
}


//- (IBAction)send_Button:(id)sender;
//{
//	//NSLog(@"Feedback Window - Send Button");
//	if([NSMailDelivery hasDeliveryClassBeenConfigured])
//	{
//		
//		BOOL		result;
//		//NSString *	senderMailAdd	= @"";
//		NSString *	currVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
//		NSString *	appName           = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleExecutable"];
//		NSString *  toMailAdd		  = @"dgwilson@paradise.net.nz";
//		NSMutableString  * theBody	  = [[[NSMutableString alloc] initWithString:[feedbackField string]] autorelease];
//		NSMutableString  * theSubject = [[[NSMutableString alloc] initWithString:@"Feedback: "] autorelease];
//		
//		[theSubject appendString:appName];					// add application name
//		[theSubject appendString:@" "];
//		[theSubject appendString:currVersionNumber];		// add application version
//		NSLog(@"E-Mail sent with Subject: %@", theSubject);
//		
//		if ([sendUSBCheckBox state] && getUSBBOOL)
//		{
//			// include details in the e-mail
//			
//			[theBody appendString:@"\n\n\n"];
//			[theBody appendString:ioregString];
//			[theBody appendString:@"\n\n\n"];
//			
//		}
//		
//		if ([sendOSCheckBox state] && getSystemProfilerBOOL)
//		{
//			// include details in the e-mail			
//		}
//		
//		
//		if(toMailAdd && theSubject && theBody)
//		{
//			NS_DURING
//			if([NSMailDelivery deliverMessage:theBody subject:theSubject to:toMailAdd])
//			{
//				result = YES;
//				NSRunAlertPanel(@"USB Missile Launcher NZ", 
//								@"Your feedback has been sent to the author. Feedback is appreciated. Thank you", nil, nil, nil);
//			}
//			NS_HANDLER
//			NSLog(@"NSMailDelivery: an exception was raised: %@",[localException reason]);
//			NSRunAlertPanel(@"USB Missile Launcher NZ", 
//							@"Unable to send e-mail, Apple mail may not be configured?", nil, nil, nil);
//			
//			NS_ENDHANDLER
//		}
//	}
//	
//	NSWindow* keyWindow = [NSApp keyWindow];
//	[keyWindow orderOut:sender];
//	
//}

//- (IBAction)sendMailCocoa:(id)sender
//// Create a mail message in the user's preferred mail client
//// by opening a mailto URL.  The extended mailto URL format
//// is documented by RFC 2368 and is supported by Mail.app
//// and other modern mail clients.
////
//// This routine's prototype makes it easy to connect it as
//// the action of a user interface object in Interface Builder.
//{
//    NSURL *     url;
//	
//    // Create the URL.
//	
//    url = [NSURL URLWithString:@"mailto:dts@apple.com"
//		   "?subject=Hello%20Cruel%20World!"
//		   "&body=Share%20and%20Enjoy"
//		   ];
//    assert(url != nil);
//	
//    // Open the URL.
//	
//    (void) [[NSWorkspace sharedWorkspace] openURL:url];
//}

/*
 
    NSAttributedString * htmlString = [NSAttributedString alloc];
    NSMutableDictionary * headers = [[NSMutableDictionary alloc] init];

    [htmlString initWithString: [NSString stringWithContentsOfFile: @"index.html"]];

    [headers setObject: @"user@org.com"
                forKey: @"To"];
    [headers setObject: @"HTML Email"
                forKey: @"Subject"];
    [headers setObject: @"Sat, 30 Jul 2005 20:00:00 -0600 (MDT)"
                forKey: @"Date"];
    [headers setObject: @"text/html"
                forKey: @"Content-type"];

    BOOL sent = [NSMailDelivery deliverMessage: htmlString
                                       headers: headers
                                        format: NSMIMEMailFormat
                                      protocol: nil];

*/ 


// http://vafer.org/blog/20080604120118/
// With 10.5 Apple deprecated the use of NSMailDelivery – without a replacement. So the questions comes up regulary – how does one send emails from Cocoa? Turns out there are couple of frameworks available that can also be used to do the job.

@end
