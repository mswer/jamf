#!/bin/bash

#mw 11-17-21
#script to check for available macOS security updates to prompt user to install them

#variables
JHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
OS_Major=$(sw_vers -productVersion | cut -d . -f 1)
OS_Minor=$(sw_vers -productVersion | cut -d . -f 2)
AlertIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Actions.icns"
EscalateIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"
ConfirmationIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns"
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
ComplianceLog="/Library/Application Support/JAMF/Receipts/OSUpdate.log"
UpToDateToken="/Library/Application Support/JAMF/Receipts/UpToDate.token"

#functions
TokenCheck(){
	if [[ -f "$ComplianceLog" ]] ; then
		if [[ $(tail -n 1 "$ComplianceLog") == "Clear" ]] ; then
			if [[ -f "$UpToDateToken" ]] ; then
				WaitTime=`cat "$UpToDateToken"`
				if [[ "$WaitTime" -ge 1 ]] ; then
					((WaitTime--))
					echo "$WaitTime" > "$UpToDateToken"
					echo "Device was up-to-date $(( 7-$WaitTime )) days ago. Will check for updates again in "$WaitTime" days. Exiting..."
					exit 0
				elif [[ "$WaitTime" -eq 0 ]] ; then
					rm -f "$UpToDateToken"
					echo "Checking for available macOS security updates..."
				fi
			else
				touch "$UpToDateToken"
				WaitTime=7
				echo "$WaitTime" > "$UpToDateToken"
				echo "Device is up-to-date. Will check for updates again in "$WaitTime" days. Exiting..."
				exit 0
			fi
		else
			echo "Checking for available macOS security updates..."
		fi
	else
		echo "Checking for available macOS security updates..."
	fi
}

CheckForUpdates(){
	if [[ "$OS_Major" == "10" ]] ; then
		if [[ "$OS_Minor" == "13" ]] ; then
			SecurityUpdate=`softwareupdate -l | grep restart | grep "Security Update" | cut -d , -f 1 | xargs`
		else
			SecurityUpdate=`softwareupdate -l | grep "Label" | grep "Security Update" | cut -d : -f 2 | xargs`
		fi
	elif [[ "$OS_Major" == "11" ]] ; then
		SecurityUpdate=`softwareupdate -l | grep "Label" | grep "macOS Big Sur" | cut -d : -f 2 | xargs`
	elif [[ "$OS_Major" == "12" ]] ; then
		SecurityUpdate=`softwareupdate -l | grep "Label" | grep "macOS Monterey" | cut -d : -f 2 | xargs`
	fi
	CurrentUpdateLog="/var/log/"$SecurityUpdate"-Counter.log"
}

CheckLog(){
	if [[ -f "$CurrentUpdateLog" ]] ; then
		if [[ $(tail -n 1 "$CurrentUpdateLog") -ge 10 ]] ; then
			Reminder="Escalate"
		else
			Reminder="Nag"
		fi
		Attempt=$(tail -n 1 "$CurrentUpdateLog")
		((Attempt++))
		echo "$Attempt" >> "$CurrentUpdateLog"
	elif [[ ! -f "$CurrentUpdateLog" ]] ; then
		Reminder="FirstAlert"
		touch "$CurrentUpdateLog"
		Attempt=1
		echo "$Attempt" > "$CurrentUpdateLog"
	fi
}

UpdateFound1013(){
	if [[ "$Reminder" == "FirstAlert" ]] ; then
	AlertResponse=$("$JHelper" -windowType utility -title "Security Alert" -heading "macOS Security Update Available" -icon "$AlertIcon" -iconSize 150 -lockHUD -description "A new security update is available for your computer. It's important to install security updates promptly to keep your device and data secure.

To install $SecurityUpdate, open the App Store from the Apple () menu, go to the Updates tab, install $SecurityUpdate, and restart when prompted.

Would you like to open the App Store now?" -alignDescription left -alignHeading left -button1 "Open Now" -button2 "Not now" -defaultButton 1)
	elif [[ "$Reminder" == "Nag" ]] ; then
	AlertResponse=$("$JHelper" -windowType utility -title "Security Alert" -heading "macOS Security Update Available" -icon "$AlertIcon" -iconSize 150 -lockHUD -description "Reminder "$Attempt": A security update is available for your computer. It's important to install security updates promptly to keep your device and data secure.

To install $SecurityUpdate, open the App Store from the Apple () menu, go to the Updates tab, install $SecurityUpdate, and restart when prompted.

Would you like to open the App Store now?" -alignDescription left -alignHeading left -button1 "Open Now" -button2 "Not now" -defaultButton 1)
	elif [[ "$Reminder" == "Escalate" ]] ; then
	AlertResponse=$("$JHelper" -windowType utility -title "Security Alert" -heading "macOS Security Update Available" -icon "$EscalateIcon" -iconSize 150 -lockHUD -description "Reminder "$Attempt": A macOS Security Update is available for your computer. The security team will automatically be notified about computers that are not updated within 14 days.

To install $SecurityUpdate, open the App Store from the Apple () menu, go to the Updates tab, install $SecurityUpdate, and restart when prompted.

Open the App Store to install the update now." -alignDescription left -alignHeading left -button1 "Open Now" -defaultButton 1)
	fi
}

UpdateFound11(){
		if [[ "$Reminder" == "FirstAlert" ]] ; then
		AlertResponse=$("$JHelper" -windowType utility -title "Security Alert" -heading "macOS Security Update Available" -icon "$AlertIcon" -iconSize 150 -lockHUD -description "A new security update is available for your computer. It's important to update promptly to keep your device and data secure.

To install $SecurityUpdate, open System Preferences from the Apple () menu, click Software Update, More Info under 'Other updates are available,' then Install Now.

Would you like to open System Preferences now?" -alignDescription left -alignHeading left -button1 "Open Now" -button2 "Not now" -defaultButton 1)
		elif [[ "$Reminder" == "Nag" ]] ; then
		AlertResponse=$("$JHelper" -windowType utility -title "Security Alert" -heading "macOS Security Update Available" -icon "$AlertIcon" -iconSize 150 -lockHUD -description "Reminder "$Attempt": A security update is available for your computer. It's important to update promptly to keep your device and data secure.

To install $SecurityUpdate, open System Preferences from the Apple () menu, click Software Update, More Info under 'Other updates are available,' then Install Now.

Would you like to open System Preferences now?" -alignDescription left -alignHeading left -button1 "Open Now" -button2 "Not now" -defaultButton 1)
		elif [[ "$Reminder" == "Escalate" ]] ; then
		AlertResponse=$("$JHelper" -windowType utility -title "Security Alert" -heading "macOS Security Update Available" -icon "$EscalateIcon" -iconSize 150 -lockHUD -description "Reminder "$Attempt": A macOS Security Update is available for your computer. The security team will automatically be notified about computers that are not updated within 14 days.

To install $SecurityUpdate, open System Preferences from the Apple () menu, click Software Update, More Info under 'Other updates are available,' then Install Now.

Open System Preferences to install the update now." -alignDescription left -alignHeading left -button1 "Open Now" -defaultButton 1)
		fi
}

OpenAppStore(){
	sudo su "$loggedInUser" -c osascript <<EOD
		tell application "App Store"
			activate
		end tell
EOD
}

#main process
[[ ! -d "/Library/Application Support/JAMF/Receipts/" ]] && mkdir "/Library/Application Support/JAMF/Receipts/"
TokenCheck
CheckForUpdates
if [[ -n "$SecurityUpdate" ]] ; then
	echo "'$SecurityUpdate' needs to be downloaded and installed..."
	CheckLog
	echo "$Attempt" > "$ComplianceLog"
	if [[ "$OS_Major" -eq 10 ]] && [[ "$OS_Minor" -eq 13 ]] ; then
		UpdateFound1013
	else
		UpdateFound11 
	fi
	if [[ "$AlertResponse" -eq 0 ]] ; then
		if [[ "$OS_Major" -eq 10 ]] && [[ "$OS_Minor" -eq 13 ]] ; then
			OpenAppStore
		else
			open /System/Library/PreferencePanes/SoftwareUpdate.prefPane
		fi
	elif  [[ "$AlertResponse" -eq 2 ]] ; then
		Confirmation=$("$JHelper" -windowType utility -title "Confirmation" -icon "$ConfirmationIcon" -iconSize 150 -lockHUD -description "Your response has been logged. You will be reminded to install $SecurityUpdate again tomorrow." -alignDescription left -alignHeading left -button1 "OK" -defaultButton 1)
	fi
else
	echo "No macOS Security Updates found. Exiting ..."
	echo "Clear" > "$ComplianceLog"
fi