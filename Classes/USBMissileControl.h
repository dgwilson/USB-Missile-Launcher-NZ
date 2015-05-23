//
//  MissileControl.h
//  USB Missile Launcher NZ
//
//  Created by David G. Wilson on 11/06/06.
//  Copyright 2006 David G. Wilson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "USBLauncher.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/IOMessage.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/hid/IOHIDLib.h>

#include <unistd.h>

//================================================================================================
//   Globals
//================================================================================================
//

@interface USBMissileControl : NSObject {
	
	Boolean				missileLauncherConnected;
	NSTimer			  * timer;
	
	
	enum launcherID {
		launcherStop = 0,
		launcherLeftUp = 1,
		launcherUp = 2,
		launcherRightUp = 3,
		launcherLeft = 4,
		launcherFire = 5,
		launcherRight = 6,
		launcherLeftDown = 7,
		launcherDown = 8,
		launcherRightDown = 9,
		launcherTest = 10,
		launcherPark = 11,
		launcherLaserToggle = 12,
		launcherPrime = 13
	} launcherID ;
	
}

- (id)init; 
void DeviceAdded(void *refCon, io_iterator_t iterator);
IOReturn FindInterfaces(IOUSBDeviceInterface **device);
void DeviceNotification( void *refCon,
						 io_service_t service,
						 natural_t messageType,
						 void *messageArgument );

//void WriteCompletion(void *refCon, IOReturn result, void *arg0);
//void ReadCompletion(void *refCon, IOReturn result, void *arg0);

- (BOOL)confirmMissileLauncherConnected;
- (id)MissileControl:(UInt8)controlBits;
//IOReturn DreamCheekyReadPipe(int dataRefIndex, UInt8 *rBuffer);
IOReturn DreamCheekyReadPipe(IOUSBDeviceInterface **missileDevice, IOUSBInterfaceInterface **missileInterface, UInt8 *rBuffer);
//IOReturn RocketBabyReadPipe(int dataRefIndex, UInt8 *rBuffer);
IOReturn RocketBabyReadPipe(IOUSBDeviceInterface **missileDevice, IOUSBInterfaceInterface **missileInterface, UInt8 *rBuffer);
IOReturn OICStormReadPipe(IOUSBDeviceInterface **missileDevice, IOUSBInterfaceInterface **missileInterface, UInt8 *rBuffer);

IOReturn DreamCheekyWritePipe(int dataRefIndex, char *wBuffer);
	void WriteCompletion(void *refCon, IOReturn result, void *arg0);
	void ReadCompletion(void *refCon, IOReturn result, void *arg0);

//	IOReturn DreamCheekyReadPipe(IOUSBInterfaceInterface **missileInterface_param, char rBuffer[8]);
void EvaluateUSBErrorCode(IOUSBDeviceInterface **deviceInterface_param, IOUSBInterfaceInterface **missileInterface_param, IOReturn kr);
	void ClearStalledPipe(IOUSBInterfaceInterface **missileInterface_param);

- (void)DreamCheeky_Park;
- (void)MissileLauncher_Park;
- (void)finishCommand:(id)sender;

- (void)DGWScheduleCancelLauncherCommand:(NSTimeInterval)duration;
- (void)DGWAbortLaunch:(NSTimer *)timer;

- (id)ReleaseMissileLauncher;
- (id)controlLauncher:(NSNumber*)code;


void printInterpretedError(char *s, IOReturn err);

@end
