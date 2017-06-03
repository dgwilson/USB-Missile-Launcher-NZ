//
//  USBLauncher_DreamRocket.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 7/05/17.
//  Copyright © 2017 David G. Wilson. All rights reserved.
//

#import "USBLauncher_DreamRocket.h"

@interface USBLauncher_DreamRocket ()
{
}
@property (assign)     BOOL    firingStarted;
@property (assign)     BOOL    firingInProgress;

@end

@implementation USBLauncher_DreamRocket

#pragma mark - HID CONTROL of launcher - DreamRocket

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
    NSLog(@"%s %02X", __PRETTY_FUNCTION__, controlBits);
 
    uint8_t report[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    
    // First Package
    IOHIDDeviceRef deviceRef = [self hidDevice];
    IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, report, sizeof(report));

    
    // Second package - - contains actual instruction
    if (controlBits & 0x01) //Left
        report[0] |= 0x04;
    if (controlBits & 0x02) //Right
        report[0] |= 0x08;
    if (controlBits & 0x04) //Up
        report[0] |= 0x01;
    if (controlBits & 0x08) //Down
        report[0] |= 0x02;
    if (controlBits & 0x10) //Fire
        report[0] |= 0x10;
    IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, report, sizeof(report));
    

    if (controlBits & 0x10) //Fire
    {
        self.firingStarted = TRUE;
        self.firingInProgress = FALSE;
        
        uint8_t data[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        IOHIDDeviceRegisterInputReportCallback(deviceRef,
                                               data,
                                               sizeof(data),
                                               Handle_IOHIDDeviceIOHIDReportCallback,
                                               (__bridge void * _Nullable)(self));
    }

}

static void Handle_IOHIDDeviceIOHIDReportCallback(
                                                  void *          inContext,          // context from IOHIDDeviceRegisterInputReportCallback
                                                  IOReturn        inResult,           // completion result for the input report operation
                                                  void *          inSender,           // IOHIDDeviceRef of the device this report is from
                                                  IOHIDReportType inType,             // the report type
                                                  uint32_t        inReportID,         // the report ID
                                                  uint8_t *       inReport,           // pointer to the report data
                                                  CFIndex         inReportLength ) // the actual size of the input report
{
//    printf( "%s( context: %p, result: %p, sender: %p," \
//           "type: %ld, id: %u, report: %p, length: %ld ).\n",
//           __PRETTY_FUNCTION__, inContext, ( void * ) inResult, inSender,
//           ( long ) inType, inReportID, inReport, inReportLength );
    
//    NSLog(@"report=0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x", inReport[0], inReport[1], inReport[2], inReport[3], inReport[4], inReport[5], inReport[6], inReport[7]);
    
    id self = (__bridge id)(inContext);
    
    if (inReport[1] >= 0x80 && [(USBLauncher_DreamRocket *)self isFiringStarted])
    {
        [(USBLauncher_DreamRocket *)self setFiringInProgress:TRUE];
    }
    
    if (inReport[1] == 0x0 && [(USBLauncher_DreamRocket *)self isFiringInProgress])
    {
//      Cancel the fire sequence
        uint8_t report[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        IOHIDDeviceSetReport(inSender, kIOHIDReportTypeOutput, 0, report, sizeof(report));
        
        // Cancel the call back
        IOHIDDeviceRegisterInputReportCallback(inSender,
                                               report,
                                               sizeof(report),
                                               NULL,
                                               inContext);

//        printf("The report data is: %8.2lf\n", *inReport);
    }
}   // Handle_IOHIDDeviceIOHIDReportCallback

@end

//if ([[privateDataRef getLauncherType] isEqualToString:@"DreamRocket"])
//
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
//    // Control of USB Rocket Launcher - DreamCheeky
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
//    // Control of the launcher works on a binary code - see the table below for an explanation
//    //
//    //     |  16  | 8 | 4 | 2 | 1 |
//    //     |------|---|---|---|---|
//    //     |   0  | 0 | 0 | 0 | 1 |    1 - Up
//    //     |   0  | 0 | 0 | 1 | 0 |    2 - Down
//    //     |   0  | 0 | 0 | 1 | 1 |    3 - nothing
//    //     |   0  | 0 | 1 | 0 | 0 |    4 - Left
//    //     |   0  | 0 | 1 | 0 | 1 |    5 - Up / Left
//    //     |   0  | 0 | 1 | 1 | 0 |    6 - Down / left
//    //     |   0  | 0 | 1 | 1 | 1 |    7 - Slow left
//    //     |   0  | 1 | 0 | 0 | 0 |    8 - Right
//    //     |   0  | 1 | 0 | 0 | 1 |    9 - Up / Right
//    //     |   0  | 1 | 0 | 1 | 0 |   10 - Down / Right
//    //     |   0  | 1 | 0 | 1 | 1 |   11 - Slow Right
//    //     |   0  | 1 | 1 | 0 | 0 |   12 - nothing
//    //     |   0  | 1 | 1 | 0 | 1 |   13 - Slow Up
//    //     |   0  | 1 | 1 | 1 | 0 |   14 - Slow Down
//    //     |   0  | 1 | 1 | 1 | 1 |   15 - nothing
//    //     |   1  | 0 | 0 | 0 | 0 |   16 - Fire
//    //
//    //     | Fire |RT |LT |DN |UP |
//    //
//    //		Thanks to Brandon Heyer for the following:
//    //      the DreamCheeky Launcher will return the following codes
//    //
//    //		00 04 00 00 00 00 00 00 - All the way left
//    //		00 08 00 00 00 00 00 00 - All the way right
//    //		40 00 00 00 00 00 00 00 - All the way down
//    //		80 00 00 00 00 00 00 00 - All the way up
//    //		00 80 00 00 00 00 00 00 - Fire Has completed
//    //		00 84 00 00 00 00 00 00 - Fire Has completed and we're all the way left
//    //		00 88 00 00 00 00 00 00 - Fire Has completed and we're all the way right
//    
//    //		They also OR together when you are in the corners,
//    //		I'd imagine cool patrol sequences (box, figure eight) could be made if these are analyzed while the turret moves.
//    //	Note the definition of the readbuffer (a definition of char doesn't cut the mustard Colonel!)
//    //			UInt8						rBuffer[dreamCheekyMaxPacketSize];
//    
//    // Lets see if we have reached the end of a travel direction
//    // If we have, we need to discontinue moving in that direction
//    // So we have likely received a request to move up for example, so lets cancel that.
//    kr = DreamCheekyReadPipe(missileDevice, missileInterface, rBuffer);
//    if (kr != kIOReturnSuccess)
//    {
//        if (debugCommands)
//            NSLog(@"USBMissileControl: ERROR returned from DreamCheekyReadPipe kr=(0x%08x)", kr);
//    } else
//    {
//        if (debugCommands)
//            NSLog(@"USBMissileControl: return from DreamCheekyReadPipe (0x%02x) (0x%02x) ", rBuffer[0], rBuffer[1]);
//    }
//				
//    //			Left		controlBits |= 1;
//    //			Right		controlBits |= 2;
//    //			Up			controlBits |= 4;
//    //			Down		controlBits |= 8;
//    //			Fire		controlBits |= 16;
//    //			NSLog(@"USBMissileControl: controlBits %d", controlBits);
//    
//    if (rBuffer[0] == 0x40)
//    {
//        if (controlBits & 8)
//        {
//            if (debugCommands)
//                NSLog(@"USBMissileControl: cancelling additional down request");
//            controlBits = controlBits ^8;
//        }
//    } else
//        if (rBuffer[0] == 0x80)
//        {
//            if (controlBits & 4)
//            {
//                if (debugCommands)
//                    NSLog(@"USBMissileControl: cancelling additional up request");
//                controlBits = controlBits ^4;
//            }
//        }
//    if ((rBuffer[1] == 0x04) || (rBuffer[1] == 0x84)) // this command response can get mixed up with Fire
//    {
//        if (controlBits & 1)
//        {
//            if (debugCommands)
//                NSLog(@"USBMissileControl: cancelling additional left request");
//            controlBits = controlBits ^1;
//        }
//    } else
//        if ((rBuffer[1] == 0x08) || (rBuffer[1] == 0x88)) // this command response can get mixed up with Fire
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
//    /*
//     // send the first package - NULL
//     reqBuffer[0] = 0;
//     reqBuffer[1] = 0;
//     reqBuffer[2] = 0;
//     reqBuffer[3] = 0;
//     reqBuffer[4] = 0;
//     reqBuffer[5] = 0;
//     reqBuffer[6] = 0;
//     reqBuffer[7] = 0;
//     devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//     devRequest.bRequest = 0x09;
//     devRequest.wValue = 0x0000200;
//     devRequest.wIndex = 0;
//     devRequest.wLength = 1;
//     devRequest.pData = reqBuffer;
//     if (debugCommands)
//     {
//     NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//     NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//     NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//     NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//     NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//     NSLog(@"USBMissileControl: DreamCheeky command package (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
//     }
//     kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//     if (debugCommands)
//     {
//     if (kr != kIOReturnSuccess)
//     {
//					if (kr == kIOReturnNoDevice)
//					{
//     if (debugCommands)
//     NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//					} else
//     if (kr == kIOReturnNotOpen)
//     {
//     if (debugCommands)
//     NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//     } else
//     {
//     NSLog(@"USBMissileControl: ERROR sending the first package - NULL");
//     EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//     }
//     }
//     }
//     
//     */
//        
//        // send the second package - contains actual instruction
//        reqBuffer[0] = 0x00;
//        gBuffer[0] = 0x00;
//        if (controlBits & 1)   // left
//        {
//            reqBuffer[0] |= 4;
//            gBuffer[0]   |= 4;  // added for WritePipe support 27Jan2007
//        }
//    if (controlBits & 2)   // right
//    {
//        reqBuffer[0] |= 8;
//        gBuffer[0]   |= 8;  // added for WritePipe support 27Jan2007
//    }
//    if (controlBits & 4)   // up
//    {
//        reqBuffer[0] |= 1;
//        gBuffer[0]   |= 1;  // added for WritePipe support 27Jan2007
//    }
//    if (controlBits & 8)   // down
//    {
//        reqBuffer[0] |= 2;
//        gBuffer[0]   |= 2;  // added for WritePipe support 27Jan2007
//    }
//    if ((controlBits & 16) || (controlBits & 128))  // Fire
//    {
//        reqBuffer[0] |= 16;
//        gBuffer[0]   |= 16;  // added for WritePipe support 27Jan2007
//        if (debugCommands)
//        {
//            NSLog(@"USBMissileControl: MissileControl - DreamCheeky Fire initiated");
//        }
//    }
//    
//    reqBuffer[1] = 0x00;
//    reqBuffer[2] = 0x00;
//    reqBuffer[3] = 0x00;
//    reqBuffer[4] = 0x00;
//    reqBuffer[5] = 0x00;
//    reqBuffer[6] = 0x00;
//    reqBuffer[7] = 0x00;
//    devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//    devRequest.bRequest = 0x09;
//    devRequest.wValue = 0x0000200;
//    devRequest.wIndex = 0;
//    devRequest.wLength = 1;
//    devRequest.pData = reqBuffer;
//    if (debugCommands)
//    {
//        NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//        NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//        NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//        NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//        NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//        NSLog(@"USBMissileControl: DreamCheeky command package (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
//    }
//    kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//    if (debugCommands)
//    {
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
//                {   // Error seems to be generated from this and I can't figure out why
//                    // USBMissileControl: EvaluateUSBErrorCode: kIOReturnOverrun (0xe00002e8) - There has been a data overrun.
//                    // It all seems to still work, so I'm going to ignore it.
//                    
//                    //	NSLog(@"USBMissileControl: ERROR delivering command package");
//                    //	EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//                }
//        }
//    }
//    
//    if (controlBits & 16)
//    {
//        // Need to stop the fire sequence - otherwise it continues without stopping
//        // if we read (or look for feedback from the launcher) it will tell us when the fire has completed
//        //
//        // readPipe: message: 00 00 00 00 00 00 00 00
//        // readPipe: message: 00 80 00 00 00 00 00 00
//        // readPipe: message: 00 00 00 00 00 00 00 00
//        //
//        // byte #2 is the fire acknowledgement
//        
//        //[self DGWScheduleCancelLauncherCommand:5.500]; // this was the old code before the launcher feedback was being read
//        
//        int delayCounter;
//        for (delayCounter = 0; delayCounter < 70; delayCounter ++)
//        {
//            [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.100]];
//            //					kr = DreamCheekyReadPipe(missileDevice, missileInterface, rBuffer);
//            DreamCheekyReadPipe(missileDevice, missileInterface, rBuffer);
//            if (rBuffer[1] >= 0x80)
//            {
//                // The 0x80 status doesn't always mean that firing has occurred, but it will be very close
//                // - wait at least 500ms before sending the NULL after receiving 0x80
//                [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.000]];
//                // Fire command completed
//                // send the third package - NULL
//                reqBuffer[0] = 0;
//                reqBuffer[1] = 0;
//                reqBuffer[2] = 0;
//                reqBuffer[3] = 0;
//                reqBuffer[4] = 0;
//                reqBuffer[5] = 0;
//                reqBuffer[6] = 0;
//                reqBuffer[7] = 0;
//                devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//                devRequest.bRequest = 0x09;
//                devRequest.wValue = 0x0000200;
//                devRequest.wIndex = 0;
//                devRequest.wLength = 8;
//                devRequest.pData = reqBuffer;
//                if (debugCommands)
//                {
//                    NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//                    NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//                    NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//                    NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//                    NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//                    NSLog(@"USBMissileControl: DreamCheeky command package (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
//                }
//                kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//                if (debugCommands)
//                {
//                    if (kr != kIOReturnSuccess)
//                    {
//                        if (kr == kIOReturnNoDevice)
//                        {
//                            if (debugCommands)
//                                NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//                        } else
//                            if (kr == kIOReturnNotOpen)
//                            {
//                                if (debugCommands)
//                                    NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//                            } else
//                            {
//                                EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//                            }
//                    }
//                }
//                
//                break;
//            }
//            
//        }
//        
//    }
//    
//    if (controlBits & 128)
//    {
//        // Need to stop the fire sequence - otherwise it continues without stopping
//        // What we're trying to do here is prime the launcher for firing
//        // So we don't actually want to FIRE
//        
//        int delayCounter;
//        for (delayCounter = 0; delayCounter < 35; delayCounter ++)  // 3.5 seconds
//        {
//            [NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:0.100]];
//        }
//        
//        // send a NULL package to shut things down.
//        reqBuffer[0] = 0;
//        reqBuffer[1] = 0;
//        reqBuffer[2] = 0;
//        reqBuffer[3] = 0;
//        reqBuffer[4] = 0;
//        reqBuffer[5] = 0;
//        reqBuffer[6] = 0;
//        reqBuffer[7] = 0;
//        devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//        devRequest.bRequest = 0x09; 
//        devRequest.wValue = 0x0000200;
//        devRequest.wIndex = 0;
//        devRequest.wLength = 8;
//        devRequest.pData = reqBuffer; 
//        if (debugCommands)
//        {
//            NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//            NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//            NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//            NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//            NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//            NSLog(@"USBMissileControl: DreamCheeky command package (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x) (0x%02x)", reqBuffer[0], reqBuffer[1], reqBuffer[2], reqBuffer[3], reqBuffer[4], reqBuffer[5], reqBuffer[6], reqBuffer[7]);
//        }
//        kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//        if (debugCommands)
//        {
//            if (kr != kIOReturnSuccess)
//            {
//                if (kr == kIOReturnNoDevice)
//                {
//                    if (debugCommands) 
//                        NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//                } else
//                    if (kr == kIOReturnNotOpen)
//                    {
//                        if (debugCommands) 
//                            NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//                    } else
//                    {
//                        EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//                    }
//            }	
//        }
//    }			
//    
//    // ===========================================================================
//    // END OF USB Rocket Launcher - DreamCheeky
//    // ===========================================================================
//}
