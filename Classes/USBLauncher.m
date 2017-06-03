//
//  USBLauncher.m
//  USB Missile Launcher NZ
//
//  Created by David G. Wilson on 11/06/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//


//Rather than have that one massive MissileControl method, I’d break things up so
// .... each launcher has it’s own subclass of USBLauncher,
// ....    with it’s own MissileControl method.
//
//For the HID based control, I’ve done a quick hack where at the start of MissileControl it checks for launcherType of @“HID” and calls in to a method named missileControlHID.


#import "USBLauncher.h"
#include "math.h"

@implementation USBLauncher

- (id)init;
{
	self = [super init];
	if (self) {
		deviceName = NULL;
        self.deviceElementsArray = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithNotify:(io_object_t)newNotification device:(IOUSBDeviceInterface **)newDeviceInterface name:(CFStringRef)newDeviceName location:(UInt32)newLocationID;
{
	self = [super init];
	if (self) {
		[self setNotification:newNotification];
		[self setDeviceInterface:newDeviceInterface];
		[self setMissileInterface:nil];
		[self setDeviceName:newDeviceName];
		[self setLocationID:newLocationID];
		[self setusbVendorID:0];
		[self setusbProductID:0];
		[self setInterfaceNumEndpoints:0];
		[self setLauncherType:nil];
        [self setLauncherName:nil];
        [self setLauncherHIDDeviceBOOL:FALSE];
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
- (NSString *)getLauncherName;
{
    return launcherName;
}
- (BOOL)isLauncherHIDDevice
{
    return launcherHIDDeviceBOOL;
}

- (void)setHidDevice:(IOHIDDeviceRef)newHidDevice
{
    _hidDevice = newHidDevice;

    // should load the HID Device Elements at this point
    
    NSArray* elements = (NSArray*) CFBridgingRelease(IOHIDDeviceCopyMatchingElements(newHidDevice, NULL, kIOHIDOptionsTypeNone ));
    usbHIDDeviceElements * devElements = [[usbHIDDeviceElements alloc] initWithDevice:newHidDevice elements:elements];
    [self.deviceElementsArray addObject:devElements];
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
- (void)setLauncherName:(NSString *)newLauncherName;
{
    launcherName = newLauncherName;
}
- (void)setLauncherHIDDeviceBOOL:(BOOL)hidDeviceBOOL;
{
    launcherHIDDeviceBOOL = hidDeviceBOOL;
}

- (NSData *)USBHIDGetDataForElement:(NSUInteger)inElementIndex
{
    IOReturn		tIOReturn;
    IOHIDValueRef	event;
    IOHIDElementRef	elementRef;
    
    NSMutableData * elementResponseData = nil;
    
    usbHIDDeviceElements * devElements;
    for (devElements in self.deviceElementsArray)
    {
        if (devElements.device == [self hidDevice])
        {
            elementRef = (__bridge IOHIDElementRef)[devElements.elements objectAtIndex:inElementIndex];
            
            //			tIOReturn = IOHIDDeviceGetValue(
            tIOReturn = IOHIDDeviceGetValue(
                                            [self hidDevice],// IOHIDDeviceRef for the HID device
                                            elementRef,		// IOHIDElementRef for the HID element
                                            &event);		// for the HID element's new value
            if (tIOReturn != kIOReturnSuccess )
            {
                NSLog(@"%@ IOReturn was not successful 0x%x", NSStringFromSelector(_cmd), err_get_code(tIOReturn));
                //                [self whatIsMyIOErrorCode:tIOReturn];
            }
            else
            {
                uint32_t size = 0;
                uint32_t bufferSize = 300;
                
                elementResponseData = [NSMutableData dataWithLength:bufferSize];
                unsigned char * elementResponseBuffer = [elementResponseData mutableBytes];
                bzero(elementResponseBuffer, bufferSize);
                
                if (IOHIDValueGetBytePtr(event) && IOHIDValueGetLength(event))
                {
                    size = min(bufferSize, IOHIDValueGetLength(event));
                    bcopy((char *)IOHIDValueGetBytePtr(event), elementResponseBuffer, size);
                    //		DumpElement(inElementIndex, elementResponseBuffer, size);
                    //		printf("\n");
                }
            }
        }
    }
//    NSLog(@"elementResponseData=%@", elementResponseData);
    return elementResponseData;
}

//http://stackoverflow.com/questions/20980815/implicit-declaration-of-function-min

// include math.h

//#ifndef min
//#define min(a,b)            (((a) < (b)) ? (a) : (b))
//#endif

double min(double a, double b) {
    return a<b ? a : b;
}

@end
