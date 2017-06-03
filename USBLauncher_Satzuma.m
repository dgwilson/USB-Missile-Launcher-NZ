//
//  USBLauncher_Satzuma.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 7/05/17.
//  Copyright © 2017 David G. Wilson. All rights reserved.
//

#import "USBLauncher_Satzuma.h"

@implementation USBLauncher_Satzuma

#pragma mark - HID CONTROL of launcher - Satzuma

- (void)missileControlWithBits:(UInt8)controlBits
{
    uint8_t report[8] = {0x5f, 0, 0xe0, 0xff, 0xfe, 0x30, 0, 0};    // suspect the 0x30 is wrong
    
    //    IOHIDDeviceRef device = [privateDataRef hidDevice];
    IOHIDDeviceRef device = [self hidDevice];
    //    NSLog(@"%02X", controlBits);
    if (controlBits & 0x01) //Left
        report[1] |= 0x08;
    if (controlBits & 0x02) //Right
        report[1] |= 0x04;
    if (controlBits & 0x04) //Up
        report[1] |= 0x02;
    if (controlBits & 0x08) //Down
        report[1] |= 0x01;
    if (controlBits & 0x10) //Fire
        report[1] |= 0x10;
    
    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, report, sizeof(report));
}

@end

//	Satzuma Missile launcher (actually Winbond Electronics Corp.)
//	USB Vendor ID		0x416	1046
//	USB Product ID		0x9391	37777


// STOP      = 0x0
// LEFT      = 0x8
// RIGHT     = 0x4
// UP        = 0x2
// DOWN      = 0x1
// LEFTUP    = LEFT + UP
// RIGHTUP   = RIGHT + UP
// LEFTDOWN  = LEFT + DOWN
// RIGHTDOWN = RIGHT + DOWN
// FIRE      = 0x10

//if ([[privateDataRef getLauncherType] isEqualToString:@"Satzuma"])
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
//    // Control of USB Missile Launcher - Original Launcher NOT CHANGED YET NOT CHANGED YET NOT CHANGED YET
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
//    reqBuffer[0] = 0x5f;
//    reqBuffer[1] = 0x00;
//    reqBuffer[2] = 0xe0;
//    reqBuffer[3] = 0xff;
//    reqBuffer[4] = 0xfe;
//    reqBuffer[5] = 0x0300;
//    reqBuffer[6] = 0x00;
//    reqBuffer[7] = 0x00;
//    
//    if (controlBits & 1)
//        reqBuffer[1] = 0x08;//left
//        
//        if (controlBits & 2)
//            reqBuffer[1] = 0x04;//right
//            
//            if (controlBits & 4)
//                reqBuffer[1] = 0x02;//up
//                
//                if (controlBits & 8)
//                    reqBuffer[1] = 0x01;//down
//                    
//                    if (controlBits & 16)
//                        reqBuffer[1] = 0x10;//fire
//                        
//                        devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//                        devRequest.bRequest = kUSBRqSetConfig;
//                        devRequest.wValue = kUSBConfDesc;
//                        devRequest.wIndex = 0;
//                        devRequest.wLength = 5;
//                        devRequest.pData = reqBuffer;
//                        kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//                        if (kr != kIOReturnSuccess)
//                        {
//                            if (kr == kIOReturnNoDevice)
//                            {
//                                if (debugCommands)
//                                    NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//                            } else
//                                if (kr == kIOReturnNotOpen)
//                                {
//                                    if (debugCommands) 
//                                        NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//                                } else
//                                {
//                                    EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//                                }
//                        }
//    
//    // ===========================================================================
//    // END OF Control of USB Missile Launcher
//    // ===========================================================================
//    
//}
