//
//  USBLauncher_DreamRocketII.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 7/05/17.
//  Copyright © 2017 David G. Wilson. All rights reserved.
//

#import "USBLauncher_DreamRocketII.h"

@interface USBLauncher_DreamRocketII ()
{
    NSUInteger fireTimerCount;
    NSTimer * myTimer;
}
@property (assign)     BOOL    firingStarted;
@property (assign)     BOOL    firingInProgress;

@end

@implementation USBLauncher_DreamRocketII

// This launcher also has the name RocketBaby - a Green/Black coloured launcher
// The Blue/Black launcher - with mounted camera on top known as the MSN launcher - is also internally a RockeyBaby


#pragma mark - HID CONTROL of launcher - DreamRocket II aka RocketBaby

- (BOOL)isFiringStarted
{
    return _firingStarted;
}
- (BOOL)isFiringInProgress
{
    return _firingInProgress;
}

- (void)missileControlWithBits:(UInt8)controlBits
{
//    NSLog(@"%s %02X", __PRETTY_FUNCTION__, controlBits);
    
    uint8_t report[8] = {0x20, 0, 0, 0, 0, 0, 0, 0};
    
    // First Package
    IOHIDDeviceRef deviceRef = [self hidDevice];
    IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, report, sizeof(report));
    
    report[0] = 0x0;
    
    // Second package - - contains actual instruction
    if (controlBits & 0x01) //Left
        report[0] |= 0x04;
    if (controlBits & 0x02) //Right
        report[0] |= 0x08;
    if (controlBits & 0x04) //Up
        report[0] |= 0x02;
    if (controlBits & 0x08) //Down
        report[0] |= 0x01;
    if (controlBits & 0x10) //Fire
        report[0] |= 0x10;
    IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, report, sizeof(report));
    
    
    if (controlBits & 0x10) //Fire
    {
//        uint8_t report[8] = {0x40, 0, 0, 0, 0, 0, 0, 0};
//        IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, report, sizeof(report));

        self.firingStarted = TRUE;
        self.firingInProgress = FALSE;
        
        fireTimerCount = 0;
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                   target:self
                                                 selector:@selector(pollDeviceTimer:)
                                                 userInfo:nil 
                                                  repeats:YES];
        
        
//        IOHIDDeviceRegisterInputReportCallback(deviceRef,
//                                               data,
//                                               sizeof(data),
//                                               Handle_IOHIDDeviceIOHIDReportCallback,
//                                               (__bridge void * _Nullable)(self));
    }
    
}

- (void)commandStop
{
    uint8_t report[8] = {0x20, 0, 0, 0, 0, 0, 0, 0};
    
    // First Package
    IOHIDDeviceRef deviceRef = [self hidDevice];
    IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, report, sizeof(report));

}

- (void)getLauncherStatus
{
    uint8_t data[8] = {0x40, 0, 0, 0, 0, 0, 0, 0};
    IOHIDDeviceRef deviceRef = [self hidDevice];
    IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, data, sizeof(data));
    
    
    NSData * responseDataA = [self USBHIDGetDataForElement:2];		// Says when max up / max down has been reached
    NSData * responseDataB = [self USBHIDGetDataForElement:3];		// Says when Fire has completed, and max left / right (data in byte 1)
    
    
    // what if responseDataA isn't long enough!
    // TODO: Fix this!
    
    NSMutableData * responseData = [NSMutableData dataWithData:responseDataA];
    [responseData replaceBytesInRange:NSMakeRange(1,1) withBytes:[responseDataB bytes] length:1];	// byte 2 = response for element 3
    [self decodeDataFromDevice:responseData];
}

- (void)decodeDataFromDevice:(NSData *)responseData
{
//    NSLog(@"%@ responseData=%@", NSStringFromSelector(_cmd), responseData);
    
    if ([responseData length] == 0)		// avoid a crash in a nil response scenario
        return;
    
    UInt8 * launcherStatusValue = (UInt8 *)[responseData bytes];	// used for launcher feedback
    NSLog(@"launcherStatusValue=0x%02x", launcherStatusValue[0]);
    
    UInt8 status = ((launcherStatusValue[0]) & 0x0F);
    if (((launcherStatusValue[0] == 0x10) || ( status >= 0x10)) && (fireTimerCount > 5))// Fire command completed
    {
        // The 0x10 status doesn't always mean that firing has occurred, but it will be very close
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.50]];
        
        [self commandStop];
        [myTimer invalidate];	// this will also remove it from the runloop
        myTimer = nil;
    }
}

- (void)pollDeviceTimer:(NSTimer*)timer
{
    //	NSLog(@"%@", NSStringFromSelector(_cmd));
    fireTimerCount ++;
    if (fireTimerCount > 30)
    {
        self.firingStarted = FALSE;
        [myTimer invalidate];	// this will also remove it from the runloop
        myTimer = nil;
    }
    else
    {
        //			[self performSelectorOnMainThread:@selector(getStatus) withObject:nil waitUntilDone:NO];
        [self performSelector:@selector(getLauncherStatus) withObject:nil];
    }
}

//static void Handle_IOHIDDeviceIOHIDReportCallback(
//                                                  void *          inContext,          // context from IOHIDDeviceRegisterInputReportCallback
//                                                  IOReturn        inResult,           // completion result for the input report operation
//                                                  void *          inSender,           // IOHIDDeviceRef of the device this report is from
//                                                  IOHIDReportType inType,             // the report type
//                                                  uint32_t        inReportID,         // the report ID
//                                                  uint8_t *       inReport,           // pointer to the report data
//                                                  CFIndex         inReportLength ) // the actual size of the input report
//{
//    //    printf( "%s( context: %p, result: %p, sender: %p," \
//    //           "type: %ld, id: %u, report: %p, length: %ld ).\n",
//    //           __PRETTY_FUNCTION__, inContext, ( void * ) inResult, inSender,
//    //           ( long ) inType, inReportID, inReport, inReportLength );
//    
//    NSLog(@"report=0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x", inReport[0], inReport[1], inReport[2], inReport[3], inReport[4], inReport[5], inReport[6], inReport[7]);
//    
//    id self = (__bridge id)(inContext);
//    
//    if (inReport[1] == 0x0 && [(USBLauncher_DreamRocketII *)self isFiringStarted])
//    {
//        [(USBLauncher_DreamRocketII *)self setFiringInProgress:TRUE];
//        
//        // Keep calling - status will change when teh firing completes
//        uint8_t data[8] = {0, 0, 0, 0, 0, 0, 0, 0};
//        IOHIDDeviceRegisterInputReportCallback(inSender,
//                                               data,
//                                               sizeof(data),
//                                               Handle_IOHIDDeviceIOHIDReportCallback,
//                                               inContext);
//
//    }
//    
//    if (inReport[1] == 0x10 && [(USBLauncher_DreamRocketII *)self isFiringInProgress])
//    {
//        //      Cancel the fire sequence
//        uint8_t report[8] = {0x20, 0, 0, 0, 0, 0, 0, 0};
//        IOHIDDeviceSetReport(inSender, kIOHIDReportTypeOutput, 0, report, sizeof(report));
//        
//        // Cancel the call back
//        IOHIDDeviceRegisterInputReportCallback(inSender,
//                                               report,
//                                               sizeof(report),
//                                               NULL,
//                                               inContext);
//        
//        //        printf("The report data is: %8.2lf\n", *inReport);
//    }
//}   // Handle_IOHIDDeviceIOHIDReportCallback


@end

//if ([[privateDataRef getLauncherType] isEqualToString:@"DreamRocketII"])
//{
//    
//    // This code is here because I need to know the launcher type so that the right launcher can be parked
//    // So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
//    if (controlBits & 32)  // Park
//    {
//        //NSLog(@"USBMissileControl: MissileControl - DreamCheeky Park");
//        // controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
//        [self DreamCheeky_Park];
//        return self;
//    }
//    
//    // ===========================================================================
//    // Control of USB Rocket Launcher - DreamCheeky II  (Rocket Baby)
//    // ===========================================================================
//    if (debugCommands)
//    {
//        NSLog(@"USBMissileControl: launcherType = %@", [privateDataRef getLauncherType]);
//        NSLog(@"USBMissileControl: USBVendorID  = %d (0x%d)", (int)[privateDataRef getusbVendorID], (int)[privateDataRef getusbVendorID]);
//        NSLog(@"USBMissileControl: USBProductID = %d (0x%d)", (int)[privateDataRef getusbProductID], (int)[privateDataRef getusbProductID]);
//        //				NSLog(@"USBMissileControl: device       = (0x%x)", [privateDataRef deviceInterface]);
//        NSLog(@"USBMissileControl: controlBits  = %d", controlBits);
//    }
//    
//    // USBVendorID  = 2689 (0xa81)
//    // USBProductID = 1793 (0x701)
//    
//    // Control of the launcher works on a binary code - see the table below for an explanation
//    //
//    // Set up Packet - 21 09 00 02 00 00 00 00
//    //
//    // 0x01  - down
//    // 0x02  - up
//    // 0x04  - left
//    // 0x08  - right
//    // 0x10  - fire
//    // 0x20  - stop
//    // 0x40  - request status
//    //
//    //	1. To fire, Send 0x10
//    //  2. The motor keeps working now, keep sending 0x40 to ask for status (say, every 100~500ms)
//    //	3. If 0x00 received, then the missile is not fired.
//    //	4. If 0x10 received, them missile is fired.
//    //	5. If the missile is fired, send 0x20 to stop it.
//    //
//    //  Other launcher Responses - these are returned as bits and thus you need to check like "if (rbBuffer[0] & 0x01)" using Bitwise AND
//    //  0x01 - all the way down
//    //  0x02 - all the way up
//    //  0x04 - all the way left
//    //  0x08 - all the way right
//    //  0x10 - fire has completed
//    //
//    //	The user has to use a USB Control Endpoint to send the command and to use the USB IN endpoint to read the status.
//    //
//    //     |  16  | 8 | 4 | 2 | 1 |
//    //     |------|---|---|---|---|
//    //     |   0  | 0 | 0 | 0 | 1 |    1 - Down
//    //     |   0  | 0 | 0 | 1 | 0 |    2 - Up
//    //     |   0  | 0 | 1 | 0 | 0 |    4 - Left
//    //     |   0  | 1 | 0 | 0 | 0 |    8 - Right
//    //     |   0  | 1 | 0 | 1 | 0 |   10 - Fire
//    //     |   1  | 0 | 1 | 0 | 0 |   20 - Stop
//    //
//    //     | Fire |RT |LT |UP |DN |
//    //
//    
//    
//    // Lets see if we have reached the end of a travel direction
//    // If we have, we need to discontinue moving in that direction
//    // So we have likely received a request to move up for example, so lets cancel that.
//    rbBuffer[0] = 0x00;
//    kr = RocketBabyReadPipe(missileDevice, missileInterface, rbBuffer);
//    if (kr != kIOReturnSuccess)
//    {
//        if (debugCommands)
//            NSLog(@"USBMissileControl: ERROR returned from DreamCheekyReadPipe kr=(0x%08x)", kr);
//    } else
//    {
//        if (debugCommands)
//            NSLog(@"USBMissileControl: return from RocketBabyReadPipe (0x%02x)", rbBuffer[0]);
//    }
//				
//    //			Left		controlBits |= 1;
//    //			Right		controlBits |= 2;
//    //			Up			controlBits |= 4;
//    //			Down		controlBits |= 8;
//    //			Fire		controlBits |= 16;
//    //			NSLog(@"USBMissileControl: controlBits %d", controlBits);
//    
//    if (rbBuffer[0] & 0x01)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
//    {
//        if (controlBits & 8)
//        {
//            if (debugCommands)
//                NSLog(@"USBMissileControl: cancelling additional down request");
//            controlBits = controlBits ^8;
//        }
//    } else
//        if (rbBuffer[0] & 0x02)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
//        {
//            if (controlBits & 4)
//            {
//                if (debugCommands)
//                    NSLog(@"USBMissileControl: cancelling additional up request");
//                controlBits = controlBits ^4;
//            }
//        }
//    if (rbBuffer[0] & 0x04)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
//    {
//        if (controlBits & 1)
//        {
//            if (debugCommands)
//                NSLog(@"USBMissileControl: cancelling additional left request");
//            controlBits = controlBits ^1;
//        }
//    } else
//        if (rbBuffer[0] & 0x08)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
//        {
//            if (controlBits & 2)
//            {
//                if (debugCommands)
//                    NSLog(@"USBMissileControl: cancelling additional right request");
//                controlBits = controlBits ^2;
//            }
//        }
//    if (debugCommands)
//        NSLog(@"USBMissileControl: controlBits %d", controlBits);
//        
//        
//        // send the package - contains actual instruction
//        reqBuffer_RB[0] = 0x00;
//        if (controlBits == 0)   // Launcher STOP (so if no command is sent, we instruct STOP)
//        {
//            reqBuffer_RB[0] = 0x20;
//        }
//    
//    // this launcher does not understand "Up & Left" type commands together. The software simulates it and will get the
//    // desired end result, however the launcher cannot drive 2 x servo motors at once using the command set available.
//    if (controlBits & 1)   // left
//    {
//        reqBuffer_RB[0] = 4;
//    }
//    if (controlBits & 2)   // right
//    {
//        reqBuffer_RB[0] = 8;
//    }
//    if (controlBits & 4)   // up
//    {
//        reqBuffer_RB[0] = 2;
//    }
//    if (controlBits & 8)   // down
//    {
//        reqBuffer_RB[0] = 1;
//    }
//    
//    
//    if ((controlBits & 16) || (controlBits & 128)) // Fire
//    {
//        reqBuffer_RB[0] = 0x10;
//        if (debugCommands)
//        {
//            NSLog(@"USBMissileControl: MissileControl - DreamCheeky Fire (or Prime) initiated");
//        }
//    }
//    
//    devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//    devRequest.bRequest = 0x09;
//    devRequest.wValue = 0x0000200;
//    devRequest.wIndex = 0;
//    devRequest.wLength = 1;
//    devRequest.pData = reqBuffer_RB;
//    if (debugCommands)
//    {
//        NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//        NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//        NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//        NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//        NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//        NSLog(@"USBMissileControl: Rocket Baby command package (0x%02x) delivered", reqBuffer_RB[0]);
//        if( debugCommands && reqBuffer_RB[0] == 0x00)
//            NSLog(@"USBMissileControl: controlBits (0x%04x)", controlBits);
//    }
//    kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//    if (kr != kIOReturnSuccess)
//    {
//        if (kr == kIOReturnNoDevice)
//        {
//            if (debugCommands)
//                NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//        } else
//            if (kr == kIOReturnNotOpen)
//            {
//                if (debugCommands)
//                    NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//            } else
//            {
//                EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//            }
//    }
//    
//    if (controlBits & 16)
//    {
//        // Need to stop the fire sequence - otherwise it continues without stopping
//        // if we read (or look for feedback from the launcher) it will tell us when the fire has completed
//        //
//        int delayCounter;
//        for (delayCounter = 0; delayCounter < 500; delayCounter ++)
//        {
//            //[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:0.100]];
//            rbBuffer[0] = 0x00;
//            kr = RocketBabyReadPipe(missileDevice, missileInterface, rbBuffer);
//            if (kr != kIOReturnSuccess)
//            {
//                // error output has already been produced c/- RocketBabyReadPipe
//                break;
//            }
//            
//            if (rbBuffer[0] & 0x10)
//            {
//                // The 0x10 status doesn't always mean that firing has occurred, but it will be very close
//                // - wait at least 500ms before sending 0x20 after receiving 0x10
//                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.500]];
//                
//                // Fire command completed
//                // send the third package - 0x20
//                reqBuffer_RB[0] = 0x20;
//                devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//                devRequest.bRequest = 0x09;
//                devRequest.wValue = 0x0000200;
//                devRequest.wIndex = 0;
//                devRequest.wLength = 1;
//                devRequest.pData = reqBuffer_RB;
//                if (debugCommands)
//                {
//                    //NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//                    //NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//                    //NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//                    //NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//                    //NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//                    NSLog(@"USBMissileControl: Rocket Baby command package (0x%02x) delivered", reqBuffer_RB[0]);
//                }
//                kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//                if (kr != kIOReturnSuccess)
//                {
//                    if (kr == kIOReturnNoDevice)
//                    {
//                        if (debugCommands)
//                            NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//                    } else
//                        if (kr == kIOReturnNotOpen)
//                        {
//                            if (debugCommands)
//                                NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//                        } else
//                        {
//                            EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//                        }
//                }
//                
//                break;
//            }
//            
//        }
//        
//    }
//    
//    if (controlBits & 128) // Prime Launcher
//    {
//        // Need to stop the prime sequence - otherwise it continues without stopping
//        // if we read (or look for feedback from the launcher) it will tell us when the fire has completed
//        //
//        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
//        
//        // Fire command completed
//        // send the third package - 0x20
//        reqBuffer_RB[0] = 0x20;
//        devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//        devRequest.bRequest = 0x09;
//        devRequest.wValue = 0x0000200;
//        devRequest.wIndex = 0;
//        devRequest.wLength = 1;
//        devRequest.pData = reqBuffer_RB; 
//        if (debugCommands)
//        {
//            //	NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//            //	NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//            //	NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//            //	NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//            //	NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//            NSLog(@"USBMissileControl: Rocket Baby command package (0x%02x) delivered", reqBuffer_RB[0]);
//        }
//        kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//        if (kr != kIOReturnSuccess)
//        {
//            if (kr == kIOReturnNoDevice)
//            {
//                if (debugCommands) 
//                    NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//            } else
//                if (kr == kIOReturnNotOpen)
//                {
//                    if (debugCommands) 
//                        NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//                } else
//                {
//                    EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//                }
//        }	
//        
//    }
//    // ===========================================================================
//    // END OF USB Rocket Launcher - DreamCheeky II (Rocket Baby)
//    // ===========================================================================
//}
