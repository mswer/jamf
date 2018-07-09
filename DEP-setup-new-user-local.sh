#!/bin/bash

# Define script variables
system_serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
loggedInUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
user_id=`id -u`
user_name=`id -un $user_id`

# open SplashBuddy app
su $loggedInUser -c 'open -a /Library/Application Support/SplashBuddy/SplashBuddy.app'

# Setting ComputerName
echo "==================================================================================" >> /var/log/jamf.log
echo "Setting computer name to serial number..." >> /var/log/jamf.log
jamf setComputerName -name $system_serial
echo "==================================================================================" >> /var/log/jamf.log

# Check to confirm current user is not the setup user, then start basic user + admin OS settings
echo "==================================================================================" >> /var/log/jamf.log
echo "Running JSS script DEP-Basic-Settings to trigger sub-policies..." >> /var/log/jamf.log
jamf policy -event SystemSettings
echo "==================================================================================" >> /var/log/jamf.log

# Opening Safari to Okta for password reset
jamf policy -event Okta

# Finder FUT policies
jamf policy -event FinderDEP

# Installing Apple Enterprise Connect
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Apple Enterprise Connect..." >> /var/log/jamf.log
jamf policy -event EnterpriseConnect
echo "==================================================================================" >> /var/log/jamf.log

# Installing Google Chrome, enabling auto-updates, and setting as default browser
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing current version of Google Chrome and setting as the default browser..." >> /var/log/jamf.log
jamf policy -event ChromeCurrent
jamf policy -event ChromeDefault
echo "==================================================================================" >> /var/log/jamf.log

# Installing Flash and Java
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Java and Flash..." >> /var/log/jamf.log
jamf policy -event BrowserPlugins
echo "==================================================================================" >> /var/log/jamf.log

# Installing Papercut Client
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Papercut Client..." >> /var/log/jamf.log
jamf policy -event PCClient
echo "==================================================================================" >> /var/log/jamf.log

# Preparing Share Drive
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Shared Drive dependencies..." >> /var/log/jamf.log
jamf policy -event SharedDrive
echo "==================================================================================" >> /var/log/jamf.log

# Installing BlueJeans
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing BlueJeans Client..." >> /var/log/jamf.log
jamf policy -event BlueJeans
echo "==================================================================================" >> /var/log/jamf.log

# Setting up user Dock
echo "==================================================================================" >> /var/log/jamf.log
echo "Configuring user Dock..." >> /var/log/jamf.log
jamf policy -event DEPDock
echo "==================================================================================" >> /var/log/jamf.log

# Creating 'Last Imaged' and 'Image Config' tokens
echo "==================================================================================" >> /var/log/jamf.log
echo "Creating Staff High Sierra token..." >> /var/log/jamf.log
jamf policy -event DEPconfigstaffhighsierra
echo "==================================================================================" >> /var/log/jamf.log

# Quit SplashBuddy if still running
if [[ $(pgrep SplashBuddy) ]]; then
	pkill SplashBuddy
fi

# we are done, so delete SplashBuddy + new user setup script
rm -rf '/Library/Application Support/SplashBuddy'
rm /Library/Preferences/io.fti.SplashBuddy.plist
rm /Library/LaunchAgents/io.fti.SplashBuddy.launch.plist
rm /usr/local/bin/jss/setup-new-user.sh

# Installing app verifications
sh /usr/local/bin/jss/DEP-install-verification.sh

exit 0