Program:
USB Missile Launcher NZ

Author:
David G. Wilson
dgwilson65@gmail.com
http://dgwilson.wordpress.com

Description:
USB Missile Launcher NZ can be used to control a USB Missile Launcher and the DreamCheeky Rocket Launcher. Perform covert operations from your desk. Fire missiles at passing colleagues. Strap a camera on top of the Launcher and record the video of your covert operations.


Notes:

The following command can be entered in the terminal to disable the camera function. i.e. it will not be one by default at application launch.
defaults write com.david.USBMissileLauncherNZ cameraDisabled -boolean YES


https://developer.apple.com/library/content/qa/qa1940/_index.html
https://stackoverflow.com/questions/39652867/code-sign-error-in-macos-sierra-xcode-8-resource-fork-finder-information-or

Search for com.apple.FinderInfo and clear this attributes for all files. You can do it like this
xattr -c <filename>



=============
KEXT
=============

sudo kextutil "USB Missile Launcher All Drivers.kext"/
Password:
Diagnostics for /Library/Extensions/USB Missile Launcher All Drivers.kext:
Warnings:
Dependency lacks appropriate value for OSBundleRequired and may not be availalble during early boot:
com.apple.iokit.IOSerialFamily - Safe Boot

Code Signing Failure: code signature is invalid
Warnings:
Dependency lacks appropriate value for OSBundleRequired and may not be availalble during early boot:
com.apple.iokit.IOSerialFamily - Safe Boot

Untrusted kexts are not allowed
ERROR: invalid signature for nz.org.mactcp.iokit.usbmissilelaunchernz, will not load


csrutil disable - done while rebooted in recovery mode

sudo kextutil "USB Missile Launcher All Drivers.kext"/
Password:
Diagnostics for /Library/Extensions/USB Missile Launcher All Drivers.kext:
Warnings:
Dependency lacks appropriate value for OSBundleRequired and may not be availalble during early boot:
com.apple.iokit.IOSerialFamily - Safe Boot

Code Signing Failure: code signature is invalid
Warnings:
Dependency lacks appropriate value for OSBundleRequired and may not be availalble during early boot:
com.apple.iokit.IOSerialFamily - Safe Boot

kext-dev-mode allowing invalid signature -67050 0xFFFFFFFFFFFEFA16 for kext "/Library/Extensions/USB Missile Launcher All Drivers.kext"
kext signature failure override allowing invalid signature -67050 0xFFFFFFFFFFFEFA16 for kext "/Library/Extensions/USB Missile Launcher All Drivers.kext"



SHA1 - hash generation

for i in U* ; do ls -l "$i" ; openssl dgst -sha1 "$i" ; echo ; done

-rw-r--r--@ 1 dgwilson  dgwilson  7593338 31 Dec 10:07 USB Missile Launcher NZ v1.8.2 b163.dmg
SHA1(USB Missile Launcher NZ v1.8.2 b163.dmg)= baa9c39f94b36ed2180c7943b1c576a9431d891c
