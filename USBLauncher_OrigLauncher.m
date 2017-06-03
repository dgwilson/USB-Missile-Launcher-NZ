//
//  USBLauncher_OrigLauncher.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 7/05/17.
//  Copyright © 2017 David G. Wilson. All rights reserved.
//

#import "USBLauncher_OrigLauncher.h"

@implementation USBLauncher_OrigLauncher

#pragma mark - HID CONTROL of launcher - Origional Launcher

- (void)missileControlWithBits:(UInt8)controlBits
{
    uint8_t report[8] = {0, 0, 0, 0, 0, 0, 0, 0};
    
    report[0] = 'U';
    report[1] = 'S';
    report[2] = 'B';
    report[3] = 'C';
    report[4] = 0;
    report[5] = 0;
    report[6] = 4;
    report[7] = 0;

    //    IOHIDDeviceRef device = [privateDataRef hidDevice];
    IOHIDDeviceRef device = [self hidDevice];
    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 1, report, sizeof(report));

    report[0] = 'U';
    report[1] = 'S';
    report[2] = 'B';
    report[3] = 'C';
    report[4] = 0;
    report[5] = 64;
    report[6] = 2;
    report[7] = 0;
    
    //    IOHIDDeviceRef device = [privateDataRef hidDevice];
//    IOHIDDeviceRef device = [self hidDevice];
    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 1, report, sizeof(report));

    report[0] |= 0x0;
    report[1] |= 0x0;
    report[2] |= 0x0;
    report[3] |= 0x0;
    report[4] |= 0x0;
    report[5] |= 0x0;
    report[6] |= 0x0;
    report[7] |= 0x0;
    //    NSLog(@"%02X", controlBits);
    if (controlBits & 0x01) //Left
        report[1] |= 1;
    if (controlBits & 0x02) //Right
        report[2] |= 1;
    if (controlBits & 0x04) //Up
        report[3] |= 1;
    if (controlBits & 0x08) //Down
        report[4] |= 1;
    if (controlBits & 0x10) //Fire
        report[5] |= 1;
    
    report[6] |= 8;
    report[7] |= 8;
    
    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 1, report, sizeof(report));
}

@end

//    reqBuffer[0] = 0;
//    if (controlBits & 1)
//        reqBuffer[1] = 1;//left
//        else
//            reqBuffer[1] = 0;
//
//            if (controlBits & 2)
//                reqBuffer[2] = 1;//right
//                else
//                    reqBuffer[2] = 0;//right
//
//                    if (controlBits & 4)
//                        reqBuffer[3] = 1;//up
//                        else
//                            reqBuffer[3] = 0;//up
//
//                            if (controlBits & 8)
//                                reqBuffer[4] = 1;//down
//                                else
//                                    reqBuffer[4] = 0;//down
//
//                                    if (controlBits & 16)
//                                        reqBuffer[5] = 1;//fire
//                                        else
//                                            reqBuffer[5] = 0;//fire
//
//                                            reqBuffer[6] = 8;
//                                            reqBuffer[7] = 8;

//if ([[privateDataRef getLauncherType] isEqualToString:@"OrigLauncher"])
//{
//    
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
//    // ===========================================================================
//    // Control of USB Missile Launcher - Original Launcher
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
//    reqBuffer[0] = 'U';
//    reqBuffer[1] = 'S';
//    reqBuffer[2] = 'B';
//    reqBuffer[3] = 'C';
//    reqBuffer[4] = 0;
//    reqBuffer[5] = 0;
//    reqBuffer[6] = 4;
//    reqBuffer[7] = 0;
//    devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//    devRequest.bRequest = kUSBRqSetConfig;
//    devRequest.wValue = kUSBConfDesc;
//    devRequest.wIndex = 1;
//    devRequest.wLength = 8;
//    devRequest.pData = reqBuffer;
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
//    reqBuffer[0] = 'U';
//    reqBuffer[1] = 'S';
//    reqBuffer[2] = 'B';
//    reqBuffer[3] = 'C';
//    reqBuffer[4] = 0;
//    reqBuffer[5] = 64;
//    reqBuffer[6] = 2;
//    reqBuffer[7] = 0;
//    devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//    devRequest.bRequest = kUSBRqSetConfig;
//    devRequest.wValue = kUSBConfDesc;
//    devRequest.wIndex = 1;
//    devRequest.wLength = 8;
//    devRequest.pData = reqBuffer;
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
//    reqBuffer[0] = 0;
//    if (controlBits & 1)
//        reqBuffer[1] = 1;//left
//        else
//            reqBuffer[1] = 0;
//            
//            if (controlBits & 2)
//                reqBuffer[2] = 1;//right
//                else
//                    reqBuffer[2] = 0;//right
//                    
//                    if (controlBits & 4)
//                        reqBuffer[3] = 1;//up
//                        else
//                            reqBuffer[3] = 0;//up
//                            
//                            if (controlBits & 8)
//                                reqBuffer[4] = 1;//down
//                                else
//                                    reqBuffer[4] = 0;//down
//                                    
//                                    if (controlBits & 16)
//                                        reqBuffer[5] = 1;//fire
//                                        else
//                                            reqBuffer[5] = 0;//fire
//                                            
//                                            reqBuffer[6] = 8;
//                                            reqBuffer[7] = 8;
//                                            devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//                                            devRequest.bRequest = kUSBRqSetConfig; 
//                                            devRequest.wValue = kUSBConfDesc; 
//                                            devRequest.wIndex = 0;
//                                            devRequest.wLength = 64; 
//                                            devRequest.pData = reqBuffer; 
//                                            kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//                                            if (kr != kIOReturnSuccess)
//                                            {
//                                                if (kr == kIOReturnNoDevice)
//                                                {
//                                                    if (debugCommands) 
//                                                        NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//                                                } else
//                                                    if (kr == kIOReturnNotOpen)
//                                                    {
//                                                        if (debugCommands) 
//                                                            NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//                                                    } else
//                                                    {
//                                                        EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//                                                    }
//                                            }
//    
//    // ===========================================================================
//    // END OF Control of USB Missile Launcher
//    // ===========================================================================
//    
//}
