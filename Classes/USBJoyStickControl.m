//
//  USBJoyStickControl.m
//  USB Missile Launcher NZ
//
//  Created by David G. Wilson on 03/02/07.
//  Copyright 2007 David G. Wilson. All rights reserved.
//

#import "USBJoyStickControl.h"

//---------------------------------------------------------------------------
// Globals
//---------------------------------------------------------------------------
static IONotificationPortRef	gNotifyPort;
static CFRunLoopRef				gRunLoop;

static io_iterator_t			gAddedIter = 0;


@implementation USBJoyStickControl


#ifndef max
#define max(a, b) \
    ((a > b) ? a:b)
#endif

#ifndef min
#define min(a, b) \
    ((a < b) ? a:b)
#endif


//---------------------------------------------------------------------------
// InitHIDNotifications
//
// This routine just creates our master port for IOKit and turns around 
// and calls the routine that will alert us when a HID Device is plugged in.
//---------------------------------------------------------------------------

- (id)initHIDNotifications
{
	CFRunLoopSourceRef			runLoopSource;
    CFMutableDictionaryRef		matchingDict1;
    CFMutableDictionaryRef		matchingDict2;
    CFNumberRef                 refUsagePage;
    CFNumberRef                 refUsage1;
    CFNumberRef                 refUsage2;
	SInt32						usagePage = kHIDPage_GenericDesktop;
	SInt32						usage1	  = kHIDUsage_GD_Joystick;
	SInt32						usage2	  = kHIDUsage_GD_GamePad;
    mach_port_t					masterPort;
    kern_return_t				kr;

    // We need to cater for two different devices
	// file://localhost/Developer/SDKs/MacOSX10.4u.sdk/System/Library/Frameworks/Kernel.framework/Versions/A/Headers/IOKit/hid/IOHIDUsageTables.h
	// IOKit/hid/IOHIDUsageTables.h
	// 	kHIDUsage_GD_Joystick	= 0x04,	/* Application Collection */
	//  kHIDUsage_GD_GamePad	= 0x05,	/* Application Collection */
	// the std joystick is catered for under GD_Joystick
	// my CyBorg Evo Joystick seems be be classified as a GD_GamePad
	
    // first create a master_port for my task
    //
    kr = IOMasterPort(bootstrap_port, &masterPort);
    if (kr || !masterPort)
        return NO;

    // Create a notification port and add its run loop event source to our run loop
    // This is how async notifications get set up.
    //

	gNotifyPort = IONotificationPortCreate(masterPort);
    runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
    
    gRunLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);


    // Create the IOKit notifications that we need
    matchingDict1 = IOServiceMatching(kIOHIDDeviceKey); 
	//"IOHIDDevice"
    if (!matchingDict1)
	{
		printf("Matching dictionary error.\n");
		return NO;    
	}

	// usage1	  = kHIDUsage_GD_Joystick;
	// Now need to make this generic enough to "any" joystick
    refUsagePage = CFNumberCreate (kCFAllocatorDefault, kCFNumberSInt32Type, &usagePage);
    refUsage1 = CFNumberCreate (kCFAllocatorDefault, kCFNumberSInt32Type, &usage1);
    CFDictionaryAddValue (matchingDict1, CFSTR (kIOHIDPrimaryUsagePageKey), refUsagePage);
    CFDictionaryAddValue (matchingDict1, CFSTR (kIOHIDPrimaryUsageKey), refUsage1);

    CFRelease(refUsagePage);
    CFRelease(refUsage1);	
	
	
    // Now set up a notification to be called when a device is first matched by I/O Kit.
    // Note that this will not catch any devices that were already plugged in so we take
    // care of those later.
    kr = IOServiceAddMatchingNotification(gNotifyPort,					// notifyPort
                                          kIOFirstMatchNotification,	// notificationType
                                          matchingDict1,				// matching
                                          HIDDeviceAdded,				// callback
                                          NULL,							// refCon
                                          &gAddedIter					// notification
                                          );

    if ( kr != kIOReturnSuccess )
        return NO;
        
    HIDDeviceAdded( NULL, gAddedIter );
	
	
	// Create the IOKit notifications that we need
    matchingDict2 = IOServiceMatching(kIOHIDDeviceKey); 
	//"IOHIDDevice"
    if (!matchingDict2)
	{
		printf("Matching dictionary error.\n");
		return NO;    
	}
	
	// usage2	  = kHIDUsage_GD_GamePad
	// Now need to make this generic enough to "any" joystick
    refUsagePage = CFNumberCreate (kCFAllocatorDefault, kCFNumberSInt32Type, &usagePage);
    refUsage2 = CFNumberCreate (kCFAllocatorDefault, kCFNumberSInt32Type, &usage2);
    CFDictionaryAddValue (matchingDict2, CFSTR (kIOHIDPrimaryUsagePageKey), refUsagePage);
    CFDictionaryAddValue (matchingDict2, CFSTR (kIOHIDPrimaryUsageKey), refUsage2);
	
    CFRelease(refUsagePage);
    CFRelease(refUsage2);	
	
	
    // Now set up a notification to be called when a device is first matched by I/O Kit.
    // Note that this will not catch any devices that were already plugged in so we take
    // care of those later.
    kr = IOServiceAddMatchingNotification(gNotifyPort,					// notifyPort
                                          kIOFirstMatchNotification,	// notificationType
                                          matchingDict2,					// matching
                                          HIDDeviceAdded,				// callback
                                          NULL,							// refCon
                                          &gAddedIter					// notification
                                          );
	
    if ( kr != kIOReturnSuccess )
        return NO;
	
    HIDDeviceAdded( NULL, gAddedIter );
	
	mach_port_deallocate(mach_task_self(), masterPort);
    masterPort = 0;

	return nil;
}

//---------------------------------------------------------------------------
// HIDDeviceAdded
//
// This routine is the callback for our IOServiceAddMatchingNotification.
// When we get called we will look at all the devices that were added and 
// we will:
//
// Create some private data to relate to each device
//
// Submit an IOServiceAddInterestNotification of type kIOGeneralInterest for 
// this device using the refCon field to store a pointer to our private data.
// When we get called with this interest notification, we can grab the refCon
// and access our private data.
//---------------------------------------------------------------------------

void HIDDeviceAdded(void *refCon, io_iterator_t iterator)
{
    io_object_t				hidDevice				= 0; // was NULL - DGW 27APR07
    IOCFPlugInInterface		**	plugInInterface 	= NULL;
    IOHIDDeviceInterface122 **	hidDeviceInterface 	= NULL;
    HRESULT					result					= S_FALSE;
    HIDDataRef              hidDataRef              = NULL;
    IOReturn				kr;
    SInt32					score;
    bool                    pass;
	int						deviceCount				= 0;
	
	//printf("HIDDeviceAdded.\n\n");

    while (( hidDevice = IOIteratorNext(iterator) ))
    {     
		//printf("Enter the iterator.\n\n");

        // Create the CF plugin for this device
        kr = IOCreatePlugInInterfaceForService(hidDevice, kIOHIDDeviceUserClientTypeID, 
                    kIOCFPlugInInterfaceID, &plugInInterface, &score);
                    
        if ( kr != kIOReturnSuccess )
		{
			printf("IOCreatePlugInInterfaceForService failed.\n\n");
			goto HIDDEVICEADDED_NONPLUGIN_CLEANUP;
		}
    
        result = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID122), 
                                                (LPVOID)&hidDeviceInterface);
                                                        
        // Got the interface
        if ( ( result == S_OK ) && hidDeviceInterface )
        {
            hidDataRef = malloc(sizeof(HIDData));						// Allocate
            bzero(hidDataRef, sizeof(HIDData));							// Zero
            
            hidDataRef->hidDeviceInterface = hidDeviceInterface;		// Load
            
            CFArrayRef arrayRef1 = IORegistryEntryCreateCFProperty(hidDevice, CFSTR("HIDDescriptor"), 0, 0);
            
            if ( arrayRef1 )
            {
                CFShow(arrayRef1);
                CFArrayRef arrayRef2 = CFArrayGetValueAtIndex(arrayRef1, 0);

                if ( arrayRef2 )
                {
                    CFShow(arrayRef2);
                    CFDataRef data = CFArrayGetValueAtIndex(arrayRef2, 1);
                    CFShow(data);
                    
                    if ( data )
                    {
                        const UInt8 * buffer = CFDataGetBytePtr(data);
                        int i;
                        printf("Bluetooth HID descriptor: ");
                        for (i=0; i<CFDataGetLength(data); i++)
                            printf("0x%x, ", buffer[i]);
                        printf("\n");
                    }
                }
				CFRelease ( arrayRef1 );
            }

            result = (*(hidDataRef->hidDeviceInterface))->open (hidDataRef->hidDeviceInterface, 0);
			if (result != 0)
				printf("USBJoyStickControl: Error returned from open %ld", result);
			// typedef SInt32 HRESULT;
			// HRESULT result;
			
            pass = FindHIDElements(hidDataRef);
			if (!pass)
			{
				printf("USBJoyStickControl: No HID elements available");
			}
			
            result = (*(hidDataRef->hidDeviceInterface))->createAsyncEventSource(hidDataRef->hidDeviceInterface, &hidDataRef->eventSource);
			if (result != 0)
				printf("USBJoyStickControl: Error returned from createAsyncEventSource %ld", result);
            
			result = (*(hidDataRef->hidDeviceInterface))->setInterruptReportHandlerCallback(
																				hidDataRef->hidDeviceInterface, 
																				hidDataRef->buffer, 
																				sizeof(hidDataRef->buffer), 
																				InterruptReportCallbackFunction, 
																				NULL, 
																				hidDataRef);
			if (result != 0)
				printf("USBJoyStickControl: Error returned from setInterruptReportHandlerCallback %ld", result);
			
//          result = (*(hidDataRef->hidDeviceInterface))->startAllQueues(hidDataRef->hidDeviceInterface);
			
            CFRunLoopAddSource(CFRunLoopGetCurrent(), hidDataRef->eventSource, kCFRunLoopDefaultMode);

            IOServiceAddInterestNotification(	
                                    gNotifyPort,				// notifyPort
                                    hidDevice,					// service
                                    kIOGeneralInterest,			// interestType
                                    DeviceNotificationJoystick,	// callback
                                    hidDataRef,					// refCon
                                    &(hidDataRef->notification)	// notification
                                    );
			deviceCount ++;
			NSLog(@"USBJoyStickControl: Added Joystick %d", deviceCount);
            goto HIDDEVICEADDED_CLEANUP;
        }

HIDDEVICEADDED_FAIL:
        // Failed to allocated a UPS interface.  Do some cleanup
        if ( hidDeviceInterface )
        {
            (*hidDeviceInterface)->Release(hidDeviceInterface);
            hidDeviceInterface = NULL;
        }
        
        if ( hidDataRef )
            free ( hidDataRef );

HIDDEVICEADDED_CLEANUP:
        // Clean up
        (*plugInInterface)->Release(plugInInterface);
        
HIDDEVICEADDED_NONPLUGIN_CLEANUP:
		continue;
//		result = 0; // this is just a dummy statement to the compiler doesn't puke on the label above
	}		
	
	IOObjectRelease(hidDevice);

}

//---------------------------------------------------------------------------
// DeviceNotificationJoystick
//
// This routine will get called whenever any kIOGeneralInterest notification 
// happens. 
//---------------------------------------------------------------------------

void DeviceNotificationJoystick(void *			refCon,
								io_service_t 	service,
								natural_t		messageType,
								void *			messageArgument )
{
//    kern_return_t	kr;
    HIDDataRef		hidDataRef = (HIDDataRef) refCon;

    if ( (hidDataRef != NULL) &&
         (messageType == kIOMessageServiceIsTerminated) )
    {
		NSLog(@"USBJoyStickControl: Joystick Removed");

        if (hidDataRef->hidQueueInterface != NULL)
        {
//            kr = (*(hidDataRef->hidQueueInterface))->stop((hidDataRef->hidQueueInterface));
//            kr = (*(hidDataRef->hidQueueInterface))->dispose((hidDataRef->hidQueueInterface));
//            kr = (*(hidDataRef->hidQueueInterface))->Release (hidDataRef->hidQueueInterface);
			(*(hidDataRef->hidQueueInterface))->stop((hidDataRef->hidQueueInterface));
			(*(hidDataRef->hidQueueInterface))->dispose((hidDataRef->hidQueueInterface));
			(*(hidDataRef->hidQueueInterface))->Release (hidDataRef->hidQueueInterface);
            hidDataRef->hidQueueInterface = NULL;
        }

        if (hidDataRef->hidDeviceInterface != NULL)
        {
//            kr = (*(hidDataRef->hidDeviceInterface))->close (hidDataRef->hidDeviceInterface);
//            kr = (*(hidDataRef->hidDeviceInterface))->Release (hidDataRef->hidDeviceInterface);
            (*(hidDataRef->hidDeviceInterface))->close (hidDataRef->hidDeviceInterface);
           (*(hidDataRef->hidDeviceInterface))->Release (hidDataRef->hidDeviceInterface);
            hidDataRef->hidDeviceInterface = NULL;
        }
        
        if (hidDataRef->notification != 0)  // was NULL DGW 27APR07
        {
//            kr = IOObjectRelease(hidDataRef->notification);
            IOObjectRelease(hidDataRef->notification);
            hidDataRef->notification = 0;  // was NULL DGW 27APR07
        }

    }
}

//---------------------------------------------------------------------------
// FindHIDElements
//---------------------------------------------------------------------------
bool FindHIDElements(HIDDataRef hidDataRef)
{
    CFArrayRef              elementArray	= NULL;
    CFMutableDictionaryRef  hidElements     = NULL;
    CFMutableDataRef        newData         = NULL;
    CFNumberRef             number			= NULL;
    CFDictionaryRef         element			= NULL;
    HIDElement              newElement;
    IOReturn                ret				= kIOReturnError;
    unsigned                i;

    if (!hidDataRef)
        return false;
        
    hidElements = CFDictionaryCreateMutable(
                                    kCFAllocatorDefault, 
                                    0, 
                                    &kCFTypeDictionaryKeyCallBacks, 
                                    &kCFTypeDictionaryValueCallBacks);                                    
    if ( !hidElements )
        return false;
        
    // Let's find the elements
    ret = (*hidDataRef->hidDeviceInterface)->copyMatchingElements(	
                                    hidDataRef->hidDeviceInterface, 
                                    NULL, 
                                    &elementArray);


    if ( (ret != kIOReturnSuccess) || !elementArray)
        goto FIND_ELEMENT_CLEANUP;
        
    //CFShow(elementArray);

    for (i=0; i<CFArrayGetCount(elementArray); i++)
    {
        element = (CFDictionaryRef) CFArrayGetValueAtIndex(elementArray, i);
        if ( !element )
            continue;
    
        bzero(&newElement, sizeof(HIDElement));
        
        newElement.owner = hidDataRef;
        
        number = (CFNumberRef)CFDictionaryGetValue(element, CFSTR(kIOHIDElementUsagePageKey));
        if ( !number ) continue;
        CFNumberGetValue(number, kCFNumberSInt32Type, &newElement.usagePage );

        number = (CFNumberRef)CFDictionaryGetValue(element, CFSTR(kIOHIDElementUsageKey));
        if ( !number ) continue;
        CFNumberGetValue(number, kCFNumberSInt32Type, &newElement.usage );
        
        number = (CFNumberRef)CFDictionaryGetValue(element, CFSTR(kIOHIDElementCookieKey));
        if ( !number ) continue;
        CFNumberGetValue(number, kCFNumberIntType, &(newElement.cookie) );
        
        number = (CFNumberRef)CFDictionaryGetValue(element, CFSTR(kIOHIDElementTypeKey));
        if ( !number ) continue;
        CFNumberGetValue(number, kCFNumberIntType, &(newElement.type) );

        if ( newElement.usagePage == kHIDPage_GenericDesktop )
        {
            switch ( newElement.usage )
            {
				case kHIDUsage_GD_Joystick:
					hidDataRef->usage = kHIDUsage_GD_Joystick;
					//printf("It's a kHIDUsage_GD_Joystick\n");
					break;
					
				case kHIDUsage_GD_GamePad:
					hidDataRef->usage = kHIDUsage_GD_GamePad;
					//printf("It's a kHIDUsage_GD_GamePad\n");
					break;
					
                case kHIDUsage_GD_X:		// DGW remember this
					//store the cookie
					hidDataRef->xAxisCookie = newElement.cookie;
					number = (CFNumberRef)CFDictionaryGetValue(element, CFSTR(kIOHIDElementMinKey));
					if (number != nil)
						CFNumberGetValue(number, kCFNumberSInt32Type, &hidDataRef->minx);
					number = (CFNumberRef)CFDictionaryGetValue(element, CFSTR(kIOHIDElementMaxKey));
					if (number != nil)
						CFNumberGetValue(number, kCFNumberSInt32Type, &hidDataRef->maxx);
					break;
					
                case kHIDUsage_GD_Y:
					//store the cookie
					hidDataRef->yAxisCookie = newElement.cookie;
					number = (CFNumberRef)CFDictionaryGetValue(element, CFSTR(kIOHIDElementMinKey));
					if (number != nil)
						CFNumberGetValue(number, kCFNumberSInt32Type, &hidDataRef->miny);
					number = (CFNumberRef)CFDictionaryGetValue(element, CFSTR(kIOHIDElementMaxKey));
					if (number != nil)
						CFNumberGetValue(number, kCFNumberSInt32Type, &hidDataRef->maxy);
                    break;
					
                default:
                    continue;
            }
        }
        else if ( newElement.usagePage == kHIDPage_Button )
        {

            switch ( newElement.usage )
            {
                case kHIDUsage_Button_1:
					//store the cookie
					hidDataRef->button1Cookie = newElement.cookie;
                    break;
                case kHIDUsage_Button_2:
					//store the cookie
					hidDataRef->button2Cookie = newElement.cookie;
                    break;
                case kHIDUsage_Button_3:
					//store the cookie
					hidDataRef->button3Cookie = newElement.cookie;
                    break;
                case kHIDUsage_Button_4:
					//store the cookie
					hidDataRef->button4Cookie = newElement.cookie;
                    break;
                default:
                    continue;
            }
        }
        else
            continue;

        newData = CFDataCreateMutable(kCFAllocatorDefault, sizeof(HIDElement));
        if ( !newData ) continue;
        bcopy(&newElement, CFDataGetMutableBytePtr(newData), sizeof(HIDElement));
              
        number = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &newElement.cookie);        
//        if ( !number )  
//			continue;
//        CFDictionarySetValue(hidElements, number, newData);
//        CFRelease(number);
//        CFRelease(newData);
		if ( number )  
        {
			CFDictionarySetValue(hidElements, number, newData);
			CFRelease(number);
		}
        CFRelease(newData);
    }
    
FIND_ELEMENT_CLEANUP:
    if ( elementArray ) CFRelease(elementArray);
    
    if (CFDictionaryGetCount(hidElements) == 0)
    {
        CFRelease(hidElements);
        hidElements = NULL;
    }
    else 
    {
        hidDataRef->hidElementDictionary = hidElements;
    }
    
    return hidDataRef->hidElementDictionary;
}

//---------------------------------------------------------------------------
// SetupQueue
//---------------------------------------------------------------------------
bool SetupQueue(HIDDataRef hidDataRef)
{
    CFIndex				count 		= 0;
    CFIndex				i			= 0;
//	CFMutableDataRef    element     = NULL;
    CFMutableDataRef *	elements	= NULL;
    CFStringRef		 *	keys		= NULL;
    IOReturn			ret;
    HIDElementRef		tempHIDElement	= NULL;
    bool				cookieAdded 	= false;
    bool                boolRet         = true;

    if ( !hidDataRef->hidElementDictionary || (((count = CFDictionaryGetCount(hidDataRef->hidElementDictionary)) <= 0)))
        return false;
        
    keys 	= (CFStringRef *)malloc(sizeof(CFStringRef) * count);
    elements 	= (CFMutableDataRef *)malloc(sizeof(CFMutableDataRef) * count);
                
    CFDictionaryGetKeysAndValues(hidDataRef->hidElementDictionary, (const void **)keys, (const void **)elements);

    hidDataRef->hidQueueInterface = (*hidDataRef->hidDeviceInterface)->allocQueue(hidDataRef->hidDeviceInterface);
    if ( !hidDataRef->hidQueueInterface )
    {
            boolRet = false;
            goto SETUP_QUEUE_CLEANUP;
    }
        
    ret = (*hidDataRef->hidQueueInterface)->create(hidDataRef->hidQueueInterface, 0, 8);
    if (ret != kIOReturnSuccess)
    {
            boolRet = false;
            goto SETUP_QUEUE_CLEANUP;
    }
        
    for (i=0; i<count; i++)
    {
        if ( !elements[i] || 
            !(tempHIDElement = (HIDElementRef)CFDataGetMutableBytePtr(elements[i])))
            continue;
        
        if ((tempHIDElement->type < kIOHIDElementTypeInput_Misc) || (tempHIDElement->type > kIOHIDElementTypeInput_ScanCodes))
            continue;
            
        ret = (*hidDataRef->hidQueueInterface)->addElement(hidDataRef->hidQueueInterface, tempHIDElement->cookie, 0);
        
        if (ret == kIOReturnSuccess)
            cookieAdded = true;
    }
    
    if ( cookieAdded )
    {
        ret = (*hidDataRef->hidQueueInterface)->createAsyncEventSource(hidDataRef->hidQueueInterface, &hidDataRef->eventSource);
        if ( ret != kIOReturnSuccess )
        {
                boolRet = false;
            goto SETUP_QUEUE_CLEANUP;
        }
    
        ret = (*hidDataRef->hidQueueInterface)->setEventCallout(hidDataRef->hidQueueInterface, QueueCallbackFunction, NULL, hidDataRef);
        if ( ret != kIOReturnSuccess )
        {
                boolRet = false;
            goto SETUP_QUEUE_CLEANUP;
        }
    
        CFRunLoopAddSource(CFRunLoopGetCurrent(), hidDataRef->eventSource, kCFRunLoopDefaultMode);
    
        ret = (*hidDataRef->hidQueueInterface)->start(hidDataRef->hidQueueInterface);
        if ( ret != kIOReturnSuccess )
        {
                boolRet = false;
            goto SETUP_QUEUE_CLEANUP;
        }
    }
    else 
    {
        (*hidDataRef->hidQueueInterface)->stop(hidDataRef->hidQueueInterface);
        (*hidDataRef->hidQueueInterface)->dispose(hidDataRef->hidQueueInterface);    
        (*hidDataRef->hidQueueInterface)->Release(hidDataRef->hidQueueInterface);
        hidDataRef->hidQueueInterface = NULL;        
    }
    
SETUP_QUEUE_CLEANUP:

    free(keys);
    free(elements);
    
    return boolRet;
}


//---------------------------------------------------------------------------
// QueueCallbackFunction
//---------------------------------------------------------------------------
void QueueCallbackFunction(
                            void * 			target, 
                            IOReturn 		result, 
                            void * 			refcon, 
                            void * 			sender)
{
    HIDDataRef          hidDataRef      = (HIDDataRef)refcon;
    AbsoluteTime		zeroTime		= {0,0};
    CFNumberRef			number			= NULL;
    CFMutableDataRef	element			= NULL;
    HIDElementRef		tempHIDElement  = NULL;//(HIDElementRef)refcon;	
    IOHIDEventStruct 	event;
//    bool                change;
//	bool                stateChange = false;
        
    if ( !hidDataRef || ( sender != hidDataRef->hidQueueInterface))
        return;
        
    while (result == kIOReturnSuccess) 
    {
        result = (*hidDataRef->hidQueueInterface)->getNextEvent(
                                        hidDataRef->hidQueueInterface, 
                                        &event, 
                                        zeroTime, 
                                        0);
                                        
        if ( result != kIOReturnSuccess )
            continue;
        
        // Only intersted in 32 values right now
        if ((event.longValueSize != 0) && (event.longValue != NULL))
        {
            free(event.longValue);
            continue;
        }
        
        number = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &event.elementCookie);        
        if ( !number )  continue;
        element = (CFMutableDataRef)CFDictionaryGetValue(hidDataRef->hidElementDictionary, number);
        CFRelease(number);
        
        if ( !element || 
            !(tempHIDElement = (HIDElement *)CFDataGetMutableBytePtr(element)))  
            continue;

//        change = (tempHIDElement->currentValue != event.value);
        tempHIDElement->currentValue = event.value;

    }

}


//---------------------------------------------------------------------------
// InterruptReportCallbackFunction
//---------------------------------------------------------------------------
void InterruptReportCallbackFunction
              (void *	 		target,
               IOReturn 		result,
               void * 			refcon,
               void * 			sender,
//               UInt32		 	bufferSize)
			   uint32_t			bufferSize)

// typedef void (*IOHIDReportCallbackFunction) (void * target, IOReturn result, void * refcon,  void * sender,  uint32_t bufferSize);

{
    HIDDataRef				hidDataRef = (HIDDataRef)refcon;
	SInt32					xmid, ymid;
	SInt32					myxaxis, myyaxis, button;
    int						action			= 0;
	float					joystickSensitivity;
	float					joystickFireButtonMatrix;
	int						joystickFireButtonMatrixInt;
	Boolean					reverseXAxis;
	Boolean					reverseYAxis;
    HRESULT					myresult		= S_FALSE;
	IOHIDEventStruct		hidEvent;
	long					xAxis, yAxis, button1, button2, button3, button4;
	
	
    if ( !hidDataRef )
        return;

	xmid = (hidDataRef->maxx - hidDataRef->minx)/2;
	ymid = (hidDataRef->maxy - hidDataRef->miny)/2;
	myxaxis = hidDataRef->buffer[0];
	myyaxis = hidDataRef->buffer[1];
	button = hidDataRef->buffer[3];

	
// get xAxis
	myresult = (*hidDataRef->hidDeviceInterface)->getElementValue(hidDataRef->hidDeviceInterface, hidDataRef->xAxisCookie, &hidEvent);
	if (myresult)
	{
		//printf("getElementValue xAxis error = %lx\n", result);
		xAxis = myxaxis;
	} else {
		xAxis = hidEvent.value;
	}
	
// get yAxis
	myresult = (*hidDataRef->hidDeviceInterface)->getElementValue(hidDataRef->hidDeviceInterface, hidDataRef->yAxisCookie, &hidEvent);
	if (myresult)
	{
		//printf("getElementValue yAxis error = %lx\n", result);
		yAxis = myyaxis;
	} else {
		yAxis = hidEvent.value;
	}
	
// get button1
	myresult = (*hidDataRef->hidDeviceInterface)->getElementValue(hidDataRef->hidDeviceInterface, hidDataRef->button1Cookie, &hidEvent);
	if (myresult)
	{
		//printf("getElementValue button1 error = %lx\n", result);
		button1 = button;
	} else {
		button1 = hidEvent.value;
	}
// get button2
	myresult = (*hidDataRef->hidDeviceInterface)->getElementValue(hidDataRef->hidDeviceInterface, hidDataRef->button2Cookie, &hidEvent);
	if (myresult)
	{
		//printf("getElementValue button1 error = %lx\n", result);
		button2 = button;
	} else {
		button2 = hidEvent.value;
	}
// get button3
	myresult = (*hidDataRef->hidDeviceInterface)->getElementValue(hidDataRef->hidDeviceInterface, hidDataRef->button3Cookie, &hidEvent);
	if (myresult)
	{
		//printf("getElementValue button1 error = %lx\n", result);
		button3 = button;
	} else {
		button3 = hidEvent.value;
	}
// get button4
	myresult = (*hidDataRef->hidDeviceInterface)->getElementValue(hidDataRef->hidDeviceInterface, hidDataRef->button4Cookie, &hidEvent);
	if (myresult)
	{
		//printf("getElementValue button1 error = %lx\n", result);
		button4 = button;
	} else {
		button4 = hidEvent.value;
	}
	
	
//	printf("BufferSize=%3.3x ", bufferSize);
//    printf("Buffer = ");

//    for ( index=0; index<bufferSize; index++)
//        printf("%3.3x ", hidDataRef->buffer[index]);
//	printf(" -- ");
//	printf("minx %3.3x, ", hidDataRef->minx);
//	printf("maxx %3.3x, ", hidDataRef->maxx);
//	printf("miny %3.3x, ", hidDataRef->miny);
//	printf("maxy %3.3x, ", hidDataRef->maxy);
//	printf(" -- ");
//	printf("x=%3.3x (%4ld) ", myxaxis, xAxis);
//	printf("y=%3.3x (%4ld) ", myyaxis, yAxis);
//	printf("b=%3.3x (%4ld) ", button, button1);
//	printf("xmid=%3.3x ", xmid);
//	printf("ymid=%3.3x ", ymid);
//	printf("\n");
	
	
	
	/* Button Page (0x09) */
	/* The Button page is the first place an application should look for user selection controls. System graphical user interfaces typically employ a pointer and a set of hierarchical selectors to select, move and otherwise manipulate their environment. For these purposes the following assignment of significance can be applied to the Button usages: */
	/* • Button 1, Primary Button. Used for object selecting, dragging, and double click activation. On MacOS, this is the only button. Microsoft operating systems call this a logical left button, because it */
	/* is not necessarily physically located on the left of the pointing device. */
	/* • Button 2, Secondary Button. Used by newer graphical user interfaces to browse object properties. Exposed by systems to applications that typically assign application-specific functionality. */
	/* • Button 3, Tertiary Button. Optional control. Exposed to applications, but seldom assigned functionality due to prevalence of two- and one-button devices. */
	/* • Buttons 4 -55. As the button number increases, its significance as a selector decreases. */
	/* In many ways the assignment of button numbers is similar to the assignment of Effort in Physical descriptors. Button 1 would be used to define the button a finger rests on when the hand is in the “at rest” position, that is, virtually no effort is required by the user to activate the button. Button values increment as the finger has to stretch to reach a control. See Section 6.2.3, “Physical Descriptors,” in the HID Specification for methods of further qualifying buttons. */
	// 	kHIDUsage_Button_1	= 0x01,	/* (primary/trigger) */

	// 	kHIDUsage_GD_X	= 0x30,	/* Dynamic Value */
	//	kHIDUsage_GD_Y	= 0x31,	/* Dynamic Value */
	//	kHIDUsage_GD_Z	= 0x32,	/* Dynamic Value */
		
	
	NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
	joystickSensitivity = [prefs floatForKey:@"joystickSensitivity"];
	joystickFireButtonMatrix = [prefs floatForKey:@"joystickFireButtonMatrix"];
	reverseXAxis = [prefs floatForKey:@"reverseXAxis"];
	reverseYAxis = [prefs floatForKey:@"reverseYAxis"];
	
	joystickFireButtonMatrixInt = joystickFireButtonMatrix;
	
	// preference options
	//   +/- 5 = joystick sensitity
	//   maybe button position for different joysticks
	//   reverse xaxis
	//   reverse yaxis

	//     |  16  | 8 | 4 | 2 | 1 |
	//     |------|---|---|---|---|
	//     |   0  | 0 | 0 | 0 | 1 |    1 - Up
	//     |   0  | 0 | 0 | 1 | 0 |    2 - Down
	//     |   0  | 0 | 1 | 0 | 0 |    4 - Left
	//     |   0  | 0 | 1 | 0 | 1 |    5 - Up / Left
	//     |   0  | 0 | 1 | 1 | 0 |    6 - Down / left
	//     |   0  | 1 | 0 | 0 | 0 |    8 - Right
	//     |   0  | 1 | 0 | 0 | 1 |    9 - Up / Right
	//     |   0  | 1 | 0 | 1 | 0 |   10 - Down / Right
	//     |   1  | 0 | 0 | 0 | 0 |   16 - Fire
	
	// the action information needs to be a binary instruction to cater for things such as up/left
	action = 0;
	if ( xAxis < (xmid - joystickSensitivity) )
	{		
		if (reverseXAxis)
			{
				action = action + 8; //launcherRight;
			} else {
				action = action + 4; //launcherLeft;
			}
	}
	if ( xAxis > (xmid + joystickSensitivity) )
	{		
		if (reverseXAxis)
		{
			action = action + 4; // launcher left
		} else {
			action = action + 8; //launcherRight;			
		}
	}
  	if ( yAxis < (ymid - joystickSensitivity) )
	{		
		if (reverseYAxis)		
		{
			action = action + 1; //launcherUp;
		} else {
			action = action + 2; //launcherDown;   
		}	
	}
	if ( yAxis > (ymid + joystickSensitivity) )
	{		
		if (reverseYAxis)		
		{
			action = action + 2; //launcherDown;
		} else {
			action = action + 1; //launcherUp;    
		}
	}

//	printf("Button position %d -- ", joystickFireButtonMatrixInt);
	switch (joystickFireButtonMatrixInt)
	{
		case 0: // button 1
			//printf("Button1 fire %ld\n", button1);
			if ( button1 == 1 )
				action = action + 16; //launcherFire;
			break;
			    
		case 1: // button 2
			//printf("Button2 fire %ld\n", button2);
			if ( button2 == 1 )
				action = action + 16; //launcherFire;
			break;
		
		case 2: // button 3
			//printf("Button3 fire %ld\n", button3);
			if ( button3 == 1 )
				action = action + 16; //launcherFire;
			break;
		
		case 3: // button 4
			//printf("Button4 fire %ld\n", button4);
			if ( button4 == 1 )
				action = action + 16; //launcherFire;
			break;
	}

			
	// Generate notification to MissileResponder
	NSDictionary*  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:action], @"Action", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"joystickInput" object:nil userInfo:userInfo];
	
	
}

/*
 
 Logitech Attack 3
 
 Buffer = 83 80 46 08 00 
 Buffer = 83 78 46 08 00 
 Buffer = 83 75 46 08 00 
 Buffer = 83 73 46 08 00 
 Buffer = 83 70 46 08 00 
 Buffer = 83 6e 46 08 00 
 Buffer = 83 6b 46 08 00 
 Buffer = 83 69 46 08 00 
 Buffer = 83 66 46 08 00 
 Buffer = 83 63 46 08 00 
 Buffer = 83 61 46 08 00 
 Buffer = 83 5e 46 08 00 
 Buffer = 83 5c 46 08 00 
 Buffer = 83 59 46 08 00 
 Buffer = 83 54 46 08 00 
 Buffer = 83 4f 46 08 00 
 Buffer = 83 4a 46 08 00 
 Buffer = 83 47 46 08 00 
 Buffer = 83 42 46 08 00 
 Buffer = 83 40 46 08 00 
 Buffer = 83 3b 46 08 00 
 Buffer = 83 38 46 08 00 
 Buffer = 83 36 46 08 00 
 Buffer = 83 33 46 08 00 
 Buffer = 83 31 46 08 00 
 Buffer = 83 2e 46 08 00 
 Buffer = 83 2b 46 08 00 
 Buffer = 83 29 46 08 00 
 Buffer = 83 26 46 08 00 
 Buffer = 83 24 46 08 00 
 Buffer = 83 1f 46 08 00 
 Buffer = 83 1c 46 08 00 
 Buffer = 83 17 46 08 00 
 Buffer = 83 15 46 08 00 
 Buffer = 83 12 46 08 00 
 Buffer = 83 0f 46 08 00 
 Buffer = 83 0d 46 08 00 
 Buffer = 83 0a 46 08 00 
 Buffer = 83 08 46 08 00 
 Buffer = 83 05 46 08 00 
 Buffer = 83 0d 46 08 00 
 Buffer = 83 0f 46 08 00 
 Buffer = 83 12 46 08 00 
 Buffer = 83 15 46 08 00 
 Buffer = 83 1c 46 08 00 
 Buffer = 83 21 46 08 00 
 Buffer = 83 29 46 08 00 
 Buffer = 83 31 46 08 00 
 Buffer = 83 33 46 08 00 
 Buffer = 83 38 46 08 00 
 Buffer = 83 3d 46 08 00 
 Buffer = 83 42 46 08 00 
 Buffer = 83 47 46 08 00 
 Buffer = 83 4f 46 00 00 
 Buffer = 83 59 46 00 00 
 Buffer = 83 5c 46 00 00 
 Buffer = 83 61 46 00 00 
 Buffer = 83 66 46 00 00 
 Buffer = 83 69 46 00 00 
 Buffer = 83 6e 46 00 00 
 Buffer = 83 73 46 00 00 
 Buffer = 83 7a 46 00 00 
 Buffer = 83 7f 46 00 00 
 Buffer = 83 80 46 00 00 
 Buffer = 85 80 46 00 00 
 Buffer = 88 80 46 00 00 
 Buffer = 8a 80 46 00 00 
 Buffer = 8d 80 46 00 00 
 Buffer = 8f 80 46 00 00 
 Buffer = 92 80 46 00 00 
 Buffer = 95 80 46 00 00 
 Buffer = 97 80 46 00 00 
 Buffer = 9c 80 46 00 00 
 Buffer = 9f 80 46 00 00 
 Buffer = a4 80 46 00 00 
 Buffer = ab 83 46 00 00 
 Buffer = ae 83 46 00 00 
 Buffer = ae 85 46 00 00 
 Buffer = b1 85 46 00 00 
 Buffer = b3 85 46 00 00 
 Buffer = bb 88 46 00 00 
 Buffer = bd 88 46 00 00 
 Buffer = c0 88 46 00 00 
 Buffer = ca 8a 46 00 00 
 Buffer = d2 8a 46 00 00 
 Buffer = d4 8a 46 00 00 
 Buffer = d9 8a 46 00 00 
 Buffer = de 8d 46 00 00 
 Buffer = e1 8d 46 00 00 
 Buffer = e6 8d 46 00 00 
 Buffer = ee 8f 46 00 00 
 Buffer = f0 92 46 00 00 
 Buffer = f3 92 46 00 00 
 Buffer = f3 95 46 00 00 
 Buffer = f5 95 46 00 00 
 Buffer = f5 97 46 00 00 
 Buffer = ee 97 46 00 00 
 Buffer = e9 97 46 00 00 
 Buffer = e6 97 46 00 00 
 Buffer = e1 97 46 00 00 
 Buffer = de 97 46 00 00 
 Buffer = d4 97 46 00 00 
 Buffer = cf 97 46 00 00 
 Buffer = ca 8d 46 00 00 
 Buffer = bd 8a 46 00 00 
 Buffer = b6 8a 46 00 00 
 Buffer = ae 8a 46 00 00 
 Buffer = a9 88 46 00 00 
 Buffer = a4 88 46 00 00 
 Buffer = 9c 85 46 00 00 
 Buffer = 95 83 46 00 00 
 Buffer = 8f 80 46 00 00 
 Buffer = 8a 80 46 00 00 
 Buffer = 85 80 46 00 00 
 Buffer = 83 80 46 00 00 
 Buffer = 80 80 46 00 00 
 Buffer = 80 7f 46 00 00 
 Buffer = 7f 7f 46 00 00 
 Buffer = 7f 7f 46 01 00 
 Buffer = 7f 7f 46 00 00 
 Buffer = 7f 7f 46 01 00 
 Buffer = 7f 7f 46 00 00 
 Buffer = 7f 7f 46 01 00 
 Buffer = 7f 7f 46 00 00 
 Buffer = 7f 7f 46 01 00 
 Buffer = 7f 7f 46 00 00 

 
 
 SAITEK Cyborg Evo Wireless
 --------------------------
 What's strange here is that when I move the joystick x asis it works like this...
 
 hard left          center          hard right
 00 <-----------  ff  00  ff -------------> 00
 
 
 And vertical works the same.
 
 
 The reported maxx and maxy seem to be bogus.
 --------------------------------------------
 
          xxx yyy zzz thr     btn
 
 Buffer = 0dc 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=0dc y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 0b2 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=0b2 y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 08b 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=08b y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 073 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=073 y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 06f 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=06f y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 06e 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=06e y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 06f 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=06f y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 06e 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=06e y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 06f 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=06f y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 078 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=078 y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 091 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=091 y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 0cc 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=0cc y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 0fa 0fd 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=0fa y=0fd b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 04a 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=04a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0da 0f6 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0da b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 05a 0f6 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=05a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 006 0f6 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=006 b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 08a 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=08a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 052 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=052 b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 03a 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=03a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 03a 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=03a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 03a 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=03a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 03a 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=03a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 03a 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=03a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 03a 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=03a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 07a 0f5 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=07a b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 042 0f6 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=042 b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0f2 0f6 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0f2 b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 08e 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=08e b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 010 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 010 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 010 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 010 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 Buffer = 000 0fe 0f7 0f7 00f 000 000  -- minx 000, maxx 3ff, miny 000, maxy 3ff,  -- x=000 y=0fe b=0f7 xmid=1ff ymid=1ff 
 
 */



@end
