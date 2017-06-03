//
//  usbHIDDeviceElements.h
//  USB Missile Launcher NZ 2.0.0
//
//  Created by David Wilson on 9/06/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDLib.h>


@interface usbHIDDeviceElements : NSObject 
{
	IOHIDDeviceRef	device;
	NSArray *		elements;
}

@property (nonatomic, assign) IOHIDDeviceRef	device;
@property (nonatomic, retain) NSArray *			elements;

- (id)initWithDevice:(IOHIDDeviceRef)inDevice elements:(NSArray *)inElements;

@end
