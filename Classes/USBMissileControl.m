//
//  MissileControl.m
//  USB Missile Launcher NZ
//
//  Created by David G. Wilson on 11/06/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

/*
 
FRIENDS to help Debug
---------------------
 
  ioreg -l -n IOUSBCompositeDr
  ioreg -l -n IOUSBCompositeDriver -w 0 > ~/Desktop/ioreg.txt
  ioreg -l -w 0 > ~/Desktop/ioreg.txt

 At 5:27 pm +1300 20/11/2007, David Wilson wrote:
 The error "kIOReturnExclusiveAccess" is generated.
 
 It is probably being grabbed by the HID manager, which is why I had to make that kext that was nothing but a plist file for the Jaycar launcher.
  
 Have them run ioreg from Terminal.
 
 This is the output with the Jaycar launcher without the kext, note how the IOUSBHIDDriver had hopped on to the IOUSBInterfaces of it.
 
 | |   |   +-o Tenx Nonstandard Devic@1d100000  <class IOUSBDevice, registered, matched, active, busy 0, retain 10>
 | |   |     +-o IOUSBCompositeDriver  <class IOUSBCompositeDriver, !registered, !matched, active, busy 0, retain 4>
 | |   |     +-o IOUSBInterface@0  <class IOUSBInterface, registered, matched, active, busy 0, retain 6>
 | |   |     | +-o IOUSBHIDDriver  <class IOUSBHIDDriver, registered, matched, active, busy 0, retain 7>
 | |   |     |   +-o IOHIDInterface  <class IOHIDInterface, registered, matched, active, busy 0, retain 5>
 | |   |     +-o IOUSBInterface@1  <class IOUSBInterface, registered, matched, active, busy 0, retain 6>
 | |   |       +-o IOUSBHIDDriver  <class IOUSBHIDDriver, registered, matched, active, busy 0, retain 7>
 | |   |         +-o IOHIDInterface  <class IOHIDInterface, registered, matched, active, busy 0, retain 5>
 

 sudo kextload -v 6 USB\ Missile\ Launcher\ All\ Drivers.kext/
 sudo kextutil -t -v 6 USB\ Missile\ Launcher\ All\ Drivers.kext/
 
 
-=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- 
 
 How to determine, from windows, what the launcher command sequences are:
 * this works in Parallels Desktop version 6 for Mac - with Windows XP
 * Connect your launcher and assign the device(s) [maybe launcher and camera] to Windows.
 * Install the manufacturers Windows software
 * run, test launcher
 
 
 * now use SnoopyPro http://sourceforge.net/projects/usbsnoop

 -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- -=* *=- 
 
 
*/

#import "USBMissileControl.h"

//================================================================================================
//   Globals
//================================================================================================
//
static IONotificationPortRef	gNotifyPort;
static io_iterator_t			gAddedRocketIter;
static io_iterator_t			gAddedMissileIter;
static CFRunLoopRef				gRunLoop;

int						launcherCount;
NSMutableArray			*launcherDevice;


//USB Missile Launcher
//#define kUSBMissileVendorID		0x1130	// 4400
//#define kUSBMissileProductID		0x0202	// 514

//USB Missile Launcher - Striker II
//#define kUSBMissileVendorID		0x1130	// 4400
//#define kUSBMissileProductID		0x0202	// 514

//USB Missile Launcher - Satzuma
//#define kUSBMissileVendorID		0x0416	// 1046
//#define kUSBMissileProductID		0x9391	// 37777

//USB Rocket Launcher c/- ThinkGeek
//#define kUSBRocketVendorID		0x1941	// 6465
//#define kUSBRocketProductID		0x8021	// 32801

static char							gBuffer[8];
#define dreamCheekyMaxPacketSize	8
#define rocketBabyMaxPacketSize		1
#define OICSTORMMaxPacketSize		2


@implementation USBMissileControl

- (id)init 
{
	kern_return_t			kr;
	mach_port_t				masterPort = 0;					// requires <mach/mach.h>
//	kern_return_t			err;
	CFMutableDictionaryRef 	matchingDictionary1 = 0;		// requires <IOKit/IOKitLib.h>
	CFMutableDictionaryRef 	matchingDictionary2 = 0;		// requires <IOKit/IOKitLib.h>
	CFMutableDictionaryRef 	matchingDictionary3 = 0;		// requires <IOKit/IOKitLib.h>
//	SInt32					usbRocketVendor    = kUSBRocketVendorID;
//	SInt32					usbRocketProduct   = kUSBRocketProductID;
//	SInt32					usbMissileVendor   = kUSBMissileVendorID;
//	SInt32					usbMissileProduct  = kUSBMissileProductID;
	CFNumberRef				numberRef;
	CFRunLoopSourceRef      runLoopSource;

	NSString * launcher1_VendorId;
	NSString * launcher1_ProductId;
	NSString * launcher2_VendorId;
	NSString * launcher2_ProductId;
	NSString * launcher3_VendorId;
	NSString * launcher3_ProductId;
	
	self = [super init];
	if (self) {
		// Inspiration at:
		// http://developer.apple.com/samplecode/USBPrivateDataSample/listing1.html
		//
		
		
		// OK, here we take a different track. I've built a preference screen that lets the user key their own
		// VendorID and ProductID. The idea here is meant to allow for the connection of new launchers.
		// Yup, it may not work, but perhaps it's worth a go.
		// DGW - 11 February 2007

	//	launcher1_VendorId = [[[NSString alloc] init] retain];

		NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
		launcher1_VendorId = [NSString stringWithString:[prefs stringForKey:@"launcher1_VendorId"]];
		launcher1_ProductId = [NSString stringWithString:[prefs stringForKey:@"launcher1_ProductId"]];

		launcher2_VendorId = [NSString stringWithString:[prefs stringForKey:@"launcher2_VendorId"]];
		launcher2_ProductId = [NSString stringWithString:[prefs stringForKey:@"launcher2_ProductId"]];

		launcher3_VendorId = [NSString stringWithString:[prefs stringForKey:@"launcher3_VendorId"]];
		launcher3_ProductId = [NSString stringWithString:[prefs stringForKey:@"launcher3_ProductId"]];

		
	//	SInt32					usbRocketVendor    = kUSBRocketVendorID;
	//	numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbRocketProduct);

		int launcher1_VendorId_num = [launcher1_VendorId intValue];
	//	NSLog(@"USBMissileControl: launcher1_VendorID_num = %i", launcher1_VendorId_num);
	//	numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher1_VendorId_num);

		int launcher1_ProductId_num = [launcher1_ProductId intValue];
	//	NSLog(@"USBMissileControl: launcher1_ProductID_num = %i", launcher1_ProductId_num);
	//	numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher1_ProductId_num);

	//	NSLog(@"USBMissileControl: launcher1_type = %@", launcher1_type);
			  
		int launcher2_VendorId_num = [launcher2_VendorId intValue];
	//	NSLog(@"USBMissileControl: launcher2_VendorID_num = %i", launcher2_VendorId_num);
	//	numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher2_VendorId_num);

		int launcher2_ProductId_num = [launcher2_ProductId intValue];
	//	NSLog(@"USBMissileControl: launcher2_ProductID_num = %i", launcher2_ProductId_num);
	//	numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher2_ProductId_num);

	//	NSLog(@"USBMissileControl: launcher2_type = %@", launcher2_type);

		int launcher3_VendorId_num = [launcher3_VendorId intValue];
	//	NSLog(@"USBMissileControl: launcher3_VendorID_num = %i", launcher3_VendorId_num);
	//	numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher3_VendorId_num);

		int launcher3_ProductId_num = [launcher3_ProductId intValue];
	//	NSLog(@"USBMissileControl: launcher3_ProductID_num = %i", launcher3_ProductId_num);
	//	numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher3_ProductId_num);

	//	NSLog(@"USBMissileControl: launcher3_type = %@", launcher3_type);

		
		launcherCount = 0;
		launcherDevice = [[[NSMutableArray alloc] init] retain];
	//	missileLauncherConnected = [self FindMissileLauncher];
		
		// set up USB detection code
		
		// First create a master_port for my task
		kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
		if (kr || !masterPort)
		{
			NSLog(@"USBMissileControl: could not create master port, err = %08x", kr);
			return NO;
		}
		//NSLog(@"Looking for devices matching vendor ID=%ld and product ID=%ld", usbVendor, usbProduct);

		// Set up the matching criteria for the devices we're interested in. The matching criteria needs to follow
		// the same rules as kernel drivers: mainly it needs to follow the USB Common Class Specification, pp. 6-7.
		// See also <http://developer.apple.com/qa/qa2001/qa1076.html>.
		// One exception is that you can use the matching dictionary "as is", i.e. without adding any matching 
		// criteria to it and it will match every IOUSBDevice in the system. IOServiceAddMatchingNotification will 
		// consume this dictionary reference, so there is no need to release it later on.
		
		gNotifyPort = IONotificationPortCreate(masterPort);
		runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
		
		gRunLoop = CFRunLoopGetCurrent();
		CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);
		
		// We are interested in all USB Devices (as opposed to USB interfaces).  The Common Class Specification
		// tells us that we need to specify the idVendor, idProduct, and bcdDevice fields, or, if we're not interested
		// in particular bcdDevices, just the idVendor and idProduct.  Note that if we were trying to match an 
		// IOUSBInterface, we would need to set more values in the matching dictionary (e.g. idVendor, idProduct, 
		// bInterfaceNumber and bConfigurationValue.
		//    
		
		matchingDictionary1 = IOServiceMatching(kIOUSBDeviceClassName);  // Interested in instances of class
																		// IOUSBDevice and its subclasses
																		// requires <IOKit/usb/IOUSBLib.h>
		
		// look up toll free bridge in apple documentation... 
		// discusses Core Foundation vs. Cocoa types that are interchangeable.
		
		if (matchingDictionary1)
		{
			//
			// Rocket Launcher
			//
			
			// Create a CFNumber for the idVendor and set the value in the dictionary
	//		numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbRocketVendor);
			numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher1_VendorId_num);
			if (!numberRef) {
				NSLog(@"USBMissileControl: could not create CFNumberRef for vendor");
			}
			CFDictionarySetValue(matchingDictionary1, CFSTR(kUSBVendorID), numberRef);
			CFRelease(numberRef);
			
			// Create a CFNumber for the idProduct and set the value in the dictionary
	//		numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbRocketProduct);
			numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher1_ProductId_num);
			CFDictionarySetValue(matchingDictionary1, CFSTR(kUSBProductID), numberRef);
			CFRelease(numberRef);
			//numberRef = 0;
			
			// Create a notification port and add its run loop event source to our run loop
			// This is how async notifications get set up.
			// Now set up a notification to be called when a device is first matched by I/O Kit.
	//		kr = IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
	//											  kIOFirstMatchNotification,  // notificationType
	//											  matchingDictionary1,        // matching
	//											  DeviceAdded,				  // callback
	//											  NULL,						  // refCon
	//											  &gAddedRocketIter			  // notification
	//											  );    
			IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
												  kIOFirstMatchNotification,  // notificationType
												  matchingDictionary1,        // matching
												  DeviceAdded,				  // callback
												  NULL,						  // refCon
												  &gAddedRocketIter			  // notification
												  );    
			
			// Iterate once to get already-present devices and arm the notification    
			DeviceAdded(NULL, gAddedRocketIter);  
			
			
			matchingDictionary2 = IOServiceMatching(kIOUSBDeviceClassName);  // Interested in instances of class
																			// IOUSBDevice and its subclasses
																			// requires <IOKit/usb/IOUSBLib.h>

		if (matchingDictionary2)
			{
				//
				// Missile Launcher
				//
				
				// Create a CFNumber for the idVendor and set the value in the dictionary
	//			numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbMissileVendor);
				numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher2_VendorId_num);
				if (!numberRef) {
					NSLog(@"USBMissileControl: could not create CFNumberRef for vendor");
				}
				CFDictionarySetValue(matchingDictionary2, CFSTR(kUSBVendorID), numberRef);
				CFRelease(numberRef);
				
				// Create a CFNumber for the idProduct and set the value in the dictionary
	//			numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbMissileProduct);
				numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher2_ProductId_num);
				CFDictionarySetValue(matchingDictionary2, CFSTR(kUSBProductID), numberRef);
				CFRelease(numberRef);
				//numberRef = 0;
				
				// Create a notification port and add its run loop event source to our run loop
				// This is how async notifications get set up.
				// Now set up a notification to be called when a device is first matched by I/O Kit.
	//			kr = IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
	//												  kIOFirstMatchNotification,  // notificationType
	//												  matchingDictionary2,        // matching
	//												  DeviceAdded,				  // callback
	//												  NULL,						  // refCon
	//												  &gAddedMissileIter		  // notification
	//												  );    
				IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
													  kIOFirstMatchNotification,  // notificationType
													  matchingDictionary2,        // matching
													  DeviceAdded,				  // callback
													  NULL,						  // refCon
													  &gAddedMissileIter		  // notification
													  );    
				
				// Iterate once to get already-present devices and arm the notification    
				DeviceAdded(NULL, gAddedMissileIter);  
				
				
				matchingDictionary3 = IOServiceMatching(kIOUSBDeviceClassName);  // Interested in instances of class
																				 // IOUSBDevice and its subclasses
																				 // requires <IOKit/usb/IOUSBLib.h>
				
				if (matchingDictionary3)
				{
					//
					// Missile Launcher
					//
					
					// Create a CFNumber for the idVendor and set the value in the dictionary
					//			numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbMissileVendor);
					numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher3_VendorId_num);
					if (!numberRef) {
						NSLog(@"USBMissileControl: could not create CFNumberRef for vendor");
					}
					CFDictionarySetValue(matchingDictionary3, CFSTR(kUSBVendorID), numberRef);
					CFRelease(numberRef);
					
					// Create a CFNumber for the idProduct and set the value in the dictionary
					//			numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbMissileProduct);
					numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &launcher3_ProductId_num);
					CFDictionarySetValue(matchingDictionary3, CFSTR(kUSBProductID), numberRef);
					CFRelease(numberRef);
					//numberRef = 0;
					
					// Create a notification port and add its run loop event source to our run loop
					// This is how async notifications get set up.
					// Now set up a notification to be called when a device is first matched by I/O Kit.
	//				kr = IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
	//													  kIOFirstMatchNotification,  // notificationType
	//													  matchingDictionary3,        // matching
	//													  DeviceAdded,				  // callback
	//													  NULL,						  // refCon
	//													  &gAddedMissileIter		  // notification
	//													  );    
					IOServiceAddMatchingNotification(gNotifyPort,				  // notifyPort
														  kIOFirstMatchNotification,  // notificationType
														  matchingDictionary3,        // matching
														  DeviceAdded,				  // callback
														  NULL,						  // refCon
														  &gAddedMissileIter		  // notification
														  );    
					
					// Iterate once to get already-present devices and arm the notification    
					DeviceAdded(NULL, gAddedMissileIter);  

				}		
				else
				{
					NSLog(@"USBMissileControl: could not create matching dictionary3");
				}
				
			}		
			else
			{
				NSLog(@"USBMissileControl: could not create matching dictionary2");
			}
		} 
		else
		{
			NSLog(@"USBMissileControl: could not create matching dictionary1");
		}
		
		
		// Now done with the master_port
		mach_port_deallocate(mach_task_self(), masterPort);
		masterPort = 0;
	}
	
	return self;
}

//================================================================================================
//
//  DeviceAdded
//
//  This routine is the callback for our IOServiceAddMatchingNotification.  When we get called
//  we will look at all the devices that were added and we will:
//
//  1.  Create some private data to relate to each device (in this case we use the service's name
//      and the location ID of the device
//  2.  Submit an IOServiceAddInterestNotification of type kIOGeneralInterest for this device,
//      using the refCon field to store a pointer to our private data.  When we get called with
//      this interest notification, we can grab the refCon and access our private data.
//
//================================================================================================
//
void DeviceAdded(void *refCon, io_iterator_t iterator)
{
    kern_return_t			kr;
    io_service_t			usbDevice;
    IOCFPlugInInterface		**plugInInterface=NULL;
    SInt32					score;
    HRESULT					res;
    SInt32					usbVendorID;
	SInt32					usbProductID;
	
	Boolean						debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];

	
    while ((usbDevice = IOIteratorNext(iterator)) != 0)
    {
        io_name_t				deviceName;
        CFStringRef				deviceNameAsCFString;  
        USBLauncher				*privateDataRef = NULL;
		IOUSBDeviceInterface	**deviceInterface;
		
        UInt32					locationID;
		io_object_t				notification;
	
		IOUSBDevRequest			request;
		UInt8					hidDescBuf[255];

		
		launcherCount ++;
		NSLog(@"USBMissileControl: DeviceAdded: Launcher Found Number %d", launcherCount);
		// NSLog(@"USBMissileControl: Device: (0x%08x) found", usbDevice);
        CFTypeRef temp1 = IORegistryEntryCreateCFProperty(usbDevice, CFSTR(kUSBVendorID), kCFAllocatorDefault, 0);
		CFNumberGetValue(temp1, kCFNumberSInt32Type, &usbVendorID);
		CFRelease(temp1);
		
		CFTypeRef temp2 = IORegistryEntryCreateCFProperty(usbDevice, CFSTR(kUSBProductID), kCFAllocatorDefault, 0);
		CFNumberGetValue(temp2, kCFNumberSInt32Type, &usbProductID);
		CFRelease(temp2);

        // Add some app-specific information about this device.
        // Create a buffer to hold the data.
//        privateDataRef = [[[USBLauncher alloc] init] retain];
        privateDataRef = [[USBLauncher alloc] init];
        
		[privateDataRef setusbVendorID:usbVendorID];
		[privateDataRef setusbProductID:usbProductID];
		
		// Need to figure out what type of launcher it is - based on our preferences set
		// Probably not the best way to do this, but it is quick at the moment to seee if it's going to work
		NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
		
		NSString * launcher1_VendorId;
		NSString * launcher1_ProductId;
		NSString * launcher1_type;
		NSString * launcher2_VendorId;
		NSString * launcher2_ProductId;
		NSString * launcher2_type;
		NSString * launcher3_VendorId;
		NSString * launcher3_ProductId;
		NSString * launcher3_type;

		launcher1_VendorId = [NSString stringWithString:[prefs stringForKey:@"launcher1_VendorId"]];
		launcher1_ProductId = [NSString stringWithString:[prefs stringForKey:@"launcher1_ProductId"]];
		launcher1_type = [NSString stringWithString:[prefs stringForKey:@"launcher1_type"]];
		
		launcher2_VendorId = [NSString stringWithString:[prefs stringForKey:@"launcher2_VendorId"]];
		launcher2_ProductId = [NSString stringWithString:[prefs stringForKey:@"launcher2_ProductId"]];
		launcher2_type = [NSString stringWithString:[prefs stringForKey:@"launcher2_type"]];
		
		launcher3_VendorId = [NSString stringWithString:[prefs stringForKey:@"launcher3_VendorId"]];
		launcher3_ProductId = [NSString stringWithString:[prefs stringForKey:@"launcher3_ProductId"]];
		launcher3_type = [NSString stringWithString:[prefs stringForKey:@"launcher3_type"]];
		
		int launcher1_VendorId_num = [launcher1_VendorId intValue];
		int launcher1_ProductId_num = [launcher1_ProductId intValue];
		int launcher2_VendorId_num = [launcher2_VendorId intValue];
		int launcher2_ProductId_num = [launcher2_ProductId intValue];
		int launcher3_VendorId_num = [launcher3_VendorId intValue];
		int launcher3_ProductId_num = [launcher3_ProductId intValue];

		if (usbVendorID == launcher1_VendorId_num && usbProductID == launcher1_ProductId_num)
		{
			[privateDataRef setLauncherType:launcher1_type];
		} else 
		if (usbVendorID == launcher2_VendorId_num && usbProductID == launcher2_ProductId_num)
		{
			[privateDataRef setLauncherType:launcher2_type];
		} else 
		if (usbVendorID == launcher3_VendorId_num && usbProductID == launcher3_ProductId_num)
		{
			[privateDataRef setLauncherType:launcher3_type];
		}

		NSLog(@"USBMissileControl: DeviceAdded: usbVendorID: %ld(0x%ld) usbProductID: %ld(0x%ld) : %@", usbVendorID, usbVendorID, usbProductID, usbProductID, [privateDataRef getLauncherType]);

        // Get the USB device's name.
        kr = IORegistryEntryGetName(usbDevice, deviceName);
		if (KERN_SUCCESS != kr)
        {
            deviceName[0] = '\0';
        }
        
        deviceNameAsCFString = CFStringCreateWithCString(kCFAllocatorDefault, deviceName, 
                                                         kCFStringEncodingASCII);
        
        // Dump our data to stderr just to see what it looks like.
        //CFShow(deviceNameAsCFString);
        
        // Save the device's name to our private data.        
		[privateDataRef setDeviceName:deviceNameAsCFString];
		NSLog(@"USBMissileControl: DeviceAdded: Device Name: %@", [privateDataRef deviceName]);
		
        // Now, get the locationID of this device. In order to do this, we need to create an IOUSBDeviceInterface 
        // for our device. This will create the necessary connections between our userland application and the 
        // kernel object for the USB Device.
        kr = IOCreatePlugInInterfaceForService(usbDevice, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                               &plugInInterface, &score);
        if ((kIOReturnSuccess != kr) || !plugInInterface)
        {
            NSLog(@"USBMissileControl: DeviceAdded: unable to create plugin. ret = %08x, iodev = %p", kr, plugInInterface);
			[privateDataRef release];
			CFRelease(deviceNameAsCFString);
            continue;
        }
		
        // Use the plugin interface to retrieve the device interface.
        res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                 (LPVOID) &deviceInterface);
        // Now done with the plugin interface.
        (*plugInInterface)->Release(plugInInterface);
        if (res || !deviceInterface)
        {
            NSLog(@"USBMissileControl: DeviceAdded: couldn't create a device interface %x(%08x)", (int)res, (int)res);
			[privateDataRef release];
			CFRelease(deviceNameAsCFString);
            continue;
        }

		[privateDataRef setDeviceInterface:deviceInterface];	// IOUSBDeviceInterface    **deviceInterface;
		//NSLog(@"USBMissileControl:  deviceInterface: (0x%lx)", deviceInterface);

        // Now that we have the IOUSBDeviceInterface, we can call the routines in IOUSBLib.h.
        // In this case, fetch the locationID. The locationID uniquely identifies the device
        // and will remain the same, even across reboots, so long as the bus topology doesn't change.
        
        kr = (*deviceInterface)->GetLocationID(deviceInterface, &locationID);
        if (KERN_SUCCESS != kr)
        {
            NSLog(@"USBMissileControl: DeviceAdded: GetLocationID returned kr=(0x%08x)", kr);
			[privateDataRef release];
			CFRelease(deviceNameAsCFString);
            continue;
        }
        else
        {
			[privateDataRef setLocationID:locationID];
			//NSLog(@"USBMissileControl: DeviceAdded: Location ID: (%d)", locationID);
        }
		
        
		// Get device Speed - because we can
		// Missile Launcher software actually doesn't need this information
		UInt8 deviceSpeed;
        kr = (*deviceInterface)->GetDeviceSpeed(deviceInterface, &deviceSpeed);
        if (KERN_SUCCESS == kr)
        {
			if (debugCommands)
			{
				if (deviceSpeed == kUSBDeviceSpeedLow)
				{
					NSLog(@"USBMissileControl: DeviceAdded: GetDeviceSpeed returned kUSBDeviceSpeedLow");
				}
				else if (deviceSpeed == kUSBDeviceSpeedFull)
				{
					NSLog(@"USBMissileControl: DeviceAdded: GetDeviceSpeed returned kUSBDeviceSpeedFull");
				}
				else if (deviceSpeed == kUSBDeviceSpeedHigh)
				{
					NSLog(@"USBMissileControl: DeviceAdded: GetDeviceSpeed returned kUSBDeviceSpeedHigh");
				}
			}
        }
		
        // Register for an interest notification of this device being removed. Use a reference to our
        // private data as the refCon which will be passed to the notification callback.
        kr = IOServiceAddInterestNotification( gNotifyPort,			// notifyPort
                                               usbDevice,			// service
                                               kIOGeneralInterest,  // interestType
                                               DeviceNotification,  // callback
                                               privateDataRef,      // refCon
                                               &notification		// notification
                                               );
		// USBMissileControl: IOServiceAddInterestNotification returned 10000003
		// http://developer.apple.com/qa/qa2001/qa1075.html
		
        if (KERN_SUCCESS != kr)
        {
            NSLog(@"USBMissileControl: DeviceAdded: IOServiceAddInterestNotification returned (%08x)", kr);
        }
        [privateDataRef setNotification:notification];
		
		// Done with this USB device; release the reference added by IOIteratorNext
		kr = IOObjectRelease(usbDevice); 
        if (KERN_SUCCESS == kr && debugCommands)
        {
			NSLog(@"USBMissileControl: DeviceAdded: success - IOObjectRelease(usbDevice)");
		}

		// Add details of the new launcher to the table/array of launchers, then send a notification/message to the main window
		// this must be loaded into the array before calling FindInterfaces
		// FindInterfaces will delete the array entry if there is an error.		
		[launcherDevice addObject:privateDataRef];
		
		
		
		kr = FindInterfaces(deviceInterface);	// This creates & loads the missileInterface and loads it into privateDataRef
		if ([privateDataRef missileInterface] == nil)
		{
			NSLog(@"USBMissileControl: DeviceAdded: We have a problem. [privateDataRef missileInterface] is nil, means that FindInterfaces has not been able to find the deviceInterface, recommend kext investigation at this point");
			[privateDataRef release];
			CFRelease(deviceNameAsCFString);
			[[NSNotificationCenter defaultCenter] postNotificationName: @"usbConnectIssue" object: nil];
			continue;
		}
		
        if (KERN_SUCCESS == kr)
        {
//			NSLog(@"USBMissileControl: DeviceAdded: success - FindInterfaces(deviceInterface)");

			/*
			 Date:    13 December 2007
			 Subject: Fixing issues with the DreamCheeky RocketBaby launcher
			 
			 Patrick McNeil
			 
			 Ok, I have it working. For some reason, the read will never return unless the HID descriptor has been read in at initialization. 
			 This only needs to be done once, and should be done at the start (when you are setting up the interfaces etc.) 
			 It's a bit dumb because you don't even need to use the HID descriptor - ah well. 
			 Probably just a messy implementation in the firmware.. who knows.
			 
			 IOUSBDevRequest request;
			 UInt8 hidDescBuf[255];
			 
			 IOReturn			kr;
			 
			 request.bmRequestType = USBmakebmRequestType(kUSBIn, kUSBStandard, kUSBInterface);
			 request.bRequest = kUSBRqGetDescriptor;
			 request.wValue = (kUSBReportDesc << 8);
			 request.wIndex = 0;
			 request.wLength = sizeof(hidDescBuf);
			 request.pData = hidDescBuf;
			 
			 kr = (*missileIntf)->ControlRequest(missileIntf, 0, &request);
			 
			 Note that although the return value is an OR of the various states, you cannot send OR's of the states to moves 
			 more then one motor at a time.
			 
			 The reason that things were working for me last night and not this morning is because I had USB Prober open in the background 
			 last night and this reads all the descriptors, etc. of every attached USB device.
			 */
			
			//NSLog(@"USBMissileControl: DeviceAdded: Reading HID Descriptor");
			request.bmRequestType = USBmakebmRequestType(kUSBIn, kUSBStandard, kUSBInterface);
			request.bRequest = kUSBRqGetDescriptor;
			request.wValue = (kUSBReportDesc << 8);
			request.wIndex = 0;
			request.wLength = sizeof(hidDescBuf);
			request.pData = hidDescBuf;
			
			// this is going to fail if the device is not open (i.e. non exclusive access) and the program will crash --> EXC_BAD_ACCESS
			kr = (*[privateDataRef missileInterface])->ControlRequest([privateDataRef missileInterface], 0, &request);
			if (debugCommands)
			{
				if (KERN_SUCCESS == kr)
				{
//					NSLog(@"USBMissileControl: DeviceAdded: HIDDescriptor read succeeded");
				} else {
					NSLog(@"USBMissileControl: DeviceAdded: HIDDescriptor read failed");
				}
			}

#pragma mark Set Application ICON
			
			// Application icon is altered depending on what the first launcher is
			if (launcherCount == 1 && [[privateDataRef getLauncherType] isEqualToString:@"DreamRocket"])
			{
				[[NSNotificationCenter defaultCenter] postNotificationName: @"setDreamCheekyIcon" object:nil userInfo:nil];
			}
			if (launcherCount == 1 && [[privateDataRef getLauncherType] isEqualToString:@"DreamRocketII"])
			{
				[[NSNotificationCenter defaultCenter] postNotificationName: @"setDreamCheekyIcon" object:nil userInfo:nil];
			}
			if (launcherCount == 1 && [[privateDataRef getLauncherType] isEqualToString:@"OICStorm"])
			{
				[[NSNotificationCenter defaultCenter] postNotificationName: @"setDreamCheekyIOCIcon" object:nil userInfo:nil];
			}
			
			// send a connection error to the main aplication window
//			NSLog(@"Issue the USB Connected Message - we're ready to rock");
			[[NSNotificationCenter defaultCenter] postNotificationName: @"usbConnect" object: nil];

		} else {
			
			// kr == kIOReturnExclusiveAccess
			NSLog(@"USBMissileControl: DeviceAdded: FAILURE - FindInterfaces(deviceInterface)");
			NSLog(@"USBMissileControl: DeviceAdded: FAILURE - Make sure software has been installed using the installer application");
			NSLog(@"USBMissileControl: DeviceAdded: FAILURE - Possibly missing KEXT file in /System/Library/Extensions");
			
			// send a connection error to the main aplication window
			[[NSNotificationCenter defaultCenter] postNotificationName: @"usbError" object: nil];
			
		}
		
//		if (debugCommands)
//		{
//			NSLog(@"USBMissileControl: DeviceAdded: IOUSBDeviceInterface    (0x%08x)", [privateDataRef deviceInterface]);
//			NSLog(@"USBMissileControl: DeviceAdded: IOUSBInterfaceInterface (0x%08x)", [privateDataRef missileInterface]);
//		}
		
		[privateDataRef release];
		CFRelease(deviceNameAsCFString);
    }
	
	if (debugCommands)
		NSLog(@"USBMissileControl: DeviceAdded: launcherDevice %@", launcherDevice);
}

IOReturn FindInterfaces(IOUSBDeviceInterface **device)
{
    IOReturn                    kr;
    IOUSBFindInterfaceRequest   request;
    io_iterator_t               iterator;
    io_service_t                usbInterface;
    IOCFPlugInInterface         **plugInInterface = NULL;
    IOUSBInterfaceInterface     **missileInterface = NULL;
    HRESULT                     result;
    SInt32                      score;
    UInt8                       interfaceClass;
    UInt8                       interfaceSubClass;
    UInt8                       interfaceNumEndpoints;
    int                         pipeRef = 0;
	USBLauncher					*privateDataRef;
	int							interfaceCount;
 
    CFRunLoopSourceRef          runLoopSource;

	Boolean						debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];
	
	
	NSLog(@"USBMissileControl: FindInterfaces: [launcherDevice count] = %d", [launcherDevice count]);
	privateDataRef = [launcherDevice objectAtIndex:[launcherDevice count] -1 ];
	
//	NSLog(@"USBMissileControl: FindInterfaces: Finding IOUSBInterfaceInterface for IOUSBDeviceInterface    (0x%08x)", [privateDataRef deviceInterface]);
	
	//Placing the constant kIOUSBFindInterfaceDontCare into the following
    //fields of the IOUSBFindInterfaceRequest structure will allow you
    //to find all the interfaces
    request.bInterfaceClass		= kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass	= kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol	= kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting	= kIOUSBFindInterfaceDontCare;
 
    //Get an iterator for the interfaces on the device
    kr = (*device)->CreateInterfaceIterator(device, &request, &iterator);
	if (KERN_SUCCESS == kr)
	{
		if (debugCommands)
			NSLog(@"USBMissileControl: FindInterfaces: success - CreateInterfaceIterator");
	}
	
	interfaceCount = 0;
    while ((usbInterface = IOIteratorNext(iterator)) != 0)
    {
		interfaceCount ++;
		if (debugCommands)
			NSLog(@"USBMissileControl: FindInterfaces: Interface count %d", interfaceCount);
		
		//Create an intermediate plug-in
//        kr = IOCreatePlugInInterfaceForService(usbInterface,
//											   kIOUSBInterfaceUserClientTypeID,
//											   kIOCFPlugInInterfaceID,
//											   &plugInInterface, &score);
        IOCreatePlugInInterfaceForService(usbInterface,
											   kIOUSBInterfaceUserClientTypeID,
											   kIOCFPlugInInterfaceID,
											   &plugInInterface, &score);
        //Release the usbInterface object after getting the plug-in
        kr = IOObjectRelease(usbInterface);
        if ((kr != kIOReturnSuccess) || !plugInInterface)
        {
            NSLog(@"USBMissileControl: FindInterfaces: Unable to create a plug-in (0x%08x)", kr);
            break;
        }
 
        //Now create the device interface for the interface
        result = (*plugInInterface)->QueryInterface(plugInInterface,
                    CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                    (LPVOID) &missileInterface);
        //No longer need the intermediate plug-in
        kr = (*plugInInterface)->Release(plugInInterface);
 
        if (result || !missileInterface)
        {
            NSLog(@"USBMissileControl: FindInterfaces: Couldn't create a device interface for the interface result (0x%08x)", (int)result);
            break;
        } else {
			//NSLog(@"USBMissileControl: FindInterfaces: IOUSBInterfaceInterface (0x%08x)", missileInterface);
			[privateDataRef setMissileInterface:missileInterface];	// IOUSBInterfaceInterface **missileInterface
		}
 
        //Get interface class and subclass
//        kr = (*missileInterface)->GetInterfaceClass(missileInterface, &interfaceClass);
//        kr = (*missileInterface)->GetInterfaceSubClass(missileInterface, &interfaceSubClass);
        (*missileInterface)->GetInterfaceClass(missileInterface, &interfaceClass);
        (*missileInterface)->GetInterfaceSubClass(missileInterface, &interfaceSubClass);
		if (debugCommands)
			NSLog(@"USBMissileControl: FindInterfaces: Interface class %d, subclass %d", interfaceClass, interfaceSubClass);
 
        //Now open the interface. This will cause the pipes associated with
        //the endpoints in the interface descriptor to be instantiated
		
		// IOUSBInterfaceInterface - documentation
		// Before the client can transfer data to and from the interface, it must have succeeded in opening the interface. 
		// This establishes an exclusive link between the client's task and the actual interface device.
		
        kr = (*missileInterface)->USBInterfaceOpen(missileInterface);
		if (debugCommands)
			NSLog(@"USBMissileControl: FindInterfaces: USBInterfaceOpen (%p) kr=(0x%08x)", missileInterface, kr);
        if (kr != kIOReturnSuccess)
        {
			NSLog(@"USBMissileControl: FindInterfaces: WARNING -->");
			if (kr == kIOReturnExclusiveAccess)
			{
				NSLog(@"USBMissileControl: FindInterfaces: ");
				NSLog(@"USBMissileControl: FindInterfaces: kIOReturnExclusiveAccess (some other task has the device opened already) - Unable to open interface (%08x)", kr);
				NSLog(@"USBMissileControl: FindInterfaces: ");
				
				NSLog(@"USBMissileControl: FindInterfaces: Suggested KEXT plist vs. launcher mismatch issue");
				NSLog(@"USBMissileControl: FindInterfaces: PreRequisite: Check the readme document - just in case");
				NSLog(@"USBMissileControl: FindInterfaces: Diagnostic suggestions: Collect the following and mail output to developer");
				NSLog(@"USBMissileControl: FindInterfaces: Diagnostic suggestions: 1. System Profiler output saved");
				NSLog(@"USBMissileControl: FindInterfaces: Diagnostic suggestions: 2. From terminal enter 'ioreg -l -w 0 > ~/Desktop/ioreg.txt'");
				NSLog(@"USBMissileControl: FindInterfaces: Diagnostic suggestions: 3. Launcher type, vendorID, ProductID");
				NSLog(@"USBMissileControl: FindInterfaces: Diagnostic suggestions: 4. Hardware and Operating System Version information - though this will be in System Profiler");
				NSLog(@"USBMissileControl: FindInterfaces: ");
			}
			else
			{
				NSLog(@"USBMissileControl: FindInterfaces: Unable to open interface (0x%08x)", kr);
			}
			NSLog(@"USBMissileControl: FindInterfaces: WARNING --> The Missile Launcher Interface is being released, the program may no longer operate correctly");
			NSLog(@"USBMissileControl: FindInterfaces: WARNING --> The Missile Launcher Interface is being released, the program may no longer operate correctly");
			NSLog(@"USBMissileControl: FindInterfaces: WARNING --> The Missile Launcher Interface is being released, the program may no longer operate correctly");
			
			NSLog(@"USBMissileControl: FindInterfaces: WARNING -->");

            (void) (*missileInterface)->Release(missileInterface);
			
			// need to remove the launcher device entry from the array
			[launcherDevice removeObjectAtIndex:[launcherDevice count] -1 ];
			return kr;
            break;
        }
 
        //Get the number of endpoints associated with this interface
        kr = (*missileInterface)->GetNumEndpoints(missileInterface, &interfaceNumEndpoints);
        if (kr != kIOReturnSuccess)
        {
            NSLog(@"USBMissileControl: FindInterfaces: Unable to get number of endpoints kr=(0x%08x)", kr);
            (void) (*missileInterface)->USBInterfaceClose(missileInterface);
            (void) (*missileInterface)->Release(missileInterface);

			// need to remove the launcher device entry from the array
			[launcherDevice removeObjectAtIndex:[launcherDevice count] -1 ];
			return kr;
            break;
        }
 
		if (debugCommands)
			NSLog(@"USBMissileControl: FindInterfaces: Interface has %d endpoints", interfaceNumEndpoints);
		
        // Access each pipe in turn.
        // The pipe at index 0 is the default control pipe and should be
        // accessed using (*usbDevice)->DeviceRequest() instead
        for (pipeRef = 0; pipeRef < interfaceNumEndpoints+1; pipeRef++)
        {
            IOReturn        kr2;
            UInt8           direction;
            UInt8           number;
            UInt8           transferType;
            UInt16          maxPacketSize;
            UInt8           interval;
            char            *message;
 
            kr2 = (*missileInterface)->GetPipeProperties(missileInterface,
                                        pipeRef, &direction,
                                        &number, &transferType,
                                        &maxPacketSize, &interval);
			if (debugCommands)
			{
				if (kr2 != kIOReturnSuccess)
					NSLog(@"USBMissileControl: FindInterfaces: Unable to get properties of pipe %d kr2=(0x%08x)", pipeRef, kr2);
				else
				{
					NSLog(@"USBMissileControl: FindInterfaces: PipeRef %i: PipeNumber 0x%08x ", pipeRef, number);
					//printf("USBMissileControl: FindInterfaces: PipeRef %d: PipeNumber %d ", pipeRef, number);
					switch (direction) 
					{
						case kUSBOut:
							message = "out";
							break;
						case kUSBIn:
							message = "in";
							break;
						case kUSBNone:
							message = "none";
							break;
						case kUSBAnyDirn:
							message = "any";
							break;
						default:
							message = "???";
					}
					NSLog(@"USBMissileControl: FindInterfaces: --> direction %s, ", message);
					//printf("direction %s, ", message);
	 
					switch (transferType)
					{
						case kUSBControl:
							message = "control";
							break;
						case kUSBIsoc:
							message = "isoc";
							break;
						case kUSBBulk:
							message = "bulk";
							break;
						case kUSBInterrupt:
							message = "interrupt";
							break;
						case kUSBAnyType:
							message = "any";
							break;
						default:
							message = "???";
					}
					NSLog(@"USBMissileControl: FindInterfaces: --> transfer type %s, maxPacketSize %d", message, maxPacketSize);
	//                printf("transfer type %s, maxPacketSize %d\n", message, maxPacketSize);
				}
			}
        }
		
        //As with service matching notifications, to receive asynchronous
        //I/O completion notifications, you must create an event source and
        //add it to the run loop
        kr = (*missileInterface)->CreateInterfaceAsyncEventSource(missileInterface, &runLoopSource);
        if (kr != kIOReturnSuccess)
        {
            NSLog(@"USBMissileControl: FindInterfaces: Unable to create asynchronous event source kr=(0x%08x)", kr);
            (void) (*missileInterface)->USBInterfaceClose(missileInterface);
            (void) (*missileInterface)->Release(missileInterface);

			// need to remove the launcher device entry from the array
			[launcherDevice removeObjectAtIndex:[launcherDevice count] -1 ];
			return kr;
            break;
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
//		NSLog(@"USBMissileControl: FindInterfaces: Asynchronous event source added to run loop");
		
        //For this test, just use first interface, so exit loop
        //break;
	}
    return kr;
}


//================================================================================================
//
//  DeviceNotification
//
//  This routine will get called whenever any kIOGeneralInterest notification happens.  We are
//  interested in the kIOMessageServiceIsTerminated message so that's what we look for.  Other
//  messages are defined in IOMessage.h.
//
//================================================================================================
//
void DeviceNotification( void *refCon,
                         io_service_t service,
                         natural_t messageType,
                         void *messageArgument )
{
//    kern_return_t				kr;
    USBLauncher					*privateDataRef = (USBLauncher *) refCon;
	IOUSBDeviceInterface        **missileDevice = NULL;
	int							i;
	USBLauncher					*launcherDataRef;
	IOUSBDeviceInterface        **launcherMissileDevice = NULL;
	
	//		kIOMessageServiceIsSuspended
	//		kIOMessageServiceIsResumed
	//		kIOMessageServiceIsRequestingClose
	//		kIOMessageServiceIsAttemptingOpen
	//		kIOMessageServiceWasClosed
	//		kIOMessageServiceBusyStateChange
	//		kIOMessageServicePropertyChange
	//		kIOMessageCanDevicePowerOff
	//		kIOMessageDeviceWillPowerOff
	//		kIOMessageDeviceWillNotPowerOff
	//		kIOMessageDeviceHasPoweredOn
	//		kIOMessageCanSystemPowerOff
	//		kIOMessageSystemWillPowerOff
	//		kIOMessageSystemWillNotPowerOff
	//		kIOMessageCanSystemSleep
	//		kIOMessageSystemWillSleep
	//		kIOMessageSystemWillNotSleep
	//		kIOMessageSystemHasPoweredOn
	//		kIOMessageSystemWillRestart
	//		kIOMessageSystemWillPowerOn
	
	
	switch (messageType)
	{	
		case kIOMessageServiceIsTerminated:
		{
			NSLog(@"USBMissileControl: DeviceNotification: (0x%08x) REMOVED", service);
			
			// Dump our private data to stderr just to see what it looks like.
			//NSLog(@"USBMissileControl: Device Name: %@", [privateDataRef deviceName]);
			
			// Free the data we're no longer using now that the device is going away
			//CFRelease([privateDataRef->deviceName);
			missileDevice = [privateDataRef deviceInterface];
			
			if (missileDevice)
			{
//				kr = (*missileDevice)->Release(missileDevice);
				(*missileDevice)->Release(missileDevice);
			}
			
//			kr = IOObjectRelease([privateDataRef notification]);
			IOObjectRelease([privateDataRef notification]);
			
			// Launcher needs to be removed from launcherDevice array!
			int numItems = [launcherDevice count];
			for (i = 0; i < numItems; i++)
			{
				//launcherDataRef = [[USBLauncher alloc] init];
				launcherDataRef = [launcherDevice objectAtIndex: i];
				launcherMissileDevice = [launcherDataRef deviceInterface];
				if (launcherMissileDevice == missileDevice) {
					NSLog(@"USBMissileControl: DeviceNotification: item at index %d remove from launcherDevice array", i);
					[launcherDevice removeObjectAtIndex: i];
					launcherCount --;
					[[NSNotificationCenter defaultCenter] postNotificationName: @"usbDisConnect" object: nil];
				}
			}
			
			//[privateDataRef dealloc];
			//[privateDataRef release];
			break;
		}
		case kIOMessageServiceIsSuspended:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageServiceIsSuspended", service);
			break;
		}
		case kIOMessageServiceIsResumed:		
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageServiceIsResumed", service);
			break;
		}
		case kIOMessageServiceIsRequestingClose:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageServiceIsRequestingClose", service);
			break;
		}
		case kIOMessageServiceIsAttemptingOpen:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageServiceIsAttemptingOpen", service);
			break;
		}
		case kIOMessageServiceWasClosed:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageServiceWasClosed", service);
			break;
		}
		case kIOMessageServiceBusyStateChange:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageServiceBusyStateChange", service);
			break;
		}
		case kIOMessageServicePropertyChange:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageServicePropertyChange", service);
			break;
		}
		case kIOMessageCanDevicePowerOff:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageCanDevicePowerOff", service);
			break;
		}
		case kIOMessageDeviceWillPowerOff:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageDeviceWillPowerOff", service);
			break;
		}
		case kIOMessageDeviceWillNotPowerOff:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageDeviceWillNotPowerOff", service);
			break;
		}
		case kIOMessageDeviceHasPoweredOn:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageDeviceHasPoweredOn", service);
			break;
		}
		case kIOMessageCanSystemPowerOff:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageCanSystemPowerOff", service);
			break;
		}
		case kIOMessageSystemWillPowerOff:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageSystemWillPowerOff", service);
			break;
		}
		case kIOMessageSystemWillNotPowerOff:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageSystemWillNotPowerOff", service);
			break;
		}
		case kIOMessageCanSystemSleep:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageCanSystemSleep", service);
			break;
		}
		case kIOMessageSystemWillSleep:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageSystemWillSleep", service);
			break;
		}
		case kIOMessageSystemWillNotSleep:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageSystemWillNotSleep", service);
			break;
		}
		case kIOMessageSystemHasPoweredOn:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageSystemHasPoweredOn", service);
			break;
		}
		case kIOMessageSystemWillRestart:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageSystemWillRestart", service);
			break;
		}
		case kIOMessageSystemWillPowerOn:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) kIOMessageSystemWillPowerOn", service);
			break;
		}
		default:
		{
			NSLog(@"USBMissileControl : DeviceNotification: (0x%08x) UNKNOWN!!!!", service);
			NSLog(@"%lu %lu", iokit_family_msg(sub_iokit_usb, 0x0A), iokit_family_msg(sub_iokit_usb, 0x11));
			break;
		}
	}	
	

}

- (BOOL)confirmMissileLauncherConnected;
{
	//NSLog(@"USBMissileControl: confirmMissileLauncherConnected");
	if (launcherCount > 0)
	{
		return YES;
	}
	
	return NO;
}

- (void)dealloc;
{
	[self ReleaseMissileLauncher];
	[launcherDevice release];
	[super dealloc];
}

- (id)MissileControl:(UInt8)controlBits;
{
	IOUSBDevRequest				devRequest;
	UInt8						reqBuffer[8];
	UInt8						reqBuffer_RB[8];
	USBLauncher					*privateDataRef;
	int							launcherDeviceNum;
	IOUSBDeviceInterface        **missileDevice;
	IOUSBInterfaceInterface		**missileInterface;
	UInt8						rBuffer[dreamCheekyMaxPacketSize];
	UInt8						rbBuffer[rocketBabyMaxPacketSize]; // Rocket Baby
	UInt8						sbBuffer[OICSTORMMaxPacketSize]; // OICStorm
//	char						wBuffer[dreamCheekyMaxPacketSize];
	IOReturn                    kr;
//    UInt32                      bytesRead;
	Boolean						debugCommands;

	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];

	
	//NSLog(@"USBMissileControl: MissileControl");
	int numItems = [launcherDevice count];
	if (debugCommands)
	{
		NSLog(@"USBMissileControl: MissileControl: Launchers to control = %d", numItems);
	}
	
	for (launcherDeviceNum = 0; launcherDeviceNum < numItems; launcherDeviceNum++)
	{
		//privateDataRef = [[USBLauncher alloc] init];
		privateDataRef = [launcherDevice objectAtIndex: launcherDeviceNum];

		missileDevice = [privateDataRef deviceInterface];
		missileInterface = [privateDataRef missileInterface];
		if (debugCommands)
		{
			NSLog(@"USBMissileControl: MissileControl: launcherDevice index    %d", launcherDeviceNum);
//			NSLog(@"USBMissileControl: MissileControl: IOUSBDeviceInterface    (0x%08x)", missileDevice);
//			NSLog(@"USBMissileControl: MissileControl: IOUSBInterfaceInterface (0x%08x)", missileInterface);
		}
		
		if (missileInterface == nil)
		{
			NSLog(@"USBMissileControl: MissileControl: No Missile Interface - IGNORING REQUEST");
			continue;
		}
		
		
//		if ([privateDataRef getusbVendorID] == kUSBMissileVendorID &&
//			[privateDataRef getusbProductID] == kUSBMissileProductID)

#pragma mark - c-enter
		
		if ([[privateDataRef getLauncherType] isEqualToString:@"c-enter"])
		{
			// This code is here because I need to know the launcher type so that the right launcher can be parked
			// So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
			if (controlBits & 32)  // Park
			{
				//NSLog(@"USBMissileControl: MissileControl - MissileLauncher Park");
				// controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
				[self MissileLauncher_Park];
				return self;
			}
			
			/*
			 2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] controlLauncher: Laser Toggle Request START
			 2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] USBMissileControl: launcherType = StrikerII
			 2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] USBMissileControl: USBVendorID = 4400 (0x1130)
			 2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: USBProductID = 514 (0x202)
			 2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: controlBits 64
			 2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=11, reqBuffer[1]=11
			 2007-06-21 21:33:12.297 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=20, reqBuffer[1]=20
			 
			 --> here's the reason the laser goes off, this is being called twice...
			 
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: launcherType = StrikerII
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: USBVendorID = 4400 (0x1130)
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: USBProductID = 514 (0x202)
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: controlBits 64
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=11, reqBuffer[1]=11
			 2007-06-21 21:33:12.299 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=20, reqBuffer[1]=20
			 2007-06-21 21:33:12.300 USB Missile Launcher NZ[14304] controlLauncher: Laser Toggle Request FINISH
			 */
			
			
			// ===========================================================================
			// Control of USB Missile Launcher - c-enter
			// ===========================================================================
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: launcherType = %@", [privateDataRef getLauncherType]);
				NSLog(@"USBMissileControl: USBVendorID  = %ld (0x%ld)", [privateDataRef getusbVendorID], [privateDataRef getusbVendorID]);
				NSLog(@"USBMissileControl: USBProductID = %ld (0x%ld)", [privateDataRef getusbProductID], [privateDataRef getusbProductID]);
//				NSLog(@"USBMissileControl: device       = (0x%x)", [privateDataRef deviceInterface]);
				NSLog(@"USBMissileControl: controlBits  = %d", controlBits);
			}
			
			/*
			 USB Information (hexadecimal values): 
			 Vendor Name: WinBond
			 "idVendor" = 0x416
			 "idProduct" = 0x9391

			 Vendor ID: 1046
			 Product ID: 37777 
			 
			 Ignore this little table for now, I'm just trying to reverse engineer
			 what the launcher developers have done. not much help for up/left try activities
			 like the other launchers support.
			 |  16  | 8 | 4 | 2 | 1 |
			 |------|---|---|---|---|
			 |   0  | 1 | 0 | 1 | 0 |   10 - fire
			 |   0  | 1 | 0 | 1 | 1 |   11 - laser
			 |   0  | 1 | 1 | 0 | 0 |   12 - left
			 |   0  | 1 | 1 | 0 | 1 |   13 - right
			 |   0  | 1 | 1 | 1 | 0 |   14 - up
			 |   0  | 1 | 1 | 1 | 1 |   15 - down
			 |   1  | 0 | 1 | 0 | 0 |   20 - release
			 
			 Toy Command Bytes (hexadecimal values): 
			 Fire Missile  = 0x0a	10
			 Laser Toggle  = 0x0b	11
			 Move Left = 0x0c		12
			 Move Right = 0x0d		13
			 Move Up = 0x0e			14
			 Move Down  = 0x0f		15
			 Release = 0x14			20
			 
			 
			 This documentation from the supplier would appear to be WRONG!
			 Actually bytes 0 and 1 need to be filled followed by zeros in the remaining bytes up to 8.
			 This information was discovered by using SnoopyPro on a PC.
			 
			 Sending Toy Commands with Control Transfer (PC to Toy): 
			 Byte 0: 0 
			 Byte 1: toyCommandByte 
			 Byte 2: toyCommandByte 
			 
			 Example Toy Command with Control Transfer: Move Left 
			 Byte 0: 0 
			 Byte 1: 0x0c 
			 Byte 2: 0x0c  Send...  
			 
			 Byte 0: 0 
			 Byte 1: 0x14 
			 Byte 2: 0x14  Send...
			 */
			reqBuffer[0] = 0x5f;
			reqBuffer[1] = 0x60;
			if (controlBits & 1)
				reqBuffer[1] = 0x68;//left
			
			if (controlBits & 2)
				reqBuffer[1] = 0x64;//right
			
			if (controlBits & 4)
				reqBuffer[1] = 0xa2;//up
			
			if (controlBits & 8)
				reqBuffer[1] = 0xe1;//down
			
			if (controlBits & 16)
				reqBuffer[1] = 0x70;//fire
			
			//			if (controlBits & 64)
			//				reqBuffer[1] = 0x0b;//Laser Toggle
			
			//			if (reqBuffer[1] == 0)
			//			{
			//				reqBuffer[1] = 0x14;   // this is a guess. If I come back into this routine with a 0 controlBit
			//				//reqBuffer[1] = 0x14;   // then perhaps I should send a "stop" or in this case a "release" to the launcher?
			//			} else
			//			{
			//				reqBuffer[1] = reqBuffer[0];
			//			}
			reqBuffer[2] = 0xe0;
			reqBuffer[3] = 0xff;
			reqBuffer[4] = 0xfe;
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = kUSBRqSetConfig; 
			devRequest.wValue = kUSBConfDesc; 
			devRequest.wIndex = 0; 
			devRequest.wLength = 5; 
			devRequest.pData = reqBuffer; 
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: c-enter reqBuffer[0]=%d, reqBuffer[1]=%d", reqBuffer[0], reqBuffer[1]);
			}
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (kr != kIOReturnSuccess)
			{
				if (kr == kIOReturnNoDevice)
				{
					if (debugCommands) 
						NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
				} else
					if (kr == kIOReturnNotOpen)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
					} else
					{
						EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
					}
			}
			
			//			if (controlBits & 64)  //Laser Toggle
			//			if ((controlBits & 16) || (controlBits & 64))
            if (controlBits & 16)
            {
                // After firing one missile, wait some seconds and send clear command.
                // Otherwise the launcher will keep on firing.
                int delayCounter;
				for (delayCounter = 0; delayCounter < 47; delayCounter ++)  // 4.7 seconds
				{
					[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:0.100]];
				}
                reqBuffer[0] = 0x5f;
                reqBuffer[1] = 0x60;
                reqBuffer[2] = 0xe0;
                reqBuffer[3] = 0xff;
                reqBuffer[4] = 0xfe;
                devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
                devRequest.bRequest = kUSBRqSetConfig; 
                devRequest.wValue = kUSBConfDesc; 
                devRequest.wIndex = 0; 
                devRequest.wLength = 5; 
                devRequest.pData = reqBuffer; 
                if (debugCommands)
                {
                    NSLog(@"USBMissileControl: c-enter reqBuffer[0]=%d, reqBuffer[1]=%d", reqBuffer[0], reqBuffer[1]);
                }
                kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
                if (kr != kIOReturnSuccess)
                {
                    if (kr == kIOReturnNoDevice)
                    {
                        if (debugCommands) 
                            NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
                    } else
                        if (kr == kIOReturnNotOpen)
                        {
                            if (debugCommands) 
                                NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
                        } else
                        {
                            EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
                        }
                }

            }
			//			} else
			//			{
			//				reqBuffer[0] = 0x5f; // release
			//				reqBuffer[1] = 0x60; // release
			//                reqBuffer[2] = 0xe0;
			//                reqBuffer[3] = 0xff;
			//                reqBuffer[4] = 0xfe;
			////				reqBuffer[5] = 0;
			////				reqBuffer[6] = 0;
			////				reqBuffer[7] = 0;
			//				devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			//				devRequest.bRequest = kUSBRqSetConfig; 
			//				devRequest.wValue = kUSBConfDesc; 
			////				devRequest.wIndex = 0;  // Switched this to 1 after mail from Erik Mason - 1 May 2007
			//				devRequest.wIndex = 1;  // having this as 1 may cause a problem with the "release" command
			//										// Erik Mason reported that movement doesn't stop until launcher reaches end of travel
			//				devRequest.wLength = 5; 
			//				devRequest.pData = reqBuffer; 
			//				if (debugCommands)
			//				{
			//					NSLog(@"USBMissileControl: STRIKER II reqBuffer[0]=%d, reqBuffer[1]=%d", reqBuffer[0], reqBuffer[1]);
			//				}
			//				kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			//				if (kr != kIOReturnSuccess)
			//				{
			//					if (kr == kIOReturnNoDevice)
			//					{
			//						if (debugCommands) 
			//							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
			//					} else
			//						if (kr == kIOReturnNotOpen)
			//						{
			//							if (debugCommands) 
			//								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
			//						} else
			//						{
			//							EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
			//						}
			//				}
			//			}
			
			// ===========================================================================
			// END OF Control of USB Missile Launcher - c-enter
			// ===========================================================================
			
		}
		else
			//		if ([privateDataRef getusbVendorID] == kUSBMissileVendorID &&
			//			[privateDataRef getusbProductID] == kUSBMissileProductID)

		
#pragma mark - StrikerII

		if ([[privateDataRef getLauncherType] isEqualToString:@"StrikerII"])
		{
			// This code is here because I need to know the launcher type so that the right launcher can be parked
			// So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
			if (controlBits & 32)  // Park
			{
				//NSLog(@"USBMissileControl: MissileControl - MissileLauncher Park");
				// controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
				[self MissileLauncher_Park];
				return self;
			}
			
			/*
			 2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] controlLauncher: Laser Toggle Request START
			 2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] USBMissileControl: launcherType = StrikerII
			 2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] USBMissileControl: USBVendorID = 4400 (0x1130)
			 2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: USBProductID = 514 (0x202)
			 2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: controlBits 64
			 2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=11, reqBuffer[1]=11
			 2007-06-21 21:33:12.297 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=20, reqBuffer[1]=20
			 
			 --> here's the reason the laser goes off, this is being called twice...
			 
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: launcherType = StrikerII
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: USBVendorID = 4400 (0x1130)
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: USBProductID = 514 (0x202)
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: controlBits 64
			 2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=11, reqBuffer[1]=11
			 2007-06-21 21:33:12.299 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=20, reqBuffer[1]=20
			 2007-06-21 21:33:12.300 USB Missile Launcher NZ[14304] controlLauncher: Laser Toggle Request FINISH
			 */
			
			
			// ===========================================================================
			// Control of USB Missile Launcher - Striker II
			// ===========================================================================
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: launcherType = %@", [privateDataRef getLauncherType]);
				NSLog(@"USBMissileControl: USBVendorID  = %ld (0x%ld)", [privateDataRef getusbVendorID], [privateDataRef getusbVendorID]);
				NSLog(@"USBMissileControl: USBProductID = %ld (0x%ld)", [privateDataRef getusbProductID], [privateDataRef getusbProductID]);
//				NSLog(@"USBMissileControl: device       = (0x%x)", [privateDataRef deviceInterface]);
				NSLog(@"USBMissileControl: controlBits  = %d", controlBits);
			}
		
/*
			USB Information (hexadecimal values): 
			Vendor ID: 1130 
			Product ID: 0202 
			
			Ignore this little table for now, I'm just trying to reverse engineer
			what the launcher developers have done. not much help for up/left try activities
			like the other launchers support.
			|  16  | 8 | 4 | 2 | 1 |
			|------|---|---|---|---|
			|   0  | 1 | 0 | 1 | 0 |   10 - fire
			|   0  | 1 | 0 | 1 | 1 |   11 - laser
			|   0  | 1 | 1 | 0 | 0 |   12 - left
			|   0  | 1 | 1 | 0 | 1 |   13 - right
			|   0  | 1 | 1 | 1 | 0 |   14 - up
			|   0  | 1 | 1 | 1 | 1 |   15 - down
			|   1  | 0 | 1 | 0 | 0 |   20 - release
 
			Toy Command Bytes (hexadecimal values): 
			Fire Missile  = 0x0a	10
			Laser Toggle  = 0x0b	11
			Move Left = 0x0c		12
			Move Right = 0x0d		13
			Move Up = 0x0e			14
			Move Down  = 0x0f		15
			Release = 0x14			20

 
			This documentation from the supplier would appear to be WRONG!
			Actually bytes 0 and 1 need to be filled followed by zeros in the remaining bytes up to 8.
			This information was discovered by using SnoopyPro on a PC.
 
			Sending Toy Commands with Control Transfer (PC to Toy): 
			Byte 0: 0 
			Byte 1: toyCommandByte 
			Byte 2: toyCommandByte 
			
			Example Toy Command with Control Transfer: Move Left 
			Byte 0: 0 
			Byte 1: 0x0c 
			Byte 2: 0x0c  Send...  
			
			Byte 0: 0 
			Byte 1: 0x14 
			Byte 2: 0x14  Send...
*/
			reqBuffer[0] = 0;
			if (controlBits & 1)
				reqBuffer[0] = 0x0c;//left

			if (controlBits & 2)
				reqBuffer[0] = 0x0d;//right
			
			if (controlBits & 4)
				reqBuffer[0] = 0x0e;//up
			
			if (controlBits & 8)
				reqBuffer[0] = 0x0f;//down
			
			if (controlBits & 16)
				reqBuffer[0] = 0x0a;//fire

			if (controlBits & 64)
				reqBuffer[0] = 0x0b;//Laser Toggle
				
			if (reqBuffer[0] == 0)
			{
				reqBuffer[0] = 0x14;   // this is a guess. If I come back into this routine with a 0 controlBit
				reqBuffer[1] = 0x14;   // then perhaps I should send a "stop" or in this case a "release" to the launcher?
			} else
			{
				reqBuffer[1] = reqBuffer[0];
			}
			reqBuffer[2] = 0;
			reqBuffer[3] = 0;
			reqBuffer[4] = 0;
			reqBuffer[5] = 0;
			reqBuffer[6] = 0;
			reqBuffer[7] = 0;
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = kUSBRqSetConfig; 
			devRequest.wValue = kUSBConfDesc; 
			devRequest.wIndex = 0; 
			devRequest.wLength = 8; 
			devRequest.pData = reqBuffer; 
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: STRIKER II reqBuffer[0]=%d, reqBuffer[1]=%d", reqBuffer[0], reqBuffer[1]);
			}
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (kr != kIOReturnSuccess)
			{
				if (kr == kIOReturnNoDevice)
				{
					if (debugCommands) 
						NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
				} else
					if (kr == kIOReturnNotOpen)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
					} else
					{
						EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
					}
			}

//			if (controlBits & 64)  //Laser Toggle
//			if ((controlBits & 16) || (controlBits & 64))
			if (controlBits & 16)
			{
				// after the fire comand, we can't send the "release" to the launcher	
				// so, NO OPP
			} else
			{
				reqBuffer[0] = 0x14; // release
				reqBuffer[1] = 0x14; // release
				reqBuffer[2] = 0;
				reqBuffer[3] = 0;
				reqBuffer[4] = 0;
				reqBuffer[5] = 0;
				reqBuffer[6] = 0;
				reqBuffer[7] = 0;
				devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
				devRequest.bRequest = kUSBRqSetConfig; 
				devRequest.wValue = kUSBConfDesc; 
//				devRequest.wIndex = 0;  // Switched this to 1 after mail from Erik Mason - 1 May 2007
				devRequest.wIndex = 1;  // having this as 1 may cause a problem with the "release" command
										// Erik Mason reported that movement doesn't stop until launcher reaches end of travel
				devRequest.wLength = 8; 
				devRequest.pData = reqBuffer; 
				if (debugCommands)
				{
					NSLog(@"USBMissileControl: STRIKER II reqBuffer[0]=%d, reqBuffer[1]=%d", reqBuffer[0], reqBuffer[1]);
				}
				kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
				if (kr != kIOReturnSuccess)
				{
					if (kr == kIOReturnNoDevice)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
					} else
						if (kr == kIOReturnNotOpen)
						{
							if (debugCommands) 
								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
						} else
						{
							EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
						}
				}
			}
			
			// ===========================================================================
			// END OF Control of USB Missile Launcher - Striker II
			// ===========================================================================
			
		}
		else
		//		if ([privateDataRef getusbVendorID] == kUSBMissileVendorID &&
		//			[privateDataRef getusbProductID] == kUSBMissileProductID)
			
#pragma mark OrigLauncher

		if ([[privateDataRef getLauncherType] isEqualToString:@"OrigLauncher"])
		{
			
			// This code is here because I need to know the launcher type so that the right launcher can be parked
			// So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
			if (controlBits & 32)  // Park
			{
				//NSLog(@"USBMissileControl: MissileControl - MissileLauncher Park");
				// controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
				[self MissileLauncher_Park];
				return self;
			}
			
			// ===========================================================================
			// Control of USB Missile Launcher - Original Launcher
			// ===========================================================================
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: launcherType = %@", [privateDataRef getLauncherType]);
				NSLog(@"USBMissileControl: USBVendorID  = %ld (0x%ld)", [privateDataRef getusbVendorID], [privateDataRef getusbVendorID]);
				NSLog(@"USBMissileControl: USBProductID = %ld (0x%ld)", [privateDataRef getusbProductID], [privateDataRef getusbProductID]);
//				NSLog(@"USBMissileControl: device       = (0x%x)", [privateDataRef deviceInterface]);
				NSLog(@"USBMissileControl: controlBits  = %d", controlBits);
			}
			
			reqBuffer[0] = 'U';
			reqBuffer[1] = 'S';
			reqBuffer[2] = 'B';
			reqBuffer[3] = 'C';
			reqBuffer[4] = 0;
			reqBuffer[5] = 0;
			reqBuffer[6] = 4;
			reqBuffer[7] = 0;
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = kUSBRqSetConfig; 
			devRequest.wValue = kUSBConfDesc; 
			devRequest.wIndex = 1;
			devRequest.wLength = 8; 
			devRequest.pData = reqBuffer; 
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (kr != kIOReturnSuccess)
			{
				if (kr == kIOReturnNoDevice)
				{
					if (debugCommands) 
						NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
				} else
					if (kr == kIOReturnNotOpen)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
					} else
					{
						EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
					}
			}
			
			reqBuffer[0] = 'U';
			reqBuffer[1] = 'S';
			reqBuffer[2] = 'B';
			reqBuffer[3] = 'C';
			reqBuffer[4] = 0;
			reqBuffer[5] = 64;
			reqBuffer[6] = 2;
			reqBuffer[7] = 0;
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = kUSBRqSetConfig; 
			devRequest.wValue = kUSBConfDesc; 
			devRequest.wIndex = 1;
			devRequest.wLength = 8; 
			devRequest.pData = reqBuffer; 
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (kr != kIOReturnSuccess)
			{
				if (kr == kIOReturnNoDevice)
				{
					if (debugCommands) 
						NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
				} else
					if (kr == kIOReturnNotOpen)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
					} else
					{
						EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
					}
			}
			
			reqBuffer[0] = 0;
			if (controlBits & 1)
				reqBuffer[1] = 1;//left
			else
				reqBuffer[1] = 0;
			
			if (controlBits & 2)
				reqBuffer[2] = 1;//right
			else
				reqBuffer[2] = 0;//right
				
			if (controlBits & 4)
				reqBuffer[3] = 1;//up
			else
				reqBuffer[3] = 0;//up
				
			if (controlBits & 8)
				reqBuffer[4] = 1;//down
			else
				reqBuffer[4] = 0;//down
				
			if (controlBits & 16)
				reqBuffer[5] = 1;//fire
			else
				reqBuffer[5] = 0;//fire
				
			reqBuffer[6] = 8;
			reqBuffer[7] = 8;
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = kUSBRqSetConfig; 
			devRequest.wValue = kUSBConfDesc; 
			devRequest.wIndex = 0;
			devRequest.wLength = 64; 
			devRequest.pData = reqBuffer; 
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (kr != kIOReturnSuccess)
			{
				if (kr == kIOReturnNoDevice)
				{
					if (debugCommands) 
						NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
				} else
					if (kr == kIOReturnNotOpen)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
					} else
					{
						EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
					}
			}
			
			// ===========================================================================
			// END OF Control of USB Missile Launcher
			// ===========================================================================
			
		}
		
		else 
//			if ([privateDataRef getusbVendorID] == kUSBRocketVendorID &&
//				[privateDataRef getusbProductID] == kUSBRocketProductID)
			
			// http://forum.codecall.net/visual-basic-programming/23869-programming-hardware-3.html

//			StrikerII (Grey) includes laser
//			USB Vendor ID		0x1130	4400
//			USB Product ID		0x0202	514
			
//			Class MissileDevice:
//			INITA     = (85, 83, 66, 67,  0,  0,  4,  0)
//			INITB     = (85, 83, 66, 67,  0, 64,  2,  0)
//			CMDFILL   = ( 8,  8,
//						 0,  0,  0,  0,  0,  0,  0,  0,
//						 0,  0,  0,  0,  0,  0,  0,  0,
//						 0,  0,  0,  0,  0,  0,  0,  0,
//						 0,  0,  0,  0,  0,  0,  0,  0,
//						 0,  0,  0,  0,  0,  0,  0,  0,
//						 0,  0,  0,  0,  0,  0,  0,  0,
//						 0,  0,  0,  0,  0,  0,  0,  0)
//			STOP      = ( 0,  0,  0,  0,  0,  0)
//			LEFT      = ( 0,  1,  0,  0,  0,  0)
//			RIGHT     = ( 0,  0,  1,  0,  0,  0)
//			UP        = ( 0,  0,  0,  1,  0,  0)
//			DOWN      = ( 0,  0,  0,  0,  1,  0)
//			LEFTUP    = ( 0,  1,  0,  1,  0,  0)
//			RIGHTUP   = ( 0,  0,  1,  1,  0,  0)
//			LEFTDOWN  = ( 0,  1,  0,  0,  1,  0)
//			RIGHTDOWN = ( 0,  0,  1,  0,  1,  0)
//			FIRE      = ( 0,  0,  0,  0,  0,  1)
//			
//			def __init__(self, battery):
//			try:
//			self.dev=UsbDevice(0x1130, 0x0202, battery)
//			self.dev.open()
//			self.dev.handle.reset()
//			except NoMissilesError, e:
//			raise NoMissilesError()
//			
//			def move(self, direction):
//			self.dev.handle.controlMsg(0x21, 0x09, self.INITA, 0x02, 0x01)
//			self.dev.handle.controlMsg(0x21, 0x09, self.INITB, 0x02, 0x01)
//			self.dev.handle.controlMsg(0x21, 0x09, direction+self.CMDFILL, 0x02, 0x01)

			
			
			
			
#pragma mark Satzuma

//	Satzuma Missile launcher (actually Winbond Electronics Corp.)
//	USB Vendor ID		0x416	1046
//	USB Product ID		0x9391	37777
	
 
// STOP      = 0x0
// LEFT      = 0x8
// RIGHT     = 0x4
// UP        = 0x2
// DOWN      = 0x1
// LEFTUP    = LEFT + UP
// RIGHTUP   = RIGHT + UP
// LEFTDOWN  = LEFT + DOWN
// RIGHTDOWN = RIGHT + DOWN
// FIRE      = 0x10

			
		if ([[privateDataRef getLauncherType] isEqualToString:@"Satzuma"])
		{
			
			// This code is here because I need to know the launcher type so that the right launcher can be parked
			// So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
			if (controlBits & 32)  // Park
			{
				//NSLog(@"USBMissileControl: MissileControl - MissileLauncher Park");
				// controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
				[self MissileLauncher_Park];
				return self;
			}
			
			// ===========================================================================
			// Control of USB Missile Launcher - Original Launcher NOT CHANGED YET NOT CHANGED YET NOT CHANGED YET
			// ===========================================================================
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: launcherType = %@", [privateDataRef getLauncherType]);
				NSLog(@"USBMissileControl: USBVendorID  = %ld (0x%ld)", [privateDataRef getusbVendorID], [privateDataRef getusbVendorID]);
				NSLog(@"USBMissileControl: USBProductID = %ld (0x%ld)", [privateDataRef getusbProductID], [privateDataRef getusbProductID]);
//				NSLog(@"USBMissileControl: device       = (0x%x)", [privateDataRef deviceInterface]);
				NSLog(@"USBMissileControl: controlBits  = %d", controlBits);
			}
			
			reqBuffer[0] = 0x5f;
			reqBuffer[1] = 0x00;
			reqBuffer[2] = 0xe0;
			reqBuffer[3] = 0xff;
			reqBuffer[4] = 0xfe;
			reqBuffer[5] = 0x0300;
			reqBuffer[6] = 0x00;
			reqBuffer[7] = 0x00;
			
			if (controlBits & 1)
				reqBuffer[1] = 0x08;//left
			
			if (controlBits & 2)
				reqBuffer[1] = 0x04;//right
			
			if (controlBits & 4)
				reqBuffer[1] = 0x02;//up
			
			if (controlBits & 8)
				reqBuffer[1] = 0x01;//down
			
			if (controlBits & 16)
				reqBuffer[1] = 0x10;//fire
			
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = kUSBRqSetConfig; 
			devRequest.wValue = kUSBConfDesc; 
			devRequest.wIndex = 0;
			devRequest.wLength = 5; 
			devRequest.pData = reqBuffer; 
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (kr != kIOReturnSuccess)
			{
				if (kr == kIOReturnNoDevice)
				{
					if (debugCommands) 
						NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
				} else
					if (kr == kIOReturnNotOpen)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
					} else
					{
						EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
					}
			}
			
			// ===========================================================================
			// END OF Control of USB Missile Launcher
			// ===========================================================================
			
		}
	
		else 
				//			if ([privateDataRef getusbVendorID] == kUSBRocketVendorID &&
				//				[privateDataRef getusbProductID] == kUSBRocketProductID)
				
#pragma mark DreamRocket
			
		if ([[privateDataRef getLauncherType] isEqualToString:@"DreamRocket"])

		{

			// This code is here because I need to know the launcher type so that the right launcher can be parked
			// So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
			if (controlBits & 32)  // Park
			{
				//NSLog(@"USBMissileControl: MissileControl - DreamCheeky Park");
				// controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
				[self DreamCheeky_Park];
				return self;
			}
			
			// ===========================================================================
			// Control of USB Rocket Launcher - DreamCheeky
			// ===========================================================================
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: launcherType = %@", [privateDataRef getLauncherType]);
				NSLog(@"USBMissileControl: USBVendorID  = %ld (0x%ld)", [privateDataRef getusbVendorID], [privateDataRef getusbVendorID]);
				NSLog(@"USBMissileControl: USBProductID = %ld (0x%ld)", [privateDataRef getusbProductID], [privateDataRef getusbProductID]);
//				NSLog(@"USBMissileControl: device       = (0x%x)", [privateDataRef deviceInterface]);
				NSLog(@"USBMissileControl: controlBits  = %d", controlBits);
			}
				
			// Control of the launcher works on a binary code - see the table below for an explanation
			//
			//     |  16  | 8 | 4 | 2 | 1 |
			//     |------|---|---|---|---|
			//     |   0  | 0 | 0 | 0 | 1 |    1 - Up
			//     |   0  | 0 | 0 | 1 | 0 |    2 - Down
			//     |   0  | 0 | 0 | 1 | 1 |    3 - nothing
			//     |   0  | 0 | 1 | 0 | 0 |    4 - Left
			//     |   0  | 0 | 1 | 0 | 1 |    5 - Up / Left
			//     |   0  | 0 | 1 | 1 | 0 |    6 - Down / left
			//     |   0  | 0 | 1 | 1 | 1 |    7 - Slow left
			//     |   0  | 1 | 0 | 0 | 0 |    8 - Right
			//     |   0  | 1 | 0 | 0 | 1 |    9 - Up / Right
			//     |   0  | 1 | 0 | 1 | 0 |   10 - Down / Right
			//     |   0  | 1 | 0 | 1 | 1 |   11 - Slow Right
			//     |   0  | 1 | 1 | 0 | 0 |   12 - nothing
			//     |   0  | 1 | 1 | 0 | 1 |   13 - Slow Up
			//     |   0  | 1 | 1 | 1 | 0 |   14 - Slow Down
			//     |   0  | 1 | 1 | 1 | 1 |   15 - nothing
			//     |   1  | 0 | 0 | 0 | 0 |   16 - Fire
			//
			//     | Fire |RT |LT |DN |UP |
			//
			//		Thanks to Brandon Heyer for the following:
			//      the DreamCheeky Launcher will return the following codes
			//	
			//		00 04 00 00 00 00 00 00 - All the way left
			//		00 08 00 00 00 00 00 00 - All the way right
			//		40 00 00 00 00 00 00 00 - All the way down
			//		80 00 00 00 00 00 00 00 - All the way up 
			//		00 80 00 00 00 00 00 00 - Fire Has completed 
			//		00 84 00 00 00 00 00 00 - Fire Has completed and we're all the way left
			//		00 88 00 00 00 00 00 00 - Fire Has completed and we're all the way right
			
			//		They also OR together when you are in the corners, 
			//		I'd imagine cool patrol sequences (box, figure eight) could be made if these are analyzed while the turret moves. 
			//	Note the definition of the readbuffer (a definition of char doesn't cut the mustard Colonel!)
			//			UInt8						rBuffer[dreamCheekyMaxPacketSize];

			// Lets see if we have reached the end of a travel direction
			// If we have, we need to discontinue moving in that direction
			// So we have likely received a request to move up for example, so lets cancel that.
			kr = DreamCheekyReadPipe(missileDevice, missileInterface, rBuffer);
			if (kr != kIOReturnSuccess)
			{
				if (debugCommands)
					NSLog(@"USBMissileControl: ERROR returned from DreamCheekyReadPipe kr=(0x%08x)", kr);
			} else
			{	
				if (debugCommands)
					NSLog(@"USBMissileControl: return from DreamCheekyReadPipe (0x%02x) (0x%02x) ", rBuffer[0], rBuffer[1]);
			}
				
//			Left		controlBits |= 1;
//			Right		controlBits |= 2;
//			Up			controlBits |= 4;
//			Down		controlBits |= 8;
//			Fire		controlBits |= 16;
//			NSLog(@"USBMissileControl: controlBits %d", controlBits);

			if (rBuffer[0] == 0x40)
			{
				if (controlBits & 8)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional down request");
					controlBits = controlBits ^8;
				}
			} else 
			if (rBuffer[0] == 0x80)
			{
				if (controlBits & 4)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional up request");
					controlBits = controlBits ^4;
				}
			}
			if ((rBuffer[1] == 0x04) || (rBuffer[1] == 0x84)) // this command response can get mixed up with Fire
			{
				if (controlBits & 1)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional left request");
					controlBits = controlBits ^1;
				}
			} else 
			if ((rBuffer[1] == 0x08) || (rBuffer[1] == 0x88)) // this command response can get mixed up with Fire
			{
				if (controlBits & 2)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional right request");
					controlBits = controlBits ^2;
				}
			}
			if (debugCommands)
				NSLog(@"USBMissileControl: controlBits %d", controlBits);
/*			
			// send the first package - NULL
			reqBuffer[0] = 0;
			reqBuffer[1] = 0;
			reqBuffer[2] = 0;
			reqBuffer[3] = 0;
			reqBuffer[4] = 0;
			reqBuffer[5] = 0;
			reqBuffer[6] = 0;
			reqBuffer[7] = 0;
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = 0x09; 
			devRequest.wValue = 0x0000200;
			devRequest.wIndex = 0;
			devRequest.wLength = 1;
			devRequest.pData = reqBuffer; 
			if (debugCommands)
			{
				NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
				NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
				NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
				NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
				NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
				NSLog(@"USBMissileControl: DreamCheeky command package (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
			}
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (debugCommands) 
			{
				if (kr != kIOReturnSuccess)
				{
					if (kr == kIOReturnNoDevice)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
					} else
						if (kr == kIOReturnNotOpen)
						{
							if (debugCommands) 
								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
						} else
						{
							NSLog(@"USBMissileControl: ERROR sending the first package - NULL");
							EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
						}
				}
			}
 
 */
			
			// send the second package - contains actual instruction
			reqBuffer[0] = 0x00;
			gBuffer[0] = 0x00;
			if (controlBits & 1)   // left
			{
				reqBuffer[0] |= 4;
				gBuffer[0]   |= 4;  // added for WritePipe support 27Jan2007
			}
			if (controlBits & 2)   // right
			{
				reqBuffer[0] |= 8;
				gBuffer[0]   |= 8;  // added for WritePipe support 27Jan2007
			}
			if (controlBits & 4)   // up
			{
				reqBuffer[0] |= 1;
				gBuffer[0]   |= 1;  // added for WritePipe support 27Jan2007
			}
			if (controlBits & 8)   // down
			{
				reqBuffer[0] |= 2;
				gBuffer[0]   |= 2;  // added for WritePipe support 27Jan2007
			}
			if ((controlBits & 16) || (controlBits & 128))  // Fire
			{
				reqBuffer[0] |= 16;
				gBuffer[0]   |= 16;  // added for WritePipe support 27Jan2007
				if (debugCommands)
				{
					NSLog(@"USBMissileControl: MissileControl - DreamCheeky Fire initiated");
				}
			}
			
			reqBuffer[1] = 0x00;
			reqBuffer[2] = 0x00;
			reqBuffer[3] = 0x00;
			reqBuffer[4] = 0x00;
			reqBuffer[5] = 0x00;
			reqBuffer[6] = 0x00;
			reqBuffer[7] = 0x00;
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = 0x09; 
			devRequest.wValue = 0x0000200;
			devRequest.wIndex = 0;
			devRequest.wLength = 1;
			devRequest.pData = reqBuffer; 
			if (debugCommands)
			{
				NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
				NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
				NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
				NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
				NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
				NSLog(@"USBMissileControl: DreamCheeky command package (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
			}
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (debugCommands)
			{
				if (kr != kIOReturnSuccess)
				{
					if (kr == kIOReturnNoDevice)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
					} else
						if (kr == kIOReturnNotOpen)
						{
							if (debugCommands) 
								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
						} else
						{   // Error seems to be generated from this and I can't figure out why
							// USBMissileControl: EvaluateUSBErrorCode: kIOReturnOverrun (0xe00002e8) - There has been a data overrun.
							// It all seems to still work, so I'm going to ignore it.
							
						//	NSLog(@"USBMissileControl: ERROR delivering command package");
						//	EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
						}
				}
			}
						
			if (controlBits & 16)
			{
				// Need to stop the fire sequence - otherwise it continues without stopping
				// if we read (or look for feedback from the launcher) it will tell us when the fire has completed
				//
				// readPipe: message: 00 00 00 00 00 00 00 00 
				// readPipe: message: 00 80 00 00 00 00 00 00 
				// readPipe: message: 00 00 00 00 00 00 00 00 
				//
				// byte #2 is the fire acknowledgement

				//[self DGWScheduleCancelLauncherCommand:5.500]; // this was the old code before the launcher feedback was being read

				int delayCounter;
				for (delayCounter = 0; delayCounter < 70; delayCounter ++)
				{
					[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.100]];
//					kr = DreamCheekyReadPipe(missileDevice, missileInterface, rBuffer);
					DreamCheekyReadPipe(missileDevice, missileInterface, rBuffer);
					if (rBuffer[1] >= 0x80)
					{
						// The 0x80 status doesn't always mean that firing has occurred, but it will be very close
						// - wait at least 500ms before sending the NULL after receiving 0x80
						[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.000]];
						// Fire command completed
						// send the third package - NULL
						reqBuffer[0] = 0;
						reqBuffer[1] = 0;
						reqBuffer[2] = 0;
						reqBuffer[3] = 0;
						reqBuffer[4] = 0;
						reqBuffer[5] = 0;
						reqBuffer[6] = 0;
						reqBuffer[7] = 0;
						devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
						devRequest.bRequest = 0x09; 
						devRequest.wValue = 0x0000200;
						devRequest.wIndex = 0;
						devRequest.wLength = 8;
						devRequest.pData = reqBuffer; 
						if (debugCommands)
						{
							NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
							NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
							NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
							NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
							NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
							NSLog(@"USBMissileControl: DreamCheeky command package (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
						}
						kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
						if (debugCommands)
						{
							if (kr != kIOReturnSuccess)
							{
								if (kr == kIOReturnNoDevice)
								{
									if (debugCommands) 
										NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
								} else
								if (kr == kIOReturnNotOpen)
								{
									if (debugCommands) 
										NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
								} else
								{
									EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
								}
							}	
						}
						
						break;
					}

				}
				
			}

			if (controlBits & 128)
			{
				// Need to stop the fire sequence - otherwise it continues without stopping
				// What we're trying to do here is prime the launcher for firing
				// So we don't actually want to FIRE
				
				int delayCounter;
				for (delayCounter = 0; delayCounter < 35; delayCounter ++)  // 3.5 seconds
				{
					[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:0.100]];
				}
				
				// send a NULL package to shut things down.
				reqBuffer[0] = 0;
				reqBuffer[1] = 0;
				reqBuffer[2] = 0;
				reqBuffer[3] = 0;
				reqBuffer[4] = 0;
				reqBuffer[5] = 0;
				reqBuffer[6] = 0;
				reqBuffer[7] = 0;
				devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
				devRequest.bRequest = 0x09; 
				devRequest.wValue = 0x0000200;
				devRequest.wIndex = 0;
				devRequest.wLength = 8;
				devRequest.pData = reqBuffer; 
				if (debugCommands)
				{
					NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
					NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
					NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
					NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
					NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
					NSLog(@"USBMissileControl: DreamCheeky command package (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
				}
				kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
				if (debugCommands)
				{
					if (kr != kIOReturnSuccess)
					{
						if (kr == kIOReturnNoDevice)
						{
							if (debugCommands) 
								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
						} else
						if (kr == kIOReturnNotOpen)
						{
							if (debugCommands) 
								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
						} else
						{
							EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
						}
					}	
				}
			}			
			
			// ===========================================================================
			// END OF USB Rocket Launcher - DreamCheeky
			// ===========================================================================
		}			

		else 
//			if ([privateDataRef getusbVendorID] == kUSBRocketVendorID &&
//				[privateDataRef getusbProductID] == kUSBRocketProductID)
			
#pragma mark DreamRocketII
			
		if ([[privateDataRef getLauncherType] isEqualToString:@"DreamRocketII"])
		{

			// This code is here because I need to know the launcher type so that the right launcher can be parked
			// So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
			if (controlBits & 32)  // Park
			{
				//NSLog(@"USBMissileControl: MissileControl - DreamCheeky Park");
				// controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
				[self DreamCheeky_Park];
				return self;
			}
			
			// ===========================================================================
			// Control of USB Rocket Launcher - DreamCheeky II  (Rocket Baby)
			// ===========================================================================
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: launcherType = %@", [privateDataRef getLauncherType]);
				NSLog(@"USBMissileControl: USBVendorID  = %ld (0x%ld)", [privateDataRef getusbVendorID], [privateDataRef getusbVendorID]);
				NSLog(@"USBMissileControl: USBProductID = %ld (0x%ld)", [privateDataRef getusbProductID], [privateDataRef getusbProductID]);
//				NSLog(@"USBMissileControl: device       = (0x%x)", [privateDataRef deviceInterface]);
				NSLog(@"USBMissileControl: controlBits  = %d", controlBits);
			}
			
			// USBVendorID  = 2689 (0xa81)
			// USBProductID = 1793 (0x701)

			// Control of the launcher works on a binary code - see the table below for an explanation
			//
// Set up Packet - 21 09 00 02 00 00 00 00
//
// 0x01  - down
// 0x02  - up
// 0x04  - left
// 0x08  - right
// 0x10  - fire
// 0x20  - stop
// 0x40  - request status
//
//	1. To fire, Send 0x10
//  2. The motor keeps working now, keep sending 0x40 to ask for status (say, every 100~500ms)
//	3. If 0x00 received, then the missile is not fired.
//	4. If 0x10 received, them missile is fired.
//	5. If the missile is fired, send 0x20 to stop it.
//		
//  Other launcher Responses - these are returned as bits and thus you need to check like "if (rbBuffer[0] & 0x01)" using Bitwise AND
//  0x01 - all the way down
//  0x02 - all the way up
//  0x04 - all the way left
//  0x08 - all the way right
//  0x10 - fire has completed
			//  			
			//	The user has to use a USB Control Endpoint to send the command and to use the USB IN endpoint to read the status.
			//
			//     |  16  | 8 | 4 | 2 | 1 |
			//     |------|---|---|---|---|
			//     |   0  | 0 | 0 | 0 | 1 |    1 - Down
			//     |   0  | 0 | 0 | 1 | 0 |    2 - Up
			//     |   0  | 0 | 1 | 0 | 0 |    4 - Left
			//     |   0  | 1 | 0 | 0 | 0 |    8 - Right
			//     |   0  | 1 | 0 | 1 | 0 |   10 - Fire
			//     |   1  | 0 | 1 | 0 | 0 |   20 - Stop
			//
			//     | Fire |RT |LT |UP |DN |
			//
			

			// Lets see if we have reached the end of a travel direction
			// If we have, we need to discontinue moving in that direction
			// So we have likely received a request to move up for example, so lets cancel that.
			rbBuffer[0] = 0x00;
			kr = RocketBabyReadPipe(missileDevice, missileInterface, rbBuffer);
			if (kr != kIOReturnSuccess)
			{
				if (debugCommands)
					NSLog(@"USBMissileControl: ERROR returned from DreamCheekyReadPipe kr=(0x%08x)", kr);
			} else
			{	
				if (debugCommands)
					NSLog(@"USBMissileControl: return from RocketBabyReadPipe (0x%02x)", rbBuffer[0]);
			}
				
//			Left		controlBits |= 1;
//			Right		controlBits |= 2;
//			Up			controlBits |= 4;
//			Down		controlBits |= 8;
//			Fire		controlBits |= 16;
//			NSLog(@"USBMissileControl: controlBits %d", controlBits);

			if (rbBuffer[0] & 0x01)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
			{
				if (controlBits & 8)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional down request");
					controlBits = controlBits ^8;
				}
			} else 
			if (rbBuffer[0] & 0x02)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
			{
				if (controlBits & 4)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional up request");
					controlBits = controlBits ^4;
				}
			}
			if (rbBuffer[0] & 0x04)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
			{
				if (controlBits & 1)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional left request");
					controlBits = controlBits ^1;
				}
			} else 
			if (rbBuffer[0] & 0x08)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
			{
				if (controlBits & 2)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional right request");
					controlBits = controlBits ^2;
				}
			}
			if (debugCommands)
				NSLog(@"USBMissileControl: controlBits %d", controlBits);
			
			
			// send the package - contains actual instruction
			reqBuffer_RB[0] = 0x00; 
			if (controlBits == 0)   // Launcher STOP (so if no command is sent, we instruct STOP)
			{
				reqBuffer_RB[0] = 0x20;
			}
			
			// this launcher does not understand "Up & Left" type commands together. The software simulates it and will get the
			// desired end result, however the launcher cannot drive 2 x servo motors at once using the command set available.
			if (controlBits & 1)   // left
			{
				reqBuffer_RB[0] = 4;
			}
			if (controlBits & 2)   // right
			{
				reqBuffer_RB[0] = 8;
			}
			if (controlBits & 4)   // up
			{
				reqBuffer_RB[0] = 2;
			}
			if (controlBits & 8)   // down
			{
				reqBuffer_RB[0] = 1;
			}


			if ((controlBits & 16) || (controlBits & 128)) // Fire
			{
				reqBuffer_RB[0] = 0x10;
				if (debugCommands)
				{
					NSLog(@"USBMissileControl: MissileControl - DreamCheeky Fire (or Prime) initiated");
				}
			}
			
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = 0x09; 
			devRequest.wValue = 0x0000200;
			devRequest.wIndex = 0;
			devRequest.wLength = 1;
			devRequest.pData = reqBuffer_RB; 
			if (debugCommands)
			{
				NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
				NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
				NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
				NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
				NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
				NSLog(@"USBMissileControl: Rocket Baby command package (0x%02x) delivered", reqBuffer_RB[0]);
				if( debugCommands && reqBuffer_RB[0] == 0x00)
					NSLog(@"USBMissileControl: controlBits (0x%04x)", controlBits);
			}
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (kr != kIOReturnSuccess)
			{
				if (kr == kIOReturnNoDevice)
				{
					if (debugCommands) 
						NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
				} else
				if (kr == kIOReturnNotOpen)
				{
					if (debugCommands) 
						NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
				} else
				{
					EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
				}
			}
									
			if (controlBits & 16)
			{
				// Need to stop the fire sequence - otherwise it continues without stopping
				// if we read (or look for feedback from the launcher) it will tell us when the fire has completed
				//
				int delayCounter;
				for (delayCounter = 0; delayCounter < 500; delayCounter ++)
				{
					//[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:0.100]];
					rbBuffer[0] = 0x00;
					kr = RocketBabyReadPipe(missileDevice, missileInterface, rbBuffer);
					if (kr != kIOReturnSuccess)
					{
						// error output has already been produced c/- RocketBabyReadPipe
						break;
					}
					
					if (rbBuffer[0] & 0x10)
					{
						// The 0x10 status doesn't always mean that firing has occurred, but it will be very close
						// - wait at least 500ms before sending 0x20 after receiving 0x10
						[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.500]];
						
						// Fire command completed
						// send the third package - 0x20
						reqBuffer_RB[0] = 0x20;
						devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
						devRequest.bRequest = 0x09; 
						devRequest.wValue = 0x0000200;
						devRequest.wIndex = 0;
						devRequest.wLength = 1;
						devRequest.pData = reqBuffer_RB; 
						if (debugCommands)
						{
							//NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
							//NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
							//NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
							//NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
							//NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
							NSLog(@"USBMissileControl: Rocket Baby command package (0x%02x) delivered", reqBuffer_RB[0]);
						}
						kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
						if (kr != kIOReturnSuccess)
						{
							if (kr == kIOReturnNoDevice)
							{
								if (debugCommands) 
									NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
							} else
							if (kr == kIOReturnNotOpen)
							{
								if (debugCommands) 
									NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
							} else
							{
								EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
							}
						}	
						
						break;
					}

				}
				
			}	
			
			if (controlBits & 128) // Prime Launcher
			{
				// Need to stop the prime sequence - otherwise it continues without stopping
				// if we read (or look for feedback from the launcher) it will tell us when the fire has completed
				//
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
						
				// Fire command completed
				// send the third package - 0x20
				reqBuffer_RB[0] = 0x20;
				devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
				devRequest.bRequest = 0x09; 
				devRequest.wValue = 0x0000200;
				devRequest.wIndex = 0;
				devRequest.wLength = 1;
				devRequest.pData = reqBuffer_RB; 
				if (debugCommands)
				{
				//	NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
				//	NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
				//	NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
				//	NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
				//	NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
					NSLog(@"USBMissileControl: Rocket Baby command package (0x%02x) delivered", reqBuffer_RB[0]);
				}
				kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
				if (kr != kIOReturnSuccess)
				{
					if (kr == kIOReturnNoDevice)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
					} else
					if (kr == kIOReturnNotOpen)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
					} else
					{
						EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
					}
				}	
						
			}
			// ===========================================================================
			// END OF USB Rocket Launcher - DreamCheeky II (Rocket Baby)
			// ===========================================================================
		}			

		else 
		//			if ([privateDataRef getusbVendorID] == kUSBRocketVendorID &&
		//				[privateDataRef getusbProductID] == kUSBRocketProductID)
		
#pragma mark OICStorm
		
		if ([[privateDataRef getLauncherType] isEqualToString:@"OICStorm"])
		{
			
			// This code is here because I need to know the launcher type so that the right launcher can be parked
			// So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
			if (controlBits & 32)  // Park
			{
				//NSLog(@"USBMissileControl: MissileControl - DreamCheeky Park");
				// controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
				[self DreamCheeky_Park];
				return self;
			}
			
			// ===========================================================================
			// Control of USB Rocket Launcher - DreamCheeky OIC Storm
			// ===========================================================================
			if (debugCommands)
			{
				NSLog(@"USBMissileControl: -------------- new command instruction --------------");
				NSLog(@"USBMissileControl: launcherType = %@", [privateDataRef getLauncherType]);
				NSLog(@"USBMissileControl: USBVendorID  = %ld (0x%ld)", [privateDataRef getusbVendorID], [privateDataRef getusbVendorID]);
				NSLog(@"USBMissileControl: USBProductID = %ld (0x%ld)", [privateDataRef getusbProductID], [privateDataRef getusbProductID]);
//				NSLog(@"USBMissileControl: device       = (0x%x)", [privateDataRef deviceInterface]);
				NSLog(@"USBMissileControl: controlBits  = %d", controlBits);
			}
			
			// USBVendorID  = 2689 (0xa81)
			// USBProductID = 1793 (0x701)
			
			// Control of the launcher works on a binary code - see the table below for an explanation
			//
			// Set up Packet - 21 09 00 02 00 00 00 00
			//
			// 0x01  - down
			// 0x02  - up
			// 0x04  - left
			// 0x08  - right
			// 0x10  - fire
			// 0x20  - stop
			// 0x40  - request status
			//
			//	1. To fire, Send 0x10
			//  2. The motor keeps working now, keep sending 0x40 to ask for status (say, every 100~500ms)
			//	3. If 0x00 received, then the missile is not fired.
			//	4. If 0x10 received, them missile is fired.
			//	5. If the missile is fired, send 0x20 to stop it.
			//		
			//  Other launcher Responses - these are returned as bits and thus you need to check like "if (rbBuffer[0] & 0x01)" using Bitwise AND
			//  0x01 - all the way down
			//  0x02 - all the way up
			//  0x04 - all the way left
			//  0x08 - all the way right
			//  0x10 - fire has completed
			//  			
			//	The user has to use a USB Control Endpoint to send the command and to use the USB IN endpoint to read the status.
			//
			//     |  16  | 8 | 4 | 2 | 1 |
			//     |------|---|---|---|---|
			//     |   0  | 0 | 0 | 0 | 1 |    1 - Down
			//     |   0  | 0 | 0 | 1 | 0 |    2 - Up
			//     |   0  | 0 | 1 | 0 | 0 |    4 - Left
			//     |   0  | 1 | 0 | 0 | 0 |    8 - Right
			//     |   0  | 1 | 0 | 1 | 0 |   10 - Fire
			//     |   1  | 0 | 1 | 0 | 0 |   20 - Stop
			//
			//     | Fire |RT |LT |UP |DN |
			//
			
			
			// Lets see if we have reached the end of a travel direction
			// If we have, we need to discontinue moving in that direction
			// So we have likely received a request to move up for example, so lets cancel that.
			sbBuffer[0] = 0x00;
			sbBuffer[1] = 0x00;
//			kr = OICStormReadPipe(missileDevice, missileInterface, rbBuffer);
//			if (kr != kIOReturnSuccess)
//			{
//				if (debugCommands)
//					NSLog(@"USBMissileControl: ERROR returned from OICStormReadPipe kr=(0x%08x)", kr);
//			} else
//			{	
//				if (debugCommands)
//					NSLog(@"USBMissileControl: return from OICStormReadPipe (0x%02x)", rbBuffer[0]);
//			}
			
			//			Left		controlBits |= 1;
			//			Right		controlBits |= 2;
			//			Up			controlBits |= 4;
			//			Down		controlBits |= 8;
			//			Fire		controlBits |= 16;
			//			NSLog(@"USBMissileControl: controlBits %d", controlBits);
			
			if (sbBuffer[1] & 0x01)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
			{
				if (controlBits & 8)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional down request");
					controlBits = controlBits ^8;
				}
			} else 
				if (sbBuffer[1] & 0x02)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
				{
					if (controlBits & 4)
					{
						if (debugCommands)
							NSLog(@"USBMissileControl: cancelling additional up request");
						controlBits = controlBits ^4;
					}
				}
			if (sbBuffer[1] & 0x04)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
			{
				if (controlBits & 1)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional left request");
					controlBits = controlBits ^1;
				}
			} else 
			if (sbBuffer[1] & 0x08)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
			{
				if (controlBits & 2)
				{
					if (debugCommands)
						NSLog(@"USBMissileControl: cancelling additional right request");
					controlBits = controlBits ^2;
				}
			}
//			if (debugCommands)
//				NSLog(@"USBMissileControl: controlBits %d", controlBits);
			
			
			// send the package - contains actual instruction
			reqBuffer_RB[0] = 0x02;
			reqBuffer_RB[1] = 0x00;
			reqBuffer_RB[2] = 0x00;
			reqBuffer_RB[3] = 0x00;
			reqBuffer_RB[4] = 0x00;
			reqBuffer_RB[5] = 0x00;
			reqBuffer_RB[6] = 0x00;
			reqBuffer_RB[7] = 0x00;
			if (controlBits == 0)   // Launcher STOP (so if no command is sent, we instruct STOP)
			{
				reqBuffer_RB[1] = 0x20;
			}
			
			// this launcher does not understand "Up & Left" type commands together. The software simulates it and will get the
			// desired end result, however the launcher cannot drive 2 x servo motors at once using the command set available.
			if (controlBits & 1)   // left
			{
				reqBuffer_RB[1] = 0x04;
				if (debugCommands)
					NSLog(@"USBMissileControl: controlBits %d - Left   <----------------", controlBits);
			}
			if (controlBits & 2)   // right
			{
				reqBuffer_RB[1] = 0x08;
				if (debugCommands)
					NSLog(@"USBMissileControl: controlBits %d - Right   <----------------", controlBits);
			}
			if (controlBits & 4)   // up
			{
				reqBuffer_RB[1] = 0x02;
				if (debugCommands)
					NSLog(@"USBMissileControl: controlBits %d - Up   <----------------", controlBits);
			}
			if (controlBits & 8)   // down
			{
				reqBuffer_RB[1] = 0x01;
				if (debugCommands)
					NSLog(@"USBMissileControl: controlBits %d - Down   <----------------", controlBits);
			}
			
			
			if ((controlBits & 16) || (controlBits & 128)) // Fire
			{
				reqBuffer_RB[1] = 0x10;
				if (debugCommands)
				{
					NSLog(@"USBMissileControl: MissileControl: OIC Storm - Fire (or Prime) initiated");
				}
			}
			
			devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
			devRequest.bRequest = 0x09; 
			devRequest.wValue = 0x0000200;
			devRequest.wIndex = 0;
			devRequest.wLength = 8;
			devRequest.pData = reqBuffer_RB; 
			if (debugCommands)
			{
				NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
				NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
				NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
				NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
				NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
				NSLog(@"USBMissileControl: OIC Storm command package (0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x) delivered", reqBuffer_RB[0], reqBuffer_RB[1], reqBuffer_RB[2], reqBuffer_RB[3], reqBuffer_RB[4], reqBuffer_RB[5], reqBuffer_RB[6], reqBuffer_RB[7]);
				if( debugCommands && reqBuffer_RB[0] == 0x02)
					NSLog(@"USBMissileControl: controlBits (0x%04x)", controlBits);
			}
			kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
			if (debugCommands)
			{
				if (kr != kIOReturnSuccess)
				{
					if (kr == kIOReturnNoDevice)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
					} else
					if (kr == kIOReturnNotOpen)
					{
						if (debugCommands) 
							NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
					} else
					{
						EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
					}
				}
			}
			
//			if (controlBits & 16)
//			{
//				// Need to stop the fire sequence - otherwise it continues without stopping
//				// if we read (or look for feedback from the launcher) it will tell us when the fire has completed
//				//
//				
//				int delayCounter;
//				for (delayCounter = 0; delayCounter < 500; delayCounter ++)
//				{
//					//[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:0.100]];
//					rbBuffer[0] = 0x00;
//					rbBuffer[1] = 0x00;
//
//					kr = OICStormReadPipe(missileDevice, missileInterface, rbBuffer);
//					if (kr != kIOReturnSuccess)
//						break;
//					
//					if (kr == kIOReturnSuccess && rbBuffer[1] & 0x10)
//					{
//						// The 0x10 status doesn't always mean that firing has occurred, but it will be very close
//						// - wait at least 500ms before sending 0x20 after receiving 0x10
//						[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.500]];
//						
//						// Fire command completed
//						// send the third package - 0x20
//						reqBuffer_RB[0] = 0x02;
//						reqBuffer_RB[1] = 0x20;
//						reqBuffer_RB[2] = 0x00;
//						reqBuffer_RB[3] = 0x00;
//						reqBuffer_RB[4] = 0x00;
//						reqBuffer_RB[5] = 0x00;
//						reqBuffer_RB[6] = 0x00;
//						reqBuffer_RB[7] = 0x00;
//						devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
//						devRequest.bRequest = 0x09; 
//						devRequest.wValue = 0x0000200;
//						devRequest.wIndex = 0;
//						devRequest.wLength = 8;
//						devRequest.pData = reqBuffer_RB; 
//						if (debugCommands)
//						{
//							//NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//							//NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//							//NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//							//NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//							//NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//							NSLog(@"USBMissileControl: OIC Storm command package (0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x) delivered", reqBuffer_RB[0], reqBuffer_RB[1], reqBuffer_RB[2], reqBuffer_RB[3], reqBuffer_RB[4], reqBuffer_RB[5], reqBuffer_RB[6], reqBuffer_RB[7]);
//						}
//						kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//						
//						if (kr != kIOReturnSuccess)
//						{
//							if (kr == kIOReturnNoDevice)
//							{
//								if (debugCommands) 
//									NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//							} else
//							if (kr == kIOReturnNotOpen)
//							{
//								if (debugCommands) 
//									NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//							} else
//							{
//								EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//							}
//						}	
//						
//						break;
//					}
//					
//				}
//				
//			}	
			
//			if (controlBits & 128) // Prime Launcher
//			{
//				// Need to stop the fire sequence - otherwise it continues without stopping
//				// if we read (or look for feedback from the launcher) it will tell us when the fire has completed
//				//
//				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
//				
//				// Fire command completed
//				// send the third package - 0x20
//				reqBuffer_RB[0] = 0x02;
//				reqBuffer_RB[1] = 0x20;
//				reqBuffer_RB[2] = 0x00;
//				reqBuffer_RB[3] = 0x00;
//				reqBuffer_RB[4] = 0x00;
//				reqBuffer_RB[5] = 0x00;
//				reqBuffer_RB[6] = 0x00;
//				reqBuffer_RB[7] = 0x00;
//				devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
//				devRequest.bRequest = 0x09; 
//				devRequest.wValue = 0x0000200;
//				devRequest.wIndex = 0;
//				devRequest.wLength = 8;
//				devRequest.pData = reqBuffer_RB; 
//				if (debugCommands)
//				{
//					//	NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//					//	NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//					//	NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//					//	NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//					//	NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//					NSLog(@"USBMissileControl: OIC Storm command package (0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x) delivered", reqBuffer_RB[0], reqBuffer_RB[1], reqBuffer_RB[2], reqBuffer_RB[3], reqBuffer_RB[4], reqBuffer_RB[5], reqBuffer_RB[6], reqBuffer_RB[7]);
//				}
//				kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//				if (debugCommands)
//				{
//					if (kr != kIOReturnSuccess)
//					{
//						if (kr == kIOReturnNoDevice)
//						{
//							if (debugCommands) 
//								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//						} else
//						if (kr == kIOReturnNotOpen)
//						{
//							if (debugCommands) 
//								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//						} else
//						{
//							EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//						}
//					}	
//				}
//				
//			}
			// ===========================================================================
			// END OF USB Rocket Launcher - DreamCheeky OIC Storm
			// ===========================================================================
		}
		
	} // for loop - number of items in launcherDevice array
		
	return self;
}

IOReturn DreamCheekyReadPipe(IOUSBDeviceInterface **missileDevice, IOUSBInterfaceInterface **missileInterface, UInt8 *rBuffer)
{
    IOReturn                    kr;
    UInt32                      bytesRead;
	Boolean						debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];
	
	if (debugCommands)
		NSLog(@"USBMissileControl: DreamCheekyReadPipe: GetPipeStatus");
	
	if (missileInterface == nil)
	{
		NSLog(@"USBMissileControl: DreamCheekyReadPipe: No Missile Interface - IGNORING REQUEST");
		return 1;
	}
	
	kr = (*missileInterface)->GetPipeStatus(missileInterface, 1);
	if (kr != kIOReturnSuccess)
	{
		if (kr == kIOReturnNoDevice)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: DreamCheekyReadPipe: kIOReturnNoDevice");
		} else
			if (kr == kIOReturnNotOpen)
			{
				if (debugCommands)
					NSLog(@"USBMissileControl: DreamCheekyReadPipe: kIOReturnNotOpen");
			} else
			{
				EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
			}
	}
	
	// You cant get the size of an array in C
	// therefore do what I've done here and use the size from the #define
	// or pass in the size of the array as another parameter to the function
	// See comments at end for details
	bzero(rBuffer, dreamCheekyMaxPacketSize);
	bytesRead = dreamCheekyMaxPacketSize;
	//	NSLog(@"USBMissileControl: DreamCheekyReadPipe: value of rBuffer bytesRead %x", bytesRead);
	
	if (debugCommands)
		NSLog(@"USBMissileControl: DreamCheekyReadPipe: ReadPipe -> bytesRead setup=%lu", bytesRead);
	kr = (*missileInterface)->ReadPipe(missileInterface, 1, rBuffer, &bytesRead);
	if (kr != kIOReturnSuccess)
	{
		if (kr == kIOReturnNoDevice)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: DreamCheekyReadPipe: kIOReturnNoDevice");
		} else
			if (kr == kIOReturnNotOpen)
			{
				if (debugCommands)
					NSLog(@"USBMissileControl: DreamCheekyReadPipe: kIOReturnNotOpen");
			} else
			{
				EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
			}
	}
	else
	{
		if (debugCommands)
			NSLog(@"USBMissileControl: readpipe result: 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x", rBuffer[0], rBuffer[1], rBuffer[2], rBuffer[3], rBuffer[4], rBuffer[5], rBuffer[6], rBuffer[7]);

		if (rBuffer[0] & 0x40)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: All the way down");
		} else 
		if (rBuffer[0] == 0x80)
		{	
			if (debugCommands)
				NSLog(@"USBMissileControl: All the way up");
		}

		if ((rBuffer[1] == 0x04) || (rBuffer[1] == 0x84))  // this command response can get mixed up with Fire
		{	
			if (debugCommands)
				NSLog(@"USBMissileControl: All the way left");
		} else 
		if ((rBuffer[1] == 0x08) || (rBuffer[1] == 0x88))  // this command response can get mixed up with Fire
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: All the way right");
		}

		if (rBuffer[1] >= 0x80)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: Fire has completed (0x%02x)", rBuffer[1]);
		}
		
	}
	return kr;
}	

IOReturn RocketBabyReadPipe(IOUSBDeviceInterface **missileDevice, IOUSBInterfaceInterface **missileInterface, UInt8 *rBuffer)
{
    IOReturn                    kr;
    UInt32                      bytesRead;
	UInt8						reqBuffer[1];
	IOUSBDevRequest				devRequest;

	Boolean						debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];
	
	reqBuffer[0] = 0x40;
	devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
	devRequest.bRequest = 0x09; 
	devRequest.wValue = 0x0000200;
	devRequest.wIndex = 0;
	devRequest.wLength = 1;
	devRequest.pData = reqBuffer; 
	if (debugCommands)
	{
	//	NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
	//	NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
	//	NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
	//	NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
	//	NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
		NSLog(@"USBMissileControl: RocketBabyReadPipe: send -->(0x%02x)", reqBuffer[0]);
	}
	
	if (missileInterface == nil)
	{
		NSLog(@"USBMissileControl: RocketBabyReadPipe: No Missile Interface - IGNORING REQUEST");
		return 1;
	}
	
	kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
	if (kr != kIOReturnSuccess)
	{
		if (kr == kIOReturnNoDevice)
		{
			if (debugCommands) 
				NSLog(@"USBMissileControl: IOReturn: kIOReturnNoDevice");
		} else
			if (kr == kIOReturnNotOpen)
			{
				if (debugCommands) 
					NSLog(@"USBMissileControl: IOReturn: kIOReturnNotOpen");
			} else
			{
				EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
			}
	}	
	
	
	// the GetPipeStatus when issued to the Rocket Baby crashes the application - DGW 17Nov07
	if (debugCommands)
		NSLog(@"USBMissileControl: RocketBabyReadPipe: GetPipeStatus");

	if (debugCommands)
		NSLog(@"USBMissileControl: RocketBabyReadPipe: pipeRef = 1");

	
	// You cant get the size of an array in C
	// therefore do what I've done here and use the size from the #define
	// or pass in the size of the array as another parameter to the function
	// See comments at end for details
	bzero(rBuffer, rocketBabyMaxPacketSize);
	bytesRead = rocketBabyMaxPacketSize;  // leave one byte at the end for NULL termination

	//	NSLog(@"USBMissileControl: DreamCheekyReadPipe: value of rBuffer bytesRead %x", bytesRead);
	
	if (debugCommands)
		NSLog(@"USBMissileControl: RocketBabyReadPipe: ReadPipe");
	
	kr = (*missileInterface)->ReadPipe(missileInterface, 1, rBuffer, &bytesRead);
	if (kr != kIOReturnSuccess)
	{
		if (kr == kIOReturnNoDevice)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: RocketBabyReadPipe: kIOReturnNoDevice");
		} else
			if (kr == kIOReturnNotOpen)
			{
				if (debugCommands)
					NSLog(@"USBMissileControl: RocketBabyReadPipe: kIOReturnNotOpen");
			} else
			{
				EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
				if (debugCommands)
					NSLog(@"USBMissileControl: RocketBabyReadPipe: (0x%02x)", rBuffer[0]);
			}
	}
	else
	{
		if (debugCommands)
			NSLog(@"USBMissileControl: RocketBabyReadPipe: recieve -->(0x%02x)", rBuffer[0]);
				
		if (rBuffer[0] >= 0x10)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: RocketBabyReadPipe: Fire has completed (0x%02x)", rBuffer[0]);
		}
		
	}
	return kr;
}	

IOReturn OICStormReadPipe(IOUSBDeviceInterface **missileDevice, IOUSBInterfaceInterface **missileInterface, UInt8 *rBuffer)
{
    IOReturn                    kr;
    UInt32                      bytesRead;
	UInt8						reqBuffer[8];
	IOUSBDevRequest				devRequest;
	
	Boolean						debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];

	//	if (missileInterface == nil)
	//	{
	//		NSLog(@"USBMissileControl: OICStormReadPipe: No Missile Interface - IGNORING REQUEST");
	//		return 1;
	//	}
	//	

	reqBuffer[0] = 0x01;
	reqBuffer[1] = 0x00;
	reqBuffer[2] = 0x00;
	reqBuffer[3] = 0x00;
	reqBuffer[4] = 0x00;
	reqBuffer[5] = 0x00;
	reqBuffer[6] = 0x00;
	reqBuffer[7] = 0x00;
	devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface); 
	devRequest.bRequest = 0x09; 
	devRequest.wValue = 0x0000200;
	devRequest.wIndex = 0;
	devRequest.wLength = 8;
	devRequest.pData = reqBuffer; 
	if (debugCommands)
	{
		//	NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
		//	NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
		//	NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
		//	NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
		//	NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
		NSLog(@"USBMissileControl: OICStormReadPipe: send -->(0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
	}
	kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
	if (kr != kIOReturnSuccess)
	{
		if (kr == kIOReturnNoDevice)
		{
			if (debugCommands) 
				NSLog(@"USBMissileControl: OICStormReadPipe: IOReturn: kIOReturnNoDevice");
		} else
		if (kr == kIOReturnNotOpen)
		{
			if (debugCommands) 
				NSLog(@"USBMissileControl: OICStormReadPipe: IOReturn: kIOReturnNotOpen");
		} else
		{
			EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
		}
	}	
	
	
	// You cant get the size of an array in C
	// therefore do what I've done here and use the size from the #define
	// or pass in the size of the array as another parameter to the function
	// See comments at end for details
	bzero(rBuffer, dreamCheekyMaxPacketSize);
	bytesRead = 0;
	
	//	NSLog(@"USBMissileControl: DreamCheekyReadPipe: value of rBuffer bytesRead %x", bytesRead);
	
	if (debugCommands)
		NSLog(@"USBMissileControl: OICStormReadPipe: ReadPipe");
	
	kr = (*missileInterface)->ReadPipe(missileInterface, 1, rBuffer, &bytesRead);
	if (kr != kIOReturnSuccess)
	{
		if (kr == kIOReturnNoDevice)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: OICStormReadPipe: kIOReturnNoDevice");
		} else
		if (kr == kIOReturnNotOpen)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: OICStormReadPipe: kIOReturnNotOpen");
		} else
		{
			EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
			if (debugCommands)
				NSLog(@"USBMissileControl: OICStormReadPipe: (0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x)", rBuffer[0], rBuffer[1], rBuffer[2], rBuffer[3], rBuffer[4], rBuffer[5], rBuffer[6], rBuffer[7]);
		}
	}
	else
	{
		if (debugCommands)
			NSLog(@"USBMissileControl: OICStormReadPipe: recieve -->(0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x)", rBuffer[0], rBuffer[1], rBuffer[2], rBuffer[3], rBuffer[4], rBuffer[5], rBuffer[6], rBuffer[7]);
		
		if (rBuffer[1] >= 0x10)
		{
			if (debugCommands)
				NSLog(@"USBMissileControl: OICStormReadPipe: Fire has completed (0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x)", rBuffer[0], rBuffer[1], rBuffer[2], rBuffer[3], rBuffer[4], rBuffer[5], rBuffer[6], rBuffer[7]);
		}
		
	}
	return kr;
}	

// I can't get the WritePipe to work for the DreamCheeky Launcher. I recieve "kIOUSBPipeStalled"
// as an error message.
// So for now I'm returning to the way it used to work.
// DGW 31 Jan 2007
IOReturn DreamCheekyWritePipe(int dataRefIndex, char *wBuffer)
{
    IOReturn                    kr;
    UInt32                      bytesToWrite;
	USBLauncher					*privateDataRef;
	IOUSBDeviceInterface        **missileDevice;
	IOUSBInterfaceInterface		**missileInterface;
		
	privateDataRef	 = [launcherDevice objectAtIndex: dataRefIndex];
	missileDevice	 = [privateDataRef deviceInterface];
	missileInterface = [privateDataRef missileInterface];
//	NSLog(@"USBMissileControl: DreamCheekyWritePipe: IOUSBDeviceInterface    (%08x)", missileDevice);
//	NSLog(@"USBMissileControl: DreamCheekyWritePipe: IOUSBInterfaceInterface (%08x)", missileInterface);
	
	
	NSLog(@"USBMissileControl: DreamCheekyWritePipe: GetPipeStatus");
	kr = (*missileInterface)->GetPipeStatus(missileInterface, 1);
	if (kr != kIOReturnSuccess)
	{
		if (kr == kIOReturnNoDevice)
		{
			NSLog(@"USBMissileControl: DreamCheekyWritePipe: kIOReturnNoDevice");
		} else
		if (kr == kIOReturnNotOpen)
		{
			NSLog(@"USBMissileControl: DreamCheekyWritePipe: kIOReturnNotOpen");
		} else
		{
			EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
		}
	}
	
//	NSLog(@"USBMissileControl: DreamCheekyWritePipe: value of rBuffer bytesRead %x", bytesRead);
	bytesToWrite = sizeof(gBuffer);
	
	NSLog(@"USBMissileControl: DreamCheekyWritePipe: WritePipe");
	NSLog(@"USBMissileControl: DreamCheekyWritePipe: gBuffer %d, %d, %d -- %lu", gBuffer[0], gBuffer[1], gBuffer[2], bytesToWrite);
	kr = (*missileInterface)->WritePipe(missileInterface, 1, gBuffer, bytesToWrite);
	//kIOReturnBadArgument (0xe00002c2) - There is an invalid argument.
	
//	kr = (*missileInterface)->WritePipeAsync(missileInterface, 1, gBuffer, bytesToWrite, WriteCompletion, (void *) missileInterface);
	if (kr != kIOReturnSuccess)
	{
		if (kr == kIOReturnNoDevice)
		{
			NSLog(@"USBMissileControl: DreamCheekyReadPipe: kIOReturnNoDevice");
		} else
			if (kr == kIOReturnNotOpen)
			{
				NSLog(@"USBMissileControl: DreamCheekyReadPipe: kIOReturnNotOpen");
			} else
			{
				EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
			}
	}
	else
	{
	}
	return kr;
}	


/*
WritePipe
Writes data on a BULK OUT or INTERRUPT OUT pipe.

IOReturn (*WritePipe)(
					  void *self,
					  UInt8 pipeRef,
					  void *buf,
					  UInt32 size);  
Parameters
self
Pointer to the IOUSBInterfaceInterface.
pipeRef
Index for the desired pipe (1 - GetNumEndpoints ).
buf
Buffer to hold the data.
size
The size of the data buffer.
Return Value
Returns kIOReturnSuccess if successful, kIOReturnNoDevice if there is no connection to an IOService, or kIOReturnNotOpen if the interface is not open for exclusive access.

Discussion
The interface must be open for the pipe to exist.
 
 
 ReadPipe
 Reads data on a BULK IN or an INTERRUPT pipe.
 
 IOReturn (*ReadPipe)(
					  void *self,
					  UInt8 pipeRef,
					  void *buf,
					  UInt32 *size);  
 Parameters
 self
 Pointer to the IOUSBInterfaceInterface.
 pipeRef
 Index for the desired pipe (1 - GetNumEndpoints ).
 buf
 Buffer to hold the data.
 size
 On entry: a pointer to the size of the buffer pointed to by buf. On exit: a pointer to the number of bytes actually read from the device.
 Return Value
 Returns kIOReturnSuccess if successful, kIOReturnNoDevice if there is no connection to an IOService, or kIOReturnNotOpen if the interface is not open for exclusive access.
 
 Discussion
 The interface must be open for the pipe to exist.
*/

/*

 | |   |   +-o IOUSBCompositeDevice@3d100000  <class IOUSBDevice, registered, matched, active, busy 0, retain count 9>
 | |   |     | {
 | |   |     |   "PortNum" = 1
 | |   |     |   "IOUserClientClass" = "IOUSBDeviceUserClient"
 | |   |     |   "Device Speed" = 0
 | |   |     |   "iSerialNumber" = 0
 | |   |     |   "Bus Power Available" = 250
 | |   |     |   "IOGeneralInterest" = "IOCommand is not serializable"
 | |   |     |   "bDeviceClass" = 0
 | |   |     |   "bNumConfigurations" = 1
 | |   |     |   "iManufacturer" = 0
 | |   |     |   "IOCFPlugInTypes" = {"9dc7b780-9ec0-11d4-a54f-000a27052861"="IOUSBFamily.kext/Contents/PlugIns/IOUSBLib.bundle"}
 | |   |     |   "bcdDevice" = 256
 | |   |     |   "bDeviceSubClass" = 0
 | |   |     |   "iProduct" = 0
 | |   |     |   "sessionID" = 2289993201107
 | |   |     |   "bMaxPacketSize0" = 8
 | |   |     |   "locationID" = 1024458752
 | |   |     |   "Need contiguous memory for isoch" = Yes
 | |   |     |   "idProduct" = 32801
 | |   |     |   "USB Address" = 2
 | |   |     |   "bDeviceProtocol" = 0
 | |   |     |   "idVendor" = 6465
 | |   |     | }
 | |   |     | 
 | |   |     +-o IOUSBCompositeDriver  <class IOUSBCompositeDriver, !registered, !matched, active, busy 0, retain count 4>
 | |   |     |   {
 | |   |     |     "IOMatchCategory" = "IODefaultMatchCategory"
 | |   |     |     "IOClass" = "IOUSBCompositeDriver"
 | |   |     |     "bDeviceClass" = 0
 | |   |     |     "bDeviceSubClass" = 0
 | |   |     |     "IOProviderClass" = "IOUSBDevice"
 | |   |     |     "CFBundleIdentifier" = "com.apple.driver.AppleUSBComposite"
 | |   |     |     "IOProbeScore" = 50000
 | |   |     |   }
 | |   |     |   
 | |   |     +-o IOUSBInterface@0  <class IOUSBInterface, registered, matched, active, busy 0, retain count 7>
 | |   |     | | {
 | |   |     | |   "IOUserClientClass" = "IOUSBInterfaceUserClient"
 | |   |     | |   "idProduct" = 32801
 | |   |     | |   "IOCFPlugInTypes" = {"2d9786c6-9ef3-11d4-ad51-000a27052861"="IOUSBFamily.kext/Contents/PlugIns/IOUSBLib.bundle"}
 | |   |     | |   "iInterface" = 0
 | |   |     | |   "bAlternateSetting" = 0
 | |   |     | |   "bConfigurationValue" = 1
 | |   |     | |   "IOUserClientCrossEndianCompatible" = No
 | |   |     | |   "bInterfaceProtocol" = 0
 | |   |     | |   "bInterfaceNumber" = 0
 | |   |     | |   "bInterfaceSubClass" = 0
 | |   |     | |   "idVendor" = 6465
 | |   |     | |   "bInterfaceClass" = 3
 | |   |     | |   "locationID" = 1024458752
 | |   |     | |   "bNumEndpoints" = 1
 | |   |     | |   "bcdDevice" = 256
 | |   |     | | }
 | |   |     | | 
 | |   |     | +-o IOService  <class IOService, !registered, !matched, active, busy 0, retain count 4>
 | |   |     | |   {
 | |   |     | |     "idProduct" = 32801
 | |   |     | |     "bConfigurationValue" = 1
 | |   |     | |     "CFBundleIdentifier" = "com.apple.kernel.iokit"
 | |   |     | |     "IOClass" = "IOService"
 | |   |     | |     "IOProbeScore" = 90000
 | |   |     | |     "IOMatchCategory" = "IODefaultMatchCategory"
 | |   |     | |     "bInterfaceNumber" = 0
 | |   |     | |     "idVendor" = 6465
 | |   |     | |     "IOProviderClass" = "IOUSBInterface"
 | |   |     | |   }
 | |   |     | |   
 | |   |     | +-o IOUSBUserClientInit  <class IOUSBUserClientInit, !registered, !matched, active, busy 0, retain count 4>
 | |   |     |     {
 | |   |     |       "IOMatchCategory" = "IOUSBUserClientInit"
 | |   |     |       "IOProbeScore" = 9000
 | |   |     |       "IOClass" = "IOUSBUserClientInit"
 | |   |     |       "IOProviderClass" = "IOUSBInterface"
 | |   |     |       "CFBundleIdentifier" = "com.apple.iokit.IOUSBUserClient"
 | |   |     |       "IOProviderMergeProperties" = {"IOUserClientClass"="IOUSBInterfaceUserClient","IOCFPlugInTypes"={"2d9786c6-9ef3-11d4-ad51-000a27052861"="IOUSBFamily.kext/Contents/PlugIns/IOUSBLib.bundle"}}
 | |   |     |     }
 | |   |     |     
 | |   |     +-o IOUSBUserClientInit  <class IOUSBUserClientInit, !registered, !matched, active, busy 0, retain count 4>
 | |   |         {
 | |   |           "IOMatchCategory" = "IOUSBUserClientInit"
 | |   |           "IOProbeScore" = 9000
 | |   |           "IOClass" = "IOUSBUserClientInit"
 | |   |           "IOProviderClass" = "IOUSBDevice"
 | |   |           "CFBundleIdentifier" = "com.apple.iokit.IOUSBUserClient"
 | |   |           "IOProviderMergeProperties" = {"IOUserClientClass"="IOUSBDeviceUserClient","IOCFPlugInTypes"={"9dc7b780-9ec0-11d4-a54f-000a27052861"="IOUSBFamily.kext/Contents/PlugIns/IOUSBLib.bundle"}}
 | |   |         }
 
*/

void EvaluateUSBErrorCode(IOUSBDeviceInterface **deviceInterface_param, IOUSBInterfaceInterface **missileInterface_param, IOReturn kr)
{
//	error code c/- usb.h
//	IOUSBFamily error codes

	Boolean						debugCommands;

	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];

	
	if (kr == kIOUSBUnknownPipeErr)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBUnknownPipeErr (0x%08x) - Pipe reference is not recognized", kr);
	} else
	if (kr == kIOUSBTooManyPipesErr)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBTooManyPipesErr (0x%08x) - There are too many pipes", kr);
	} else
	if (kr == kIOUSBNoAsyncPortErr)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBNoAsyncPortErr (0x%08x) - There is no asynchronous port", kr);
	} else
	if (kr == kIOUSBNotEnoughPipesErr)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBNotEnoughPipesErr (0x%08x) - There are not enough pipes in the interface", kr);
	} else
	if (kr == kIOUSBNotEnoughPowerErr)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBNotEnoughPowerErr (0x%08x) - There is not enough power for the selected configuration", kr);
	} else
	if (kr == kIOUSBEndpointNotFound)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBEndpointNotFound (0x%08x) - The endpoint has not been found", kr);
	} else
	if (kr == kIOUSBConfigNotFound)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBConfigNotFound (0x%08x) - The configuration has not been found", kr);
	} else
	if (kr == kIOUSBTransactionTimeout)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBTransactionTimeout (0x%08x) - The transaction has timed out", kr);
	} else
	if (kr == kIOUSBTransactionReturned)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBTransactionReturned (0x%08x) - The transaction has been returned to the caller", kr);
	} else
	if (kr == kIOUSBPipeStalled)
	{
		if (debugCommands)
		{
			NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBPipeStalled (0x%08x) - The pipe has stalled; the error needs to be cleared", kr);
		}
		ClearStalledPipe(missileInterface_param);
	} else
	if (kr == kIOUSBInterfaceNotFound)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBInterfaceNotFound (0x%08x) - The interface reference is not recognized", kr);
	} else
	if (kr == kIOUSBLowLatencyBufferNotPreviouslyAllocated)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBLowLatencyBufferNotPreviouslyAllocated (0x%08x) - Attempted to use user space low latency isochronous calls without first calling PrepareBuffer on the data buffer", kr);
	} else
	if (kr == kIOUSBLowLatencyFrameListNotPreviouslyAllocated)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBLowLatencyFrameListNotPreviouslyAllocated (0x%08x) - Attempted to use user space low latency isochronous calls without first calling PrepareBuffer on the frame list", kr);
	} else
	if (kr == kIOUSBHighSpeedSplitError)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBHighSpeedSplitError (0x%08x) - The hub received an error on a high speed bus trying to do a split transaction", kr);
	} else
	if (kr == kIOUSBSyncRequestOnWLThread)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOUSBSyncRequestOnWLThread (0x%08x) - A synchronous USB request was made on the work loop thread, perhaps from a callback. In this case, only asynchronous requests are permitted.", kr);
	} else
	if (kr == kIOReturnBadArgument)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOReturnBadArgument (0x%08x) - There is an invalid argument.", kr);
	} else
	if (kr == kIOReturnOverrun)
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: kIOReturnOverrun (0x%08x) - There has been a data overrun.", kr);
	} else
	{
		NSLog(@"USBMissileControl: EvaluateUSBErrorCode: Error Unknown (0x%08x)", kr);
	}
	return;
}

void ClearStalledPipe(IOUSBInterfaceInterface **missileInterface_param)
{
	IOReturn			kr;
	Boolean				debugCommands;

	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];

	
	kr = (*missileInterface_param)->ClearPipeStall(missileInterface_param, 1);
	if (debugCommands)
	{
		if (kIOReturnSuccess != kr) 
		{				
			NSLog(@"USBMissileControl: ClearStalledPipe: unable to ClearPipe error (0x%08x)", kr);
		} else
		{
			NSLog(@"USBMissileControl: ClearStalledPipe: ClearPipe success (0x%08x)", kr);
		}
	}

	return;
	
	/*
	 Subject: Re: What is a pipe stall && how to recover from it?
	 From: David Ferguson <email@hidden>
	 Date: Mon, 20 Dec 2004 15:26:05 -0800
	 Delivered-to: email@hidden
	 Delivered-to: email@hidden
	 A pipe stall means that the device endpoint for a particular pipe returned a STALL packet in response to a packet it received.
	 
	 On the host controller side, when a STALL is received the request is returned with the STALL error, and the host endpoint for that 
	 pipe is halted (ie, if there are other transactions queued, they will not be processed). That endpoint will not be used until the 
	 halted condition is removed -- there are various ways that do that depending on which OS you are using (ClearPipeStall() is one).
	 
	 Usually when a device returns a STALL, it also sets it's device endpoint to be halted as well. Typically you need to use a device 
	 request targeted at the endpoint with CLEAR_FEATURE ENDPOINT_HALT parameters.
	 
	 What this means for a particular device depends on that device (or device class specification). How that device recovers without 
	 losing data also depends on the device. If you are having trouble with losing data, it is likely that you are using an API that 
	 resets the data toggle on the host side, and the device isn't changing the data toggle.
	 
	 The USB Spec, chapter 8 should help you understand when devices return STALL, and what must be done to restart a pipe. You can download the spec from http://www.usb.org/developers/docs
	 
	 Hope this helps.
	 
	 David Ferguson
	 USB Software Team
	 Apple Computer
	 
	*/
}

/*
 
 0xe00002c2
 0xe00002e8
 
 Endpoint Descriptor:
 bLength                 7
 bDescriptorType         5
 bEndpointAddress     0x81  EP 1 IN
 bmAttributes            3
 Transfer Type            Interrupt
 Synch Type               None
 Usage Type               Data
 wMaxPacketSize     0x0008  bytes 8 once
 
  
		Macro to encode the bRequest field of a Device Request. Use it to construct an IOUSBDevRequest .
*/

- (void)DreamCheeky_Park;
{
//	UInt8			controls;
//	controls = 0;

	//NSLog(@"USBMissileControl: DreamCheeky_Park");

	//  4 seconds - up
	//  2 seconds - down
	// 16 seconds - left
	//  8 seconds - right
	
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherUp] afterDelay:0.00];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:0.50];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherUp] afterDelay:0.55];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:1.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherUp] afterDelay:1.05];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:1.5];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherUp] afterDelay:1.55];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:2.00];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherUp] afterDelay:2.05];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:2.50];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherUp] afterDelay:2.55];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:3.00];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherUp] afterDelay:3.05];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:3.50];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherUp] afterDelay:3.55];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:4.0];

	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherDown] afterDelay:4.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:5.5];
	
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherLeft] afterDelay:6.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:16.0];

	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherRight] afterDelay:16.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:24.0];

	[self performSelector:@selector(finishCommand:) withObject:self afterDelay:24.5];
}

- (void)MissileLauncher_Park;
{
//	UInt8			controls;
//	controls = 0;
	
	//NSLog(@"USBMissileControl: MissileLauncher_Park");
	
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherLeft] afterDelay:0.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherLeft] afterDelay:3.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherLeft] afterDelay:6.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherDown] afterDelay:7.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherRight] afterDelay:9.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherRight] afterDelay:11.0];
	[self performSelector:@selector(controlLauncher:) withObject:[NSNumber numberWithInt:launcherStop] afterDelay:13.0];
	
	[self performSelector:@selector(finishCommand:) withObject:self afterDelay:13.5];	
}

- (void)finishCommand:(id)sender;
{
//	NSLog(@"Calling the notification center for finishCommandInProgress");
	[[NSNotificationCenter defaultCenter] postNotificationName: @"finishCommandInProgress" object: nil];
}

- (void)DGWScheduleCancelLauncherCommand:(NSTimeInterval)duration;
{
	timer = [NSTimer scheduledTimerWithTimeInterval:duration
											 target:self
										   selector:@selector(DGWAbortLaunch:)
										   userInfo:nil
											repeats:NO];
	return;
}

- (void)DGWAbortLaunch:(NSTimer *)timer;
{
	[self controlLauncher:launcherStop];
}

- (id)ReleaseMissileLauncher
{
	USBLauncher					*privateDataRef = NULL;
	int							i;
	IOUSBDeviceInterface        **missileDevice = NULL;
	
	int numItems = [launcherDevice count];	
	for (i = 0; i < numItems; i++)
	{
//		privateDataRef = [[[USBLauncher alloc] init] retain];
//		privateDataRef = [[USBLauncher alloc] init];
		privateDataRef = [launcherDevice objectAtIndex: i];
		missileDevice = [privateDataRef deviceInterface];
		(*missileDevice)->USBDeviceClose(missileDevice);
		(*missileDevice)->Release(missileDevice);
		[launcherDevice removeObjectAtIndex: i];
//		[privateDataRef release];
	}
	
	return self;
}

- (id)controlLauncher:(NSNumber*)code;
{
	int				launcherRequest = [code intValue];
	UInt8			controls;
	Boolean			debugCommands;
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	debugCommands = [prefs floatForKey:@"debugCommands"];
	
	controls = 0;
	// Left				controls |= 1;
	// Right			controls |= 2;
	// Up				controls |= 4;
	// Down				controls |= 8;
	// Fire				controls |= 16;
	// Park Launcher    controls |= 32
	// Laser Toggle		controls |= 64
	
	
	switch(launcherRequest)
	{
		case launcherStop:
		{
			controls = 0;
			[self MissileControl:controls];
			break;
		}
		case launcherLeftUp:
		{
			controls |= 1;
			controls |= 4;
			[self MissileControl:controls];
			break;
		}
		case launcherUp: 
		{
			controls |= 4;
			[self MissileControl:controls];
			break;
		}
		case launcherRightUp:
		{
			controls |= 2;
			controls |= 4;
			[self MissileControl:controls];
			break;
		}
		case launcherLeft:
		{
			controls |= 1;
			[self MissileControl:controls];
			break;
		}
		case launcherFire:  // FIRE
		{
			controls |= 16;
			[self MissileControl:controls];
			break;
		}
		case launcherRight:
		{
			controls |= 2;
			[self MissileControl:controls];
			break;
		}
		case launcherLeftDown:
		{
			controls |= 1;
			controls |= 8;
			[self MissileControl:controls];
			break;
		}
		case launcherDown: 
		{
			controls |= 8;
			[self MissileControl:controls];
			break;
		}
		case launcherRightDown:
		{
			controls |= 2;
			controls |= 8;
			[self MissileControl:controls];
			break;
		}
		case launcherTest:						// DGW TESTING CODE
		{
			[self MissileControl:controls];
			break;
		}
		case launcherPark:						// DGW TESTING CODE
		{
			// the DreamCheeky launcher only needs to get the "Left" command once as it keeps going once activated
			// the Missile launcher only moves a set distance on receipt of a command
			controls |= 32;
			[self MissileControl:controls];
			break;
		}
		case launcherLaserToggle:
		{
			controls |= 64;
			if (debugCommands)
				NSLog(@"USBMissileControl: controlLauncher: Laser Toggle Request START");
			[self MissileControl:controls];
			if (debugCommands)
				NSLog(@"USBMissileControl: controlLauncher: Laser Toggle Request FINISH");
			break;
		}
		case launcherPrime:
		{
			controls |= 128;
			[self MissileControl:controls];
			break;
		}
	}
	return self;
}


void printInterpretedError(char *s, IOReturn err)
{
	// These should be defined somewhere, but I can't find them. These from Accessing hardware.
	
#if 0
	static struct{int err; char *where;} systemSources[] = {
    {0, "kernel"},
    {1, "user space library"},
    {2, "user space servers"},
    {3, "old ipc errors"},
    {4, "mach-ipc errors"},
    {7, "distributed ipc"},
    {0x3e, "user defined errors"},
    {0x3f, "(compatibility) mach-ipc errors"}
    };
#endif
	
	UInt32 system, sub, code;
    
    fprintf(stderr, "%s (0x%08X) ", s, err);
    
    system = err_get_system(err);
    sub = err_get_sub(err);
    code = err_get_code(err);
    
    if(system == err_get_system(sys_iokit))
    {
        if(sub == err_get_sub(sub_iokit_usb))
        {
            fprintf(stderr, "USB error %ld(0x%lX) ", code, code);
        }
        else if(sub == err_get_sub(sub_iokit_common))
        {
            fprintf(stderr, "IOKit common error %ld(0x%lX) ", code, code);
        }
        else
        {
            fprintf(stderr, "IOKit error %ld(0x%lX) from subsytem %ld(0x%lX) ", code, code, sub, sub);
        }
    }
    else
    {
        fprintf(stderr, "error %ld(0x%lX) from system %ld(0x%lX) - subsytem %ld(0x%lX) ", code, code, system, system, sub, sub);
    }
	fprintf(stderr, "\n");
}

@end

/*

 Sample code below. 
 Note: rBuffer
 
 I want to pass in "rBuffer" to the procedure testCall. This procedure will update rBuffer and the results will be available to the main procedure (in this example).
 At the moment within testCall the size of rBuffer is being reported a 4 (same size as a pointer?).
 
 I've been looking at call by reverence/value online and not having much success in figuring out what I've stuffed up.
 
 
#include <stdio.h>
 
 void testCall(char *rBuffer);
 
 
 
 int main (int argc, const char * argv[]) {
	 // insert code here...
	 
	 char rBuffer[8];
	 
	 testCall(rBuffer);
	 return 0;
 }
 
 
 void testCall(char *rBuffer)
 {
	 int                      bytesRead;
	 
	 //	bzero(rBuffer, sizeof(rBuffer));
	 bytesRead = sizeof(rBuffer);
	 printf("testCall: value of rBuffer bytesRead %x\n", bytesRead);
	 
 }
 

 Incidentally, the fact that you've used the same name for the testCall parameter and the variable in main is not meaningful. 
 You could use a different name for the testCall parameter and the behaviour would be identical.
 
 You have struck a fundamental restriction in C: you cannot pass an array to a function. Any use of the array variable in an 
 expression (except for sizeof) is immediately converted into a pointer to the first element of that array.
 
 In your main function, the testCall(rBuffer) function call is identical to testCall(&rBuffer[0]).
 
 I'm less familiar with C++ and almost unfamiliar with Objective C, so I'm not sure if they offer an easy way around this.
 
 There are three possible solutions in standard C:
 
 (a) If your buffer is always going to be the same size, you can define the parameter to testCall as being a pointer to an 
	array of a fixed size. You need to use a lot of parentheses, so this is ugly.
 
	void testCall(char (*rBuffer)[8]);
 
 This declares rBuffer as a pointer to an array of 8 characters. Not to be confused with char *rBuffer[8], which declares 
 rBuffer as an array of 8 pointers to characters.
 
 Within testCall, you have to use similar syntax to reference rBuffer, e.g.
 
	sizeof(*rBuffer)
 
	(*rBuffer)[i] to get the character at position i
 
 In effect, replace rBuffer with (*rBuffer).
 
 The call from main looks like this:
 
	testCall(&rBuffer);
 
 (b) A syntactically nicer way of doing this (which still requires a fixed array size) is to declare a structure and pass that as a pointer.
 
	typedef struct
	{
		char buf[8];
	} tBuffer;
 
 In main:
 
	tBuffer rBuffer;
 
	testCall(&rBuffer);
 
	rBuffer.buf[i] to get the character at position i
 
 In testCall:
 
	void testCall (tBuffer *rBuffer);
 
	sizeof(rBuffer->buf)
 
	rBuffer->buf[i] to get the character at position i
 
 (c) If you need a variable sized buffer within testCall then you have to pass the number of elements in the array as an 
     extra parameter. For char arrays this is the same as sizeof, but for arrays of larger types (such as int) you might 
     need an expression like (sizeof(rBuffer) / sizeof(rBuffer[0])) to get the number of elements.
 
 In main:
 
	char rBuffer[8];
 
	testCall(rBuffer, sizeof(rBuffer));
 
 In testCall:
 
	void testCall(char *rBuffer, int bufSize);
 
	Use bufSize rather than sizeof to determine the number of characters in the array.
 
 > I've been looking at call by reverence/value online and not having much success in figuring out what I've stuffed up.
 
 If you passed the array by value, it would copy the contents of rBuffer into testCall, then testCall would be modifying 
 a private copy and would be unable to modify main's rBuffer.
 
 -- 
 David Empson
 dempson@actrix.gen.nz
 
*/
