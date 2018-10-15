#!/bin/bash

# Created 10/2/18 by mw to remove computers from depreciated corporate wireless network
# Updated 10/11/18 to be using during DEP device provisioning so that computers can be bound to AD

# *** How to use ***
# When installing script in JSS, set the following variable field names:
# $4 = Undesired Network SSID; $5 = Desired Network SSID; $6 = Desired Network Password
# Note that this script requires you to enter your network password in plaintext in the policy

# Figure out which network interface is wifi; assumes the only network interfaces are en0 and en1
# This script should work with any Mac with 2 or fewer network interfaces (portables, Macminis, etc.)
# Note this check may fail if the device is connected to an SSID with "Error" in the name
int_check=`networksetup -getairportnetwork en0 | grep Error`
if [ "$int_check" == "" ] ; then
	wifi_int="en0"
	else
	wifi_int="en1"
fi

# Switch connection to desired network (set network name below)
# Remove undesired network from preferred networks so device does not re-connect
CurrentNetwork=`networksetup -getairportnetwork en0 | cut -c 24-`
UndesiredNetwork="$4"
DesiredNetwork="$5"
NetworkPassword=$6"
if [ "$CurrentNetwork" != "$DesiredNetwork" ] ; then
		echo "Switching connection to $DesiredNetwork, removing $UndesiredNetwork..." >> /var/log/jamf.log
		networksetup -setairportnetwork "$wifi_int" "$DesiredNetwork" "$NetworkPassword"
		# Pausing for 10 seconds to give the device time to connect
		sleep 10
		networksetup -removepreferredwirelessnetwork "$wifi_int" "$UndesiredNetwork"
        echo "Now connected to $DesiredNetwork."  >> /var/log/jamf.log
		echo "$UndesiredNetwork disconnected and removed from preferred networks. Exiting..." >> /var/log/jamf.log
	else
		echo "Already connected to $DesiredNetwork. Exiting..." >> /var/log/jamf.log
fi

exit 0