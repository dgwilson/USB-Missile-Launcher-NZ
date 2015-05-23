//
//  USBJoyStickControl.h
//  USB Missile Launcher NZ
//
//  Created by David G. Wilson on 03/02/07.
//  Copyright 2007 David G. Wilson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/IOMessage.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <IOKit/hid/IOHIDUsageTables.h>
#include <IOKit/hidsystem/IOHIDLib.h>
#include <IOKit/hidsystem/IOHIDShared.h>
#include <IOKit/hidsystem/IOHIDParameter.h>


//---------------------------------------------------------------------------
// TypeDefs
//---------------------------------------------------------------------------
typedef enum CalibrationState {
    kCalibrationStateInactive   = 0,
    kCalibrationStateTopLeft,
    kCalibrationStateTopRight,
    kCalibrationStateBottomRight,
    kCalibrationStateBottomLeft
} CalibrationState;

typedef struct HIDData
{
    io_object_t					notification;
    IOHIDDeviceInterface122 ** 	hidDeviceInterface;
    IOHIDQueueInterface **      hidQueueInterface;
    CFDictionaryRef             hidElementDictionary;
    CFRunLoopSourceRef			eventSource;
    CalibrationState            state;
	SInt32						usage;
	IOHIDElementCookie			xAxisCookie;
	IOHIDElementCookie			yAxisCookie;
	IOHIDElementCookie			button1Cookie;
	IOHIDElementCookie			button2Cookie;
	IOHIDElementCookie			button3Cookie;
	IOHIDElementCookie			button4Cookie;
    SInt32                      minx;
    SInt32                      maxx;
    SInt32                      miny;
    SInt32                      maxy;
    UInt8                       buffer[256];  
} HIDData;

typedef HIDData *				HIDDataRef;

typedef struct HIDElement {
    SInt32						currentValue;
    SInt32						usagePage;
    SInt32						usage;
    IOHIDElementType			type;
    IOHIDElementCookie			cookie;
    HIDDataRef					owner;
}HIDElement;

typedef HIDElement *			HIDElementRef;


@interface USBJoyStickControl : NSObject 
{

}

//---------------------------------------------------------------------------
// Methods
//---------------------------------------------------------------------------
- (id)initHIDNotifications;
static void HIDDeviceAdded(void *refCon, io_iterator_t iterator);
static void DeviceNotificationJoystick(void *refCon, io_service_t service, natural_t messageType, void *messageArgument);
static bool FindHIDElements(HIDDataRef hidDataRef);
static bool SetupQueue(HIDDataRef hidDataRef);
static void QueueCallbackFunction(
								void * 			target, 
								IOReturn 		result, 
								void * 			refcon, 
								void * 			sender);
static void InterruptReportCallbackFunction(
								void *	 		target,
								IOReturn 		result,
								void *			refcon,
								void *			sender,
								uint32_t		bufferSize);


@end
