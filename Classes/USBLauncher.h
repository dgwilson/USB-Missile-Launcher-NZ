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

@interface USBLauncher : NSObject 
{
	io_object_t				notification;
	IOUSBDeviceInterface    **deviceInterface;
	IOUSBInterfaceInterface **missileInterface;
	CFStringRef				deviceName;
	UInt32					locationID;
	SInt32					usbVendorID;
	SInt32					usbProductID;
    UInt8                   interfaceNumEndpoints;
	NSString				*launcherType;
}

- (id)init;
- (id)initWithNotify:(io_object_t)newNotification device:(IOUSBDeviceInterface **)newDeviceInterface name:(CFStringRef)newDeviceName location:(UInt32)newLocationID;
- (void)dealloc;

- (io_object_t)notification;
- (IOUSBDeviceInterface **)deviceInterface;
- (IOUSBInterfaceInterface **)missileInterface;
- (CFStringRef)deviceName;
- (UInt32)locationID;
- (UInt8)interfaceNumEndpoints;
- (SInt32)getusbVendorID;
- (SInt32)getusbProductID;
- (NSString *)getLauncherType;

- (void)setNotification:(io_object_t)newNotification;
- (void)setDeviceInterface:(IOUSBDeviceInterface **)newDeviceInterface;
- (void)setMissileInterface:(IOUSBInterfaceInterface **)newMissileInterface;
- (void)setDeviceName:(CFStringRef)newDeviceName;
- (void)setLocationID:(UInt32)newLocationID;
- (void)setusbVendorID:(SInt32)newusbVendorID;
- (void)setusbProductID:(SInt32)newusbProductID;
- (void)setInterfaceNumEndpoints:(UInt8)newInterfaceNumEndpoints;
- (void)setLauncherType:(NSString *)newLauncherType;


@end
