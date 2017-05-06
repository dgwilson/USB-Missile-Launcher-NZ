//
//  USBLauncher.h
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 30/07/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOMessage.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/hid/IOHIDLib.h>

@interface USBLauncher : NSObject 
{
	io_object_t				notification;
	IOUSBDeviceInterface    **deviceInterface;
	IOUSBInterfaceInterface183 **missileInterface;
	CFStringRef				deviceName;
	UInt32					locationID;
	SInt32					usbVendorID;
	SInt32					usbProductID;
    UInt8                   interfaceNumEndpoints;
	NSString				*launcherType;
}

@property (assign, nonatomic) IOHIDDeviceRef hidDevice;


- (id)init;
- (id)initWithNotify:(io_object_t)newNotification device:(IOUSBDeviceInterface **)newDeviceInterface name:(CFStringRef)newDeviceName location:(UInt32)newLocationID;

- (io_object_t)notification;
- (IOUSBDeviceInterface **)deviceInterface;
- (IOUSBInterfaceInterface183 **)missileInterface;
- (CFStringRef)deviceName;
- (UInt32)locationID;
- (UInt8)interfaceNumEndpoints;
- (SInt32)getusbVendorID;
- (SInt32)getusbProductID;
- (NSString *)getLauncherType;

- (void)setNotification:(io_object_t)newNotification;
- (void)setDeviceInterface:(IOUSBDeviceInterface **)newDeviceInterface;
- (void)setMissileInterface:(IOUSBInterfaceInterface183 **)newMissileInterface;
- (void)setDeviceName:(CFStringRef)newDeviceName;
- (void)setLocationID:(UInt32)newLocationID;
- (void)setusbVendorID:(SInt32)newusbVendorID;
- (void)setusbProductID:(SInt32)newusbProductID;
- (void)setInterfaceNumEndpoints:(UInt8)newInterfaceNumEndpoints;
- (void)setLauncherType:(NSString *)newLauncherType;


@end
