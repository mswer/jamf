#!/bin/bash

# Define script variables
system_serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
loggedInUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
user_id=`id -u`
user_name=`id -un $user_id`

# open SplashBuddy app
su $loggedInUser -c 'open -a /Library/Application Support/SplashBuddy/SplashBuddy.app'
sleep 3
su $loggedInUser -c 'open -a /Library/Application Support/SplashBuddy/SplashBuddy.app'

# Setting ComputerName
echo "==================================================================================" >> /var/log/jamf.log
echo "Setting computer name to serial number..." >> /var/log/jamf.log
jamf setComputerName -name $system_serial
echo "==================================================================================" >> /var/log/jamf.log

echo "==================================================================================" >> /var/log/jamf.log
echo "Creating sucadmin..." >> /var/log/jamf.log
jamf policy -event DEPMakeSucadmin
echo "==================================================================================" >> /var/log/jamf.log

# Start basic device setup
# This policy runs the following triggers for the following effects:
# wallpaper (sets SA wallpaper), EULA (installs loginwindow EULA), UptimeReminder (installs
# uptime reminder components), EnableRemoteMGMTDEP (enables ARD/SSH for sucadmin, PI_setfirmware
# (sets firmware password), EnableLocation (enables location services), SetTimeServer
# (sets 3 NTP time servers), sucadminprofile (sets sucadmin profile picture)
echo "==================================================================================" >> /var/log/jamf.log
echo "Running SA device customization policies..." >> /var/log/jamf.log
jamf policy -event SystemSettings
echo "==================================================================================" >> /var/log/jamf.log

# Opening Safari to Okta for password reset
jamf policy -event Okta

# Finder FUT policies
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Finder FUT policies - will not be shown until restart..." >> /var/log/jamf.log
jamf policy -event FinderDEP
echo "==================================================================================" >> /var/log/jamf.log

# Installing Apple Enterprise Connect
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Apple Enterprise Connect..." >> /var/log/jamf.log
jamf policy -event EnterpriseConnect
echo "==================================================================================" >> /var/log/jamf.log

# Installing Apple Enterprise Connect
echo "==================================================================================" >> /var/log/jamf.log
echo "Checking if SonicWall installed from the App Store..." >> /var/log/jamf.log
if [ ! -d /Applications/SonicWall\ Mobile\ Connect.app ];
	then echo "App Store failed. Installing from JSS..." && jamf policy -event SonicWall 
	else
		echo "Installing SonicWall_Mobile_Connect_VPP-v1.pkg" >> /var/log/jamf.log
		echo "Actually, SonicWall was already installed." >> /var/log/jamf.log
		echo "Sometimes things work correctly :) Skipping JSS policy..." >> /var/log/jamf.log
		echo "Successfully installed SonicWall_Mobile_Connect_VPP-v1.pkg" >> /var/log/jamf.log
	fi
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
echo "Verifying app installs and creating Staff High Sierra token and running recon..." >> /var/log/jamf.log
sh /usr/local/bin/jss/DEP-install-verification.sh
jamf policy -event DEPconfigstaffhighsierra
echo "==================================================================================" >> /var/log/jamf.log

# Quit SplashBuddy if still running
if [[ $(pgrep SplashBuddy) ]]; then
	pkill SplashBuddy
fi

# we are done, so delete SplashBuddy + new user setup script
echo "Deleting device setup files..." >> /var/log/jamf.log
rm -rf '/Library/Application Support/SplashBuddy'
rm /Library/Preferences/io.fti.SplashBuddy.plist
rm /Library/LaunchAgents/io.fti.SplashBuddy.launch.plist
rm /usr/local/bin/jss/DEP-setup-new-user.sh
rm /usr/local/bin/jss/DEP-start-setup.sh
rm /usr/local/bin/jss/DEP-install-verification.sh

# Telling user device setup is complete
echo "Device setup complete. Notifying user..." >> /var/log/jamf.log
sh /usr/local/bin/jss/DEP-setup-complete.sh

exit 0