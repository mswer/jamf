#!/bin/bash

#mw 11/30/21
#script to upgrade macOS High Sierra users to macOS Catalina

#variables
StartupVolume=`system_profiler SPSoftwareDataType | grep "Boot Volume" | cut -d : -f 2 | xargs`
AvailSpace=`df -Hl "/Volumes/$StartupVolume/" | tail -n 1 | awk '{print $4}' | sed 's/[A-Za-z]*//g' | cut -d . -f 1 | xargs`
JHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
AlertIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns"
NoteIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
PowerSource=`pmset -g ps | grep drawing | cut -d\' -f 2`
CatalinaInstaller="/Users/Shared/Install macOS Catalina.app"
MojaveInstaller="/Applications/Install macOS Mojave.app"
BigSurInstaller="/Applications/Install macOS Big Sur.app"
MontereyInstaller="/Applications/Install macOS Monterey.app"
[[ -d "$CatalinaInstaller" ]] && MinSpace="13" || MinSpace="21"
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
InPlaceToken=`ls /Library/Application\ Support/JAMF/Receipts/ | grep inplace`
[[ -n "$InPlaceToken" ]] && ExistingToken="/Library/Application Support/JAMF/Receipts/$InPlaceToken"
NewToken="/Library/Application Support/JAMF/Receipts/inplace_upgrade-staff10_15.cfg"
CatalinaIcon="/Users/Shared/Install macOS Catalina.app/Contents/Resources/ProductPageIcon_256x256.tiff"

#functions
DeleteInstallers(){
	[[ -d "$MojaveInstaller" ]] && rm -rf "$MojaveInstaller"
	[[ -d "$BigSurInstaller" ]] && rm -rf "$BigSurInstaller"
	[[ -d "$MontereyInstaller" ]] && rm -rf "$MontereyInstaller"
}

DisableJamfConnect(){
	echo "Disabling Jamf Connect Login..."
	[[ -n "$(/usr/local/bin/authchanger -print | grep Okta)" ]] && /usr/local/bin/authchanger -reset
}

OpenDIX(){
	sudo su "$loggedInUser" -c osascript <<EOD
	tell application "Disk Inventory X"
		activate
	end tell
EOD
}

SpaceCheck(){
	if [[ "$AvailSpace" -ge "$MinSpace" ]] ; then
		echo "Sufficient HD space available to proceed ("$AvailSpace"gb)..."
		HDSpace="Yes"
	else
		echo "Insufficient HD space available to proceed ("$AvailSpace"gb)..."
		HDSpace="No"
		SpaceResponse=$("$JHelper" -windowType utility -title "Management alert" -heading "Insufficient Disk Space" -icon "$AlertIcon" -iconSize 150 -lockHUD -description "macOS Catalina requires "$MinSpace"gb of free space. You currently have "$AvailSpace"gb free. 

Would you like to install Disk Inventory X to help identify large files/folders that can be deleted? If you need further assistance, please submit a Help Desk ticket." -alignDescription left -alignHeading left -button1 "Install" -button2 "Not now" -defaultButton 1)
	fi
	if [[ "$HDSpace" == "No" ]] ; then
		if [[ "$SpaceResponse" -eq 0 ]] ; then
			echo "Setting up user with Disk Inventory X..."
			if [[ -d "/Applications/Disk Inventory X.app" ]] ; then
				OpenDIX
			else
				jamf policy -event DiskInventoryX && OpenDIX
			fi
		elif [[ "$SpaceResponse" -eq 2 ]] ; then
			echo "User declined Disk Inventory X..."
		fi
		exit 0
	fi
}

PowerCheck(){
	if [[ "$PowerSource" == "AC Power" ]] ; then
		echo "Device is plugged into power..."
		PowerResponse=$("$JHelper" -windowType utility -title "Management alert" -heading "AC Power detected" -icon "$NoteIcon" -iconSize 100 -lockHUD -description "macOS upgrades should be completed while your computer is plugged in. If your computer loses power while upgrading, it may result in data loss.

For the best results, the technolgy team recommends keeping your Mac connected to power until the upgrade is complete." -alignDescription left -alignHeading left -button1 "Ok" -defaultButton 1)
		[[ "$PowerResponse" -eq 0 ]] && echo "$loggedInUser acknowledged power warning..."
	else
		echo "Device is not plugged in..."
#		[[ -z "$Attempt" ]] && Attempt=1
		PowerResponse=$("$JHelper" -windowType utility -title "Management alert" -heading "Connect to AC Power" -icon "$AlertIcon" -iconSize 150 -lockHUD -description "To start your macOS upgrade, please connect your Mac to power.
	
For the best results, the technolgy team recommends keeping your Mac connected to power until the upgrade is complete.

Please plug in your computer and try again." -alignDescription left -alignHeading left -button1 "Ok" -defaultButton 1)
	exit 0
#If you want to upgrade now, connect your computer to power and then click Retry." -alignDescription left -alignHeading left -button1 "Retry" -button2 "Not now" -defaultButton 1)
#	if [[ "$Attempt" -eq 1 ]] ; then
#		if [[ $PowerResponse -eq 0 ]] ; then
#			echo "Pausing while user connects to power..."
#			((Attempt++))
#			PowerSource="0"
#			PowerSource=`pmset -g ps | grep drawing | cut -d\' -f 2`
#			sleep 5
#			PowerCheck
#		elif [[ $PowerResponse -eq 2 ]] ; then
#			echo "$loggedInUser declined to retry..."
#			exit 0
#		fi
#	elif [[ "$Attempt" -eq 2 ]] ; then
#		PowerExit=$("$JHelper" -windowType hud -title "Error" -heading "No AC Power" -icon "$AlertIcon" -iconSize 100 -lockHUD -description "Your computer still does not register AC Power. Please try again later when you can connect to power." -alignDescription left -alignHeading left -button1 "OK")
#		[[ "$PowerExit" -eq 0 ]] && exit 0
#		fi
	fi
}

InstallerCheck(){
	if [[ -d "$CatalinaInstaller" ]] ; then
		echo "macOS Catalina 10.15.7 installer found..."
	else
		echo "macOS Catalina installer missing. Attempting to re-download..."
		jamf policy -event DownloadCatalina
	fi
}

TokenCheck(){
	echo "Checking for in-place upgrade token..."
	if [[ -f "/Library/Application Support/JAMF/Receipts/$InPlaceToken" ]] ; then
		echo "Token found. Updating '$InPlaceToken'..."
		echo "The macOS 10.15.7 upgrade was initiated on $(date +'%m/%d/%Y %r')" >> "$ExistingToken"
	else
		echo "No token found. Creating in-place upgrade token..."
		echo "The macOS 10.15.7 upgrade was initiated on $(date +'%m/%d/%Y %r')" > "$NewToken"
	fi
	jamf recon > /dev/null
}

#main process
DeleteInstallers
SpaceCheck
PowerCheck
InstallerCheck
if [[ -d "$CatalinaInstaller" ]] ; then
	DisableJamfConnect
	TokenCheck
	UpgradeNotice=$("$JHelper" -windowType utility -title "Management alert" -heading "macOS Catalina " -icon "$CatalinaIcon" -iconSize 100 -lockHUD -description "Your macOS upgrade is starting now. Please be patient — your computer will automatically restart in about 10 minutes, when the upgrade is ready to install." -alignDescription left -alignHeading left -button1 "Ok" -defaultButton 1 -countdown -timeout 10 -alignCountdown justified)
	echo "Starting upgrade to macOS Catalina..."
	"$CatalinaInstaller"/Contents/Resources/startosinstall --agreetolicense && kill $(ps aux | grep "Self Service" | grep app | awk {'print $2'})
else
	echo "Somehow the Catalina installer is still missing. Exiting..."
	exit 1
fi