#!/bin/bash

# Created 10/2/18 by mw to remove computers from depreciated corporate wireless network

# *** How to use ***
# This script is written with the assumption that the **current wireless network*** is the undesired network
# Create Smart Computer Group for "Current AirPort Network" is and the network name and scope policy to that group
# Set your desired network name using the variable on line 23 below; keep the quotes because the network name is a string
# Set the password for that network in the JSS policy, parameter 4; when adding script to JSS, name parameter appropriately

# Figure out which network interface is wifi; assumes the only network interfaces are en0 and en1
# This script should work with any Mac with 2 or fewer network interfaces (portables, Macminis, etc.)
int_check=`networksetup -getairportnetwork en0 | grep Error`
if [ "$int_check" == "" ] ; then
	wifi_int="en0"
	else
	wifi_int="en1"
fi

# Switch connection to desired network (set network name below)
# Remove undesired network from preferred networks so device does not re-connect
UndesiredNetwork=`networksetup -getairportnetwork "$wifi_int" | cut -c 24-`
DesiredNetwork=""
if [ "$UndesiredNetwork" != "$DesiredNetwork" ] ; then
		echo "Switching connection to $DesiredNetwork, removing $UndesiredNetwork..." >> /var/log/jamf.log
		networksetup -setairportnetwork "$wifi_int" "$DesiredNetwork" $4
		# Pausing for 10 seconds to give the device time to connect
		sleep 10
		networksetup -removepreferredwirelessnetwork "$wifi_int" "$UndesiredNetwork"
        echo "Now connected to $DesiredNetwork." /var/log/jamf.log
		echo "$UndesiredNetwork disconnected and removed from preferred networks. Exiting..." >> /var/log/jamf.log
	else
		echo "Already connected to $UndesiredNetwork. Exiting..." >> /var/log/jamf.log
fi

exit 0