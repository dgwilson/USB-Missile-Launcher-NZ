//
//  usbHIDDeviceElements.m
//  USB Missile Launcher NZ 2.0.0
//
//  Created by David Wilson on 9/06/11.
//  Copyright 2011 David G. Wilson. All rights reserved.
//

#import "usbHIDDeviceElements.h"


@implementation usbHIDDeviceElements

@synthesize device;
@synthesize elements;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)initWithDevice:(IOHIDDeviceRef)inDevice elements:(NSArray *)inElements
{
    self = [self init];
    if (self) {
        // Initialization code here.
		self.device = inDevice;
		self.elements = inElements;
    }
    
    return self;	
}

@end
