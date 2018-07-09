#!/bin/bash

# Define script variables
system_serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
loggedInUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
user_id=`id -u`
user_name=`id -un $user_id`
logfile=/var/log/jamf/.log
exec > $logfile 2>&1

# open SplashBuddy app
su $loggedInUser -c 'open -a /Library/Application Support/SplashBuddy/SplashBuddy.app'

# Setting ComputerName
echo "=================================================================================="
echo "Setting computer name to serial number..."
jamf setComputerName -name $system_serial
echo "=================================================================================="

echo "=================================================================================="
echo "Creating sucadmin..."
jamf policy -event DEPMakeSucadmin
echo "=================================================================================="

# Start basic device setup
# This policy runs the following triggers for the following effects:
# wallpaper (sets SA wallpaper), EULA (installs loginwindow EULA), UptimeReminder (installs
# uptime reminder components), EnableRemoteMGMTDEP (enables ARD/SSH for sucadmin, PI_setfirmware
# (sets firmware password), EnableLocation (enables location services), SetTimeServer
# (sets 3 NTP time servers), sucadminprofile (sets sucadmin profile picture)
echo "=================================================================================="
echo "Running SA device customization policies..."
jamf policy -event SystemSettings
echo "=================================================================================="

# Opening Safari to Okta for password reset
jamf policy -event Okta

# Finder FUT policies
echo "=================================================================================="
echo "Installing Finder FUT policies - will not be shown until restart..."
jamf policy -event FinderDEP
echo "=================================================================================="

# Installing Apple Enterprise Connect
echo "=================================================================================="
echo "Installing Apple Enterprise Connect..."
jamf policy -event EnterpriseConnect
echo "=================================================================================="

# Installing Apple Enterprise Connect
echo "=================================================================================="
echo "Checking if SonicWall installed from the App Store..."
if [ ! -d /Applications/SonicWall\ Mobile\ Connect.app ];
	then jamf policy -event SonicWall && echo "App Store failed/. Installing from JSS..."
	else echo "SonicWall installed from App Store. Skipping JSS policy..."
	fi
echo "=================================================================================="

# Installing Google Chrome, enabling auto-updates, and setting as default browser
echo "=================================================================================="
echo "Installing current version of Google Chrome and setting as the default browser..."
jamf policy -event ChromeCurrent
jamf policy -event ChromeDefault
echo "=================================================================================="

# Installing Flash and Java
echo "=================================================================================="
echo "Installing Java and Flash..."
jamf policy -event BrowserPlugins
echo "=================================================================================="

# Installing Papercut Client
echo "=================================================================================="
echo "Installing Papercut Client..."
jamf policy -event PCClient
echo "=================================================================================="

# Preparing Share Drive
echo "=================================================================================="
echo "Installing Shared Drive dependencies..."
jamf policy -event SharedDrive
echo "=================================================================================="

# Installing BlueJeans
echo "=================================================================================="
echo "Installing BlueJeans Client..."
jamf policy -event BlueJeans
echo "=================================================================================="

# Setting up user Dock
echo "=================================================================================="
echo "Configuring user Dock..."
jamf policy -event DEPDock
echo "=================================================================================="

# Creating 'Last Imaged' and 'Image Config' tokens
echo "=================================================================================="
echo "Verifying app installs and creating Staff High Sierra token and..."
sh /usr/local/bin/jss/DEP-install-verification.sh
jamf policy -event DEPconfigstaffhighsierra
echo "=================================================================================="

# Quit SplashBuddy if still running
if [[ $(pgrep SplashBuddy) ]]; then
	pkill SplashBuddy
fi

# we are done, so delete SplashBuddy + new user setup script
rm -rf '/Library/Application Support/SplashBuddy'
rm /Library/Preferences/io.fti.SplashBuddy.plist
rm /Library/LaunchAgents/io.fti.SplashBuddy.launch.plist
rm /usr/local/bin/jss/DEP-setup-new-user.sh
rm /usr/local/bin/jss/DEP-start-setup.sh
rm /usr/local/bin/jss/DEP-install-verification.sh

# Telling user device setup is complete
sh /usr/local/bin/jss/DEP-setup-complete.sh

exit 0