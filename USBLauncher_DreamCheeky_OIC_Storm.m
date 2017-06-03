//
//  USBLauncher_DreamCheeky_OIC_Storm.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 7/05/17.
//  Copyright © 2017 David G. Wilson. All rights reserved.
//

#import "USBLauncher_DreamCheeky_OIC_Storm.h"

@implementation USBLauncher_DreamCheeky_OIC_Storm


#pragma mark - HID CONTROL of launcher - Dream Cheeky OIC Storm

- (void)missileControlWithBits:(UInt8)controlBits
{
//    NSLog(@"%s 0x%08X", __PRETTY_FUNCTION__, controlBits);
    uint8_t report[8] = {0x02, 0, 0, 0, 0, 0, 0, 0};
    
//    IOHIDDeviceRef device = [privateDataRef hidDevice];
    IOHIDDeviceRef device = [self hidDevice];
//    NSLog(@"%02X", controlBits);
    if (controlBits & 0x01) //Left
        report[1] |= 0x04;
    if (controlBits & 0x02) //Right
        report[1] |= 0x08;
    if (controlBits & 0x04) //Up
        report[1] |= 0x02;
    if (controlBits & 0x08) //Down
        report[1] |= 0x01;
    if (controlBits & 0x10) //Fire
        report[1] |= 0x10;
    if (controlBits & 0x40)  // Turn ON THUNDER light - Launcher is coloured military green
    {
        report[0] = 0x03;
        report[1] = 0x01;
    }
    if (controlBits & 0x80)  // Turn OFF THUNDER light - Launcher is coloured military green
    {
        report[0] = 0x03;
        report[1] = 0x00;
    }
    IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0, report, sizeof(report));
}

@end

//if ([[privateDataRef getLauncherType] isEqualToString:@"OICStorm"])
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
//    // Control of USB Rocket Launcher - DreamCheeky OIC Storm
//    // ===========================================================================
//    if (debugCommands)
//    {
//        NSLog(@"USBMissileControl: -------------- new command instruction --------------");
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
//    sbBuffer[0] = 0x00;
//    sbBuffer[1] = 0x00;
//    //			kr = OICStormReadPipe(missileDevice, missileInterface, rbBuffer);
//    //			if (kr != kIOReturnSuccess)
//    //			{
//    //				if (debugCommands)
//    //					NSLog(@"USBMissileControl: ERROR returned from OICStormReadPipe kr=(0x%08x)", kr);
//    //			} else
//    //			{
//    //				if (debugCommands)
//    //					NSLog(@"USBMissileControl: return from OICStormReadPipe (0x%02x)", rbBuffer[0]);
//    //			}
//    
//    //			Left		controlBits |= 1;
//    //			Right		controlBits |= 2;
//    //			Up			controlBits |= 4;
//    //			Down		controlBits |= 8;
//    //			Fire		controlBits |= 16;
//    //			NSLog(@"USBMissileControl: controlBits %d", controlBits);
//    
//    if (sbBuffer[1] & 0x01)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
//    {
//        if (controlBits & 8)
//        {
//            if (debugCommands)
//                NSLog(@"USBMissileControl: cancelling additional down request");
//            controlBits = controlBits ^8;
//        }
//    } else
//        if (sbBuffer[1] & 0x02)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
//        {
//            if (controlBits & 4)
//            {
//                if (debugCommands)
//                    NSLog(@"USBMissileControl: cancelling additional up request");
//                controlBits = controlBits ^4;
//            }
//        }
//    if (sbBuffer[1] & 0x04)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
//    {
//        if (controlBits & 1)
//        {
//            if (debugCommands)
//                NSLog(@"USBMissileControl: cancelling additional left request");
//            controlBits = controlBits ^1;
//        }
//    } else
//        if (sbBuffer[1] & 0x08)  // Bitwise AND -- http://en.wikipedia.org/wiki/Operators_in_C_and_C_Plus_Plus
//        {
//            if (controlBits & 2)
//            {
//                if (debugCommands)
//                    NSLog(@"USBMissileControl: cancelling additional right request");
//                controlBits = controlBits ^2;
//            }
//        }
//    //			if (debugCommands)
//    //				NSLog(@"USBMissileControl: controlBits %d", controlBits);
//    
//    
//    // send the package - contains actual instruction
//    reqBuffer_RB[0] = 0x02;
//    reqBuffer_RB[1] = 0x00;
//    reqBuffer_RB[2] = 0x00;
//    reqBuffer_RB[3] = 0x00;
//    reqBuffer_RB[4] = 0x00;
//    reqBuffer_RB[5] = 0x00;
//    reqBuffer_RB[6] = 0x00;
//    reqBuffer_RB[7] = 0x00;
//    if (controlBits == 0)   // Launcher STOP (so if no command is sent, we instruct STOP)
//    {
//        reqBuffer_RB[1] = 0x20;
//    }
//    
//    // this launcher does not understand "Up & Left" type commands together. The software simulates it and will get the
//    // desired end result, however the launcher cannot drive 2 x servo motors at once using the command set available.
//    if (controlBits & 1)   // left
//    {
//        reqBuffer_RB[1] = 0x04;
//        if (debugCommands)
//            NSLog(@"USBMissileControl: controlBits %d - Left   <----------------", controlBits);
//    }
//    if (controlBits & 2)   // right
//    {
//        reqBuffer_RB[1] = 0x08;
//        if (debugCommands)
//            NSLog(@"USBMissileControl: controlBits %d - Right   <----------------", controlBits);
//    }
//    if (controlBits & 4)   // up
//    {
//        reqBuffer_RB[1] = 0x02;
//        if (debugCommands)
//            NSLog(@"USBMissileControl: controlBits %d - Up   <----------------", controlBits);
//    }
//    if (controlBits & 8)   // down
//    {
//        reqBuffer_RB[1] = 0x01;
//        if (debugCommands)
//            NSLog(@"USBMissileControl: controlBits %d - Down   <----------------", controlBits);
//    }
//    
//    
//    if ((controlBits & 16) || (controlBits & 128)) // Fire
//    {
//        reqBuffer_RB[1] = 0x10;
//        if (debugCommands)
//        {
//            NSLog(@"USBMissileControl: MissileControl: OIC Storm - Fire (or Prime) initiated");
//        }
//    }
//    
//    devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//    devRequest.bRequest = 0x09;
//    devRequest.wValue = 0x0000200;
//    devRequest.wIndex = 0;
//    devRequest.wLength = 8;
//    devRequest.pData = reqBuffer_RB;
//    if (debugCommands)
//    {
//        NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//        NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//        NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//        NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//        NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//        NSLog(@"USBMissileControl: OIC Storm command package (0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x) delivered", reqBuffer_RB[0], reqBuffer_RB[1], reqBuffer_RB[2], reqBuffer_RB[3], reqBuffer_RB[4], reqBuffer_RB[5], reqBuffer_RB[6], reqBuffer_RB[7]);
//        if( debugCommands && reqBuffer_RB[0] == 0x02)
//            NSLog(@"USBMissileControl: controlBits (0x%04x)", controlBits);
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
//                {
//                    EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//                }
//        }
//    }
//    
//    //			if (controlBits & 16)
//    //			{
//    //				// Need to stop the fire sequence - otherwise it continues without stopping
//    //				// if we read (or look for feedback from the launcher) it will tell us when the fire has completed
//    //				//
//    //
//    //				int delayCounter;
//    //				for (delayCounter = 0; delayCounter < 500; delayCounter ++)
//    //				{
//    //					//[NSThread sleepUntilDate:[[NSDate alloc]initWithTimeIntervalSinceNow:0.100]];
//    //					rbBuffer[0] = 0x00;
//    //					rbBuffer[1] = 0x00;
//    //
//    //					kr = OICStormReadPipe(missileDevice, missileInterface, rbBuffer);
//    //					if (kr != kIOReturnSuccess)
//    //						break;
//    //
//    //					if (kr == kIOReturnSuccess && rbBuffer[1] & 0x10)
//    //					{
//    //						// The 0x10 status doesn't always mean that firing has occurred, but it will be very close
//    //						// - wait at least 500ms before sending 0x20 after receiving 0x10
//    //						[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.500]];
//    //
//    //						// Fire command completed
//    //						// send the third package - 0x20
//    //						reqBuffer_RB[0] = 0x02;
//    //						reqBuffer_RB[1] = 0x20;
//    //						reqBuffer_RB[2] = 0x00;
//    //						reqBuffer_RB[3] = 0x00;
//    //						reqBuffer_RB[4] = 0x00;
//    //						reqBuffer_RB[5] = 0x00;
//    //						reqBuffer_RB[6] = 0x00;
//    //						reqBuffer_RB[7] = 0x00;
//    //						devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//    //						devRequest.bRequest = 0x09;
//    //						devRequest.wValue = 0x0000200;
//    //						devRequest.wIndex = 0;
//    //						devRequest.wLength = 8;
//    //						devRequest.pData = reqBuffer_RB;
//    //						if (debugCommands)
//    //						{
//    //							//NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//    //							//NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//    //							//NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//    //							//NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//    //							//NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//    //							NSLog(@"USBMissileControl: OIC Storm command package (0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x) delivered", reqBuffer_RB[0], reqBuffer_RB[1], reqBuffer_RB[2], reqBuffer_RB[3], reqBuffer_RB[4], reqBuffer_RB[5], reqBuffer_RB[6], reqBuffer_RB[7]);
//    //						}
//    //						kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//    //
//    //						if (kr != kIOReturnSuccess)
//    //						{
//    //							if (kr == kIOReturnNoDevice)
//    //							{
//    //								if (debugCommands)
//    //									NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//    //							} else
//    //							if (kr == kIOReturnNotOpen)
//    //							{
//    //								if (debugCommands)
//    //									NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//    //							} else
//    //							{
//    //								EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//    //							}
//    //						}
//    //
//    //						break;
//    //					}
//    //
//    //				}
//    //
//    //			}
//    
//    //			if (controlBits & 128) // Prime Launcher
//    //			{
//    //				// Need to stop the fire sequence - otherwise it continues without stopping
//    //				// if we read (or look for feedback from the launcher) it will tell us when the fire has completed
//    //				//
//    //				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
//    //
//    //				// Fire command completed
//    //				// send the third package - 0x20
//    //				reqBuffer_RB[0] = 0x02;
//    //				reqBuffer_RB[1] = 0x20;
//    //				reqBuffer_RB[2] = 0x00;
//    //				reqBuffer_RB[3] = 0x00;
//    //				reqBuffer_RB[4] = 0x00;
//    //				reqBuffer_RB[5] = 0x00;
//    //				reqBuffer_RB[6] = 0x00;
//    //				reqBuffer_RB[7] = 0x00;
//    //				devRequest.bmRequestType = USBmakebmRequestType(kUSBOut, kUSBClass, kUSBInterface);
//    //				devRequest.bRequest = 0x09;
//    //				devRequest.wValue = 0x0000200;
//    //				devRequest.wIndex = 0;
//    //				devRequest.wLength = 8;
//    //				devRequest.pData = reqBuffer_RB;
//    //				if (debugCommands)
//    //				{
//    //					//	NSLog(@"  devRequest.bmRequestType %x", devRequest.bmRequestType);
//    //					//	NSLog(@"  devRequest.bRequest      %x", devRequest.bRequest);
//    //					//	NSLog(@"  devRequest.wValue        %x", devRequest.wValue);
//    //					//	NSLog(@"  devRequest.wIndex        %x", devRequest.wIndex);
//    //					//	NSLog(@"  devRequest.wLength       %x", devRequest.wLength);
//    //					NSLog(@"USBMissileControl: OIC Storm command package (0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x) delivered", reqBuffer_RB[0], reqBuffer_RB[1], reqBuffer_RB[2], reqBuffer_RB[3], reqBuffer_RB[4], reqBuffer_RB[5], reqBuffer_RB[6], reqBuffer_RB[7]);
//    //				}
//    //				kr = (*missileDevice)->DeviceRequest(missileDevice, &devRequest);
//    //				if (debugCommands)
//    //				{
//    //					if (kr != kIOReturnSuccess)
//    //					{
//    //						if (kr == kIOReturnNoDevice)
//    //						{
//    //							if (debugCommands) 
//    //								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNoDevice", [privateDataRef getLauncherType]);
//    //						} else
//    //						if (kr == kIOReturnNotOpen)
//    //						{
//    //							if (debugCommands) 
//    //								NSLog(@"USBMissileControl: %@ IOReturn: kIOReturnNotOpen", [privateDataRef getLauncherType]);
//    //						} else
//    //						{
//    //							EvaluateUSBErrorCode(missileDevice, missileInterface, kr);
//    //						}
//    //					}	
//    //				}
//    //				
//    //			}
//    // ===========================================================================
//    // END OF USB Rocket Launcher - DreamCheeky OIC Storm
//    // ===========================================================================
//}
