#!/bin/bash

# Define script variables
system_serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
loggedInUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
user_id=`id -u`
user_name=`id -un $user_id`
hn=`hostname`

# open SplashBuddy app
su $loggedInUser -c 'open -a /Library/Application Support/SplashBuddy/SplashBuddy.app'

# Setting ComputerName
echo "==================================================================================" >> /var/log/jamf.log
echo "Setting computer name to serial number..." >> /var/log/jamf.log
jamf setComputerName -name $system_serial
sleep 2
echo "Computer renamed to $hn" >> /var/log/jamf.log
echo "==================================================================================" >> /var/log/jamf.log

# Check to confirm current user is not the setup user, then start basic user + admin OS settings
echo "==================================================================================" >> /var/log/jamf.log
echo "Running JSS script DEP-Basic-Settings to trigger sub-policies..." >> /var/log/jamf.log
jamf policy -event SystemSettings
echo "==================================================================================" >> /var/log/jamf.log

# Finder FUT policies
jamf policy -event FinderDEP

# Installing Apple Enterprise Connect
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Apple Enterprise Connect..." >> /var/log/jamf.log
jamf policy -event EnterpriseConnect
ECV=`defaults read /Applications/Enterprise\ Connect.app/Contents/version CFBundleShortVersionString`
	if [ -f "/Applications/Enterprise\ Connect.app/Contents/version.plist" ]; then
		echo "Enterprise Connect $ECV installed successfully..." >> /var/log/jamf.log
			else echo "Enterprise Connect not installed..." >> /var/log/jamf.log
		fi
echo "==================================================================================" >> /var/log/jamf.log

# Installing Google Chrome, enabling auto-updates
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing the current version of Google Chrome..." >> /var/log/jamf.log
jamf policy -event ChromeCurrent
ChromeVersion=`defaults read /Applications/Google\ Chrome.app/Contents/info CFBundleShortVersionString`
	if [ -f "/Applications/Google\ Chrome.app/Contents/info.plist" ]; then
		echo "Google Chrome $ChromeVersion installed successfully..." >> /var/log/jamf.log
			else echo "Google Chrome not installed..." >> /var/log/jamf.log
		fi
echo "==================================================================================" >> /var/log/jamf.log

# Installing Flash and Java
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Java and Flash..." >> /var/log/jamf.log
jamf policy -event BrowserPlugins
FlashVersion=`defaults read /Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version CFBundleShortVersionString`
JavaVersion=`defaults read /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/enabled CFBundleShortVersionString`
	if [ -f "/Library/Internet\ Plug-Ins/Flash\ Player.plugin/Contents/version.plist" ]; then
		echo "Flash $FlashVersion installed successfully..." >> /var/log/jamf.log
			else echo "Flash not installed..." >> /var/log/jamf.log
		fi
	if [ -f "/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/enabled.plist" ]; then
			echo "$JavaVersion installed successfully..." >> /var/log/jamf.log
				else echo "Java not installed..." >> /var/log/jamf.log
			fi	
echo "==================================================================================" >> /var/log/jamf.log

# Installing Papercut Client
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Papercut Client..." >> /var/log/jamf.log
jamf policy -event PCClient
PCCVersion=`defaults read /Applications/PCClient.app/Contents/Info CFBundleShortVersionString`
if [ -f "/Applications/PCClient.app/Contents/Info CFBundleShortVersionString.plist" ]; then
	echo "PCClient $PCCVersion installed successfully..." >> /var/log/jamf.log
		else echo "PCClient not installed..." >> /var/log/jamf.log
	fi
echo "==================================================================================" >> /var/log/jamf.log

# Preparing Share Drive
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Shared Drive dependencies..." >> /var/log/jamf.log
jamf policy -event SharedDrive
if [ -f "/Library/Widgets/Zidget.wdgt/Contents/Info.plist" ]; then
	echo "Zidget installed successfully..." >> /var/log/jamf.log
		else echo "Zidget not installed..." >> /var/log/jamf.log
fi
echo "==================================================================================" >> /var/log/jamf.log

# Installing BlueJeans
echo "==================================================================================" >> /var/log/jamf.log
jamf policy -event BlueJeans
BJVersion=`defaults read /Applications/Blue\ Jeans.app/Contents/Info CFBundleShortVersionString`
if [ -f "/Applications/Blue\ Jeans.app/Contents/Info CFBundleShortVersionString.plist" ]; then
	echo "Blue Jeans installed successfully..." >> /var/log/jamf.log
		else echo "Blue Jeans not installed..." >> /var/log/jamf.log
fi
echo "==================================================================================" >> /var/log/jamf.log

# Creating 'Last Imaged' and 'Image Config' tokens
echo "==================================================================================" >> /var/log/jamf.log
echo "Creating Staff High Sierra token..." >> /var/log/jamf.log
jamf policy -event configstaffhighsierra
jamf recon
echo "==================================================================================" >> /var/log/jamf.log

# Verifying app installs


# Opening SA Okta in Safari, then set Chrome as default browser
open -a "Safari" https://successacademies.okta.com
sleep 1
jamf policy ChromeDefault

# Quit SplashBuddy if still running
if [[ $(pgrep SplashBuddy) ]]; then
	pkill SplashBuddy
fi

# we are done, so delete SplashBuddy + new user setup script
rm -rf '/Library/Application Support/SplashBuddy'
rm /Library/Preferences/io.fti.SplashBuddy.plist
rm /Library/LaunchAgents/io.fti.SplashBuddy.launch.plist
rm /usr/local/bin/jss/setup-new-user.sh

exit 0