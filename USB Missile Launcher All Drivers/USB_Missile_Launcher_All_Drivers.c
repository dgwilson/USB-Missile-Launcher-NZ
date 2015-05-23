//
//  USB_Missile_Launcher_All_Drivers.c
//  USB Missile Launcher All Drivers
//
//  Created by David Wilson on 12/01/12.
//  Copyright (c) 2012 David G. Wilson. All rights reserved.
//

#include <mach/mach_types.h>

kern_return_t USB_Missile_Launcher_All_Drivers_start(kmod_info_t * ki, void *d);
kern_return_t USB_Missile_Launcher_All_Drivers_stop(kmod_info_t *ki, void *d);

kern_return_t USB_Missile_Launcher_All_Drivers_start(kmod_info_t * ki, void *d)
{
    return KERN_SUCCESS;
}

kern_return_t USB_Missile_Launcher_All_Drivers_stop(kmod_info_t *ki, void *d)
{
    return KERN_SUCCESS;
}
