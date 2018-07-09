#!/bin/bash

# Define script variables
system_serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
loggedInUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
user_id=`id -u`
user_name=`id -un $user_id`

# open SplashBuddy app
su $loggedInUser -c 'open -a /Library/Application Support/SplashBuddy/SplashBuddy.app'

# Setting ComputerName
jamf setComputerName -name $system_serial

# Check to confirm current user is not the setup user, then start basic user + admin OS settings
jamf policy -event SystemSettings

# Finder FUT policies
jamf policy -event FinderDEP

# Installing Apple Enterprise Connect
jamf policy -event EnterpriseConnect

# Installing Google Chrome, enabling auto-updates
jamf policy -event ChromeCurrent

# Installing Flash and Java
jamf policy -event BrowserPlugins

# Installing Papercut Client
jamf policy -event PCClient

# Preparing Share Drive
jamf policy -event SharedDrive

# Installing BlueJeans
jamf policy -event BlueJeans

# Creating 'Last Imaged' and 'Image Config' tokens
jamf policy -event configstaffhighsierra

# Preparing for Reboot

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