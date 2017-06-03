//
//  USBLauncher_StrikerII.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 7/05/17.
//  Copyright © 2017 David G. Wilson. All rights reserved.
//

#import "USBLauncher_StrikerII.h"

@implementation USBLauncher_StrikerII

#pragma mark - HID CONTROL of launcher - Striker II

- (void)missileControlWithBits:(UInt8)controlBits
{
    uint8_t report[8] = {0x14, 0x14, 0, 0, 0, 0, 0, 0};
    
    //    IOHIDDeviceRef device = [privateDataRef hidDevice];
    IOHIDDeviceRef device = [self hidDevice];
    //    NSLog(@"%02X", controlBits);
    if (controlBits & 0x01) //Left
        report[0] |= 0x0c;
    if (controlBits & 0x02) //Right
        report[0] |= 0x0d;
    if (controlBits & 0x04) //Up
        report[0] |= 0x0e;
    if (controlBits & 0x08) //Down
        report[0] |= 0x0f;
    if (controlBits & 0x10) //Fire
        report[0] |= 0x0a;
    if (controlBits & 0x64) //Laser
        report[0] |= 0x0b;

    if (controlBits > 0)
        report[1] |= 0x0;

    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, report, sizeof(report));
}

@end


//if ([[privateDataRef getLauncherType] isEqualToString:@"StrikerII"])
//{
//    // This code is here because I need to know the launcher type so that the right launcher can be parked
//    // So this procedure ends up being call again by the procedure that is being called, i.e. MissileLauncher_Park
//    if (controlBits & 32)  // Park
//    {
//        //NSLog(@"USBMissileControl: MissileControl - MissileLauncher Park");
//        // controlBits = 0;  // we're outa here, so don't need to worry about setting the controlBits
//        [self MissileLauncher_Park];
//        return self;
//    }
//    
//    /*
//     2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] controlLauncher: Laser Toggle Request START
//     2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] USBMissileControl: launcherType = StrikerII
//     2007-06-21 21:33:12.295 USB Missile Launcher NZ[14304] USBMissileControl: USBVendorID = 4400 (0x1130)
//     2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: USBProductID = 514 (0x202)
//     2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: controlBits 64
//     2007-06-21 21:33:12.296 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=11, reqBuffer[1]=11
//     2007-06-21 21:33:12.297 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=20, reqBuffer[1]=20
//     
//     --> here's the reason the laser goes off, this is being called twice...
//     
//     2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: launcherType = StrikerII
//     2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: USBVendorID = 4400 (0x1130)
//     2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: USBProductID = 514 (0x202)
//     2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: controlBits 64
//     2007-06-21 21:33:12.298 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=11, reqBuffer[1]=11
//     2007-06-21 21:33:12.299 USB Missile Launcher NZ[14304] USBMissileControl: STRIKER II reqBuffer[0]=20, reqBuffer[1]=20
//     2007-06-21 21:33:12.300 USB Missile Launcher NZ[14304] controlLauncher: Laser Toggle Request FINISH
//     */
//    
//    
//    // ===========================================================================
//    // Control of USB Missile Launcher - Striker II
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
//    /*
//     USB Information (hexadecimal values):
//     Vendor ID: 1130
//     Product ID: 0202
//     
//     Ignore this little table for now, I'm just trying to reverse engineer
//     what the launcher developers have done. not much help for up/left try activities
//     like the other launchers support.
//     |  16  | 8 | 4 | 2 | 1 |
//     |------|---|---|---|---|
//     |   0  | 1 | 0 | 1 | 0 |   10 - fire
//     |   0  | 1 | 0 | 1 | 1 |   11 - laser
//     |   0  | 1 | 1 | 0 | 0 |   12 - left
//     |   0  | 1 | 1 | 0 | 1 |   13 - right
//     |   0  | 1 | 1 | 1 | 0 |   14 - up
//     |   0  | 1 | 1 | 1 | 1 |   15 - down
//     |   1  | 0 | 1 | 0 | 0 |   20 - release
//     
//     Toy Command Bytes (hexadecimal values):
//     Fire Missile  = 0x0a	10
//     Laser Toggle  = 0x0b	11
//     Move Left = 0x0c		12
//     Move Right = 0x0d		13
//     Move Up = 0x0e			14
//     Move Down  = 0x0f		15
//     Release = 0x14			20
//     
//     
//     This documentation from the supplier would appear to be WRONG!
//     Actually bytes 0 and 1 need to be filled followed by zeros in the remaining bytes up to 8.
//     This information was discovered by using SnoopyPro on a PC.
//     
//     Sending Toy Commands with Control Transfer (PC to Toy):
//     Byte 0: 0
//     Byte 1: toyCommandByte
//     Byte 2: toyCommandByte
//     
//     Example Toy Command with Control Transfer: Move Left
//     Byte 0: 0
//     Byte 1: 0x0c
//     Byte 2: 0x0c  Send...
//     
//     Byte 0: 0
//     Byte 1: 0x14
//     Byte 2: 0x14  Send...
//     */
//    reqBuffer[0] = 0;
//    if (controlBits & 1)
//        reqBuffer[0] = 0x0c;//left
//        
//        if (controlBits & 2)
//            reqBuffer[0] = 0x0d;//right
//            
//            if (controlBits & 4)
//                reqBuffer[0] = 0x0e;//up
//                
//                if (controlBits & 8)
//                    reqBuffer[0] = 0x0f;//down
//                    
//                    if (controlBits & 16)
//                        reqBuffer[0] = 0x0a;//fire
//                        
//                        if (controlBits & 64)
//                            reqBuffer[0] = 0x0b;//Laser Toggle
//                            
//                            if (reqBuffer[0] == 0)
//                            {
//                                reqBuffer[0] = 0x14;   // this is a guess. If I come back into this routine with a 0 controlBit
//                                reqBuffer[1] = 0x14;   // then perhaps I should send a "stop" or in this case a "release" to the launcher?
//                            } else
//                            {
//                                reqBuffer[1] = reqBuffer[0];
//                            }
//    reqBuffer[2] = 0;
//    reqBuffer[3] = 0;
//    reqBuffer[4] = 0;
//    reqBuffer[5] = 0;
//    reqBuffer[6] = 0;
//    reqBuffer[7] = 0;
//    devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//    devRequest.bRequest = kUSBRqSetConfig;
//    devRequest.wValue = kUSBConfDesc;
//    devRequest.wIndex = 0;
//    devRequest.wLength = 8;
//    devRequest.pData = reqBuffer;
//    if (debugCommands)
//    {
//        NSLog(@"USBMissileControl: STRIKER II reqBuffer[0]=%d, reqBuffer[1]=%d", reqBuffer[0], reqBuffer[1]);
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
//    //			if (controlBits & 64)  //Laser Toggle
//    //			if ((controlBits & 16) || (controlBits & 64))
//    if (controlBits & 16)
//    {
//        // after the fire comand, we can't send the "release" to the launcher
//        // so, NO OPP
//    } else
//    {
//        reqBuffer[0] = 0x14; // release
//        reqBuffer[1] = 0x14; // release
//        reqBuffer[2] = 0;
//        reqBuffer[3] = 0;
//        reqBuffer[4] = 0;
//        reqBuffer[5] = 0;
//        reqBuffer[6] = 0;
//        reqBuffer[7] = 0;
//        devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//        devRequest.bRequest = kUSBRqSetConfig;
//        devRequest.wValue = kUSBConfDesc;
//        //				devRequest.wIndex = 0;  // Switched this to 1 after mail from Erik Mason - 1 May 2007
//        devRequest.wIndex = 1;  // having this as 1 may cause a problem with the "release" command
//        // Erik Mason reported that movement doesn't stop until launcher reaches end of travel
//        devRequest.wLength = 8;
//        devRequest.pData = reqBuffer;
//        if (debugCommands)
//        {
//            NSLog(@"USBMissileControl: STRIKER II reqBuffer[0]=%d, reqBuffer[1]=%d", reqBuffer[0], reqBuffer[1]);
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
//    }
//    
//    // ===========================================================================
//    // END OF Control of USB Missile Launcher - Striker II
//    // ===========================================================================
//    
//}
//else
