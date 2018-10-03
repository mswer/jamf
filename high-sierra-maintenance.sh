#!/bin/bash

# Defining variables
SW="/Applications/SonicWALL Mobile Connect.app"
SWVersion=`defaults read /Applications/SonicWALL\ Mobile\ Connect.app/Contents/Info CFBundleShortVersionString`

# Deleting macOS installer & old image tokens
echo "================================================================" >> /var/log/jamf.log
echo "Removing macOS High Sierra installer and old image tokens..." >> /var/log/jamf.log
rm -rf /Users/Shared/Install\ macOS\ High\ Sierra.app
rm /Library/Application\ Support/JAMF/Receipts/config_network.cfg
rm /Library/Application\ Support/JAMF/Receipts/config_schools.cfg
rm /Library/Application\ Support/JAMF/Receipts/config_network_sierra.cfg
rm /Library/Application\ Support/JAMF/Receipts/config_schools_sierra.cfg

# If SonicWall version is 4.0.3, delete and update
if [ "$SWVersion" = "4.0.3" ] ; then
	echo "================================================================" >> /var/log/jamf.log
	echo "SonicWall 4.0.3 doesn't work on macOS 10.13. Upgrading..." >> /var/log/jamf.log
	rm -rf $SonicWall
	jamf policy -event SonicWall
	exit 0
		else
			if [ ! -d "$SW" ] ; then
				echo "================================================================" >> /var/log/jamf.log
				echo "SonicWall does not appear to be installed. Installing..." >> /var/log/jamf.log
				jamf policy -event SonicWall
			else
				echo "================================================================" >> /var/log/jamf.log
				echo "A compatible version of SonicWall is already installed. " >> /var/log/jamf.log
			fi
		fi
exit 0