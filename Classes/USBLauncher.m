//
//  USBLauncher.m
//  USB Missile Launcher NZ
//
//  Created by David G. Wilson on 11/06/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

#import "USBLauncher.h"


@implementation USBLauncher

- (id)init;
{
	self = [super init];
	if (self) {
		deviceName = NULL;
	}
	return self;
}

//- (void)dealloc 
//{
//	[launcherType release];
//	[super dealloc];
//}

- (id)initWithNotify:(io_object_t)newNotification device:(IOUSBDeviceInterface **)newDeviceInterface name:(CFStringRef)newDeviceName location:(UInt32)newLocationID;
{
	self = [super init];
	if (self) {
	//	notification = newNotification;
	//	deviceInterface = newDeviceInterface;
	//	deviceName = newDeviceName;
	//	locationID = newLocationID;
		[self setNotification:newNotification];
		[self setDeviceInterface:newDeviceInterface];
		[self setMissileInterface:nil];
		[self setDeviceName:newDeviceName];
		[self setLocationID:newLocationID];
		[self setusbVendorID:0];
		[self setusbProductID:0];
		[self setInterfaceNumEndpoints:0];
		[self setLauncherType:nil];
	}
	return self;
}

- (io_object_t)notification;
{
	return notification;
}
- (IOUSBDeviceInterface **)deviceInterface;
{
	return deviceInterface;
}
- (IOUSBInterfaceInterface183 **)missileInterface;
{
	return missileInterface;
}
- (CFStringRef)deviceName;
{
	return deviceName;
}
- (UInt32)locationID;
{
	return locationID;
}
- (UInt8)interfaceNumEndpoints;
{
	return interfaceNumEndpoints;
}
- (SInt32)getusbVendorID;
{
	return usbVendorID;
}
- (SInt32)getusbProductID;
{
	return usbProductID;
}
- (NSString *)getLauncherType;
{
	return launcherType;
}

- (void)setNotification:(io_object_t)newNotification;
{
	notification = newNotification;
}
- (void)setDeviceInterface:(IOUSBDeviceInterface **)newDeviceInterface;
{
	deviceInterface = newDeviceInterface;
}
- (void)setMissileInterface:(IOUSBInterfaceInterface183 **)newMissileInterface;
{
	missileInterface = newMissileInterface;
}
- (void)setDeviceName:(CFStringRef)newDeviceName;
{
	deviceName = newDeviceName;
}
- (void)setLocationID:(UInt32)newLocationID;
{
	locationID = newLocationID;
}

- (void)setusbVendorID:(SInt32)newusbVendorID;
{
	usbVendorID = newusbVendorID;
}
- (void)setusbProductID:(SInt32)newusbProductID;
{
	usbProductID = newusbProductID;
}
- (void)setInterfaceNumEndpoints:(UInt8)newInterfaceNumEndpoints;
{
	interfaceNumEndpoints = newInterfaceNumEndpoints;
}
- (void)setLauncherType:(NSString *)newLauncherType;
{
	launcherType = newLauncherType;
}
@end
