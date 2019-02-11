#!/bin/bash

#Script to enable location services on High Sierra Macs
#mw, 11-06-18
#via https://www.jamf.com/jamf-nation/discussions/18887/not-able-to-unlock-mac-from-jss
#and using some elements from the old script from https://www.jamf.com/jamf-nation/discussions/6835/time-zone-using-current-location-scriptable

#Variables
wifi_int=`/usr/sbin/networksetup -listallhardwareports | grep -A1 Wi-Fi | grep Device | awk '{print $2}'`

echo "==================================================================================" >> /var/log/jamf.log
echo "Enabling Location Services..." >> /var/log/jamf.log
sudo -u _locationd /usr/bin/defaults -currentHost write com.apple.locationd LocationServicesEnabled -int 1

#Wi-Fi must be powered on to determine current location
/usr/sbin/networksetup -setairportpower $wifi_int on

#Pause to enable location services to load properly
sleep 3

#Re-enable network time
/usr/sbin/systemsetup -setusingnetworktime on

#Python code snippet to reload AutoTimeZoneDaemon
/usr/bin/python << EOF
from Foundation import NSBundle
TZPP = NSBundle.bundleWithPath_("/System/Library/PreferencePanes/DateAndTime.prefPane/Contents/Resources/TimeZone.prefPane")
TimeZonePref          = TZPP.classNamed_('TimeZonePref')
ATZAdminPrefererences = TZPP.classNamed_('ATZAdminPrefererences')

atzap  = ATZAdminPrefererences.defaultPreferences()
pref   = TimeZonePref.alloc().init()
atzap.addObserver_forKeyPath_options_context_(pref, "enabled", 0, 0)
result = pref._startAutoTimeZoneDaemon_(0x1)
EOF

sleep 5

#Get the time from time server
/usr/sbin/systemsetup -getnetworktimeserver

#Detect the newly set timezone
/usr/sbin/systemsetup -gettimezone

exit 0