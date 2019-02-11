#!/bin/bash

# mw 02-11-19
# for MacOS 10.10 and below, the device UUID must be included in plist name when running defaults read to get the boolean
# for MacOS 10.11+, the device UUID *cannot* be included in the please name when running defaults read to get the boolean

#Variables
uuid=$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}')
domain="/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd"
file="${domain}.${uuid}.plist"
os_version=`sw_vers -productVersion | cut -d . -f 2`

#Functions
below_mavericks () {
	status=$(defaults read "${file}" LocationServicesEnabled)
	if [[ "${status}" == "1" ]] ; then
	result="Enabled"
	else
	result="Disabled"
	fi
}
above_mavericks () {
	status=$(defaults read "${domain}" LocationServicesEnabled)
	if [[ "${status}" == "1" ]] ; then
	result="Enabled"
	else
	result="Disabled"
	fi
}

#Check location services based on OS version
if [[ -f "$file" ]] ; then
	if [ "$os_version" -lt "11" ] ; then
		below_mavericks
		elif [ "$os_version" -gt "11" ] ; then
		above_mavericks
	fi
	else
	result="Unavailable"
fi

echo "<result>${result}</result>"