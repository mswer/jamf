#!/bin/bash

# Define script variables
system_serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
loggedInUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
user_id=`id -u`
user_name=`id -un $user_id`
baduser1="_mbsetupuser"
baduser2="loginwindow"
SetupScript="/Library/Application Support/JAMF/tmp/DEP Setup New User.sh"

# Don't start setting the device up until there's a user logged in
if [ $loggedInUser == "$baduser1" ] || [ $loggedInUser == "$baduser2" ];
	then
		while [ $loggedInUser == $baduser1 ] || [ $loggedInUser == $baduser2 ] 
		do
			echo "User not logged in yet. Waiting..." >> /var/log/jamf.log
			sleep 5;
            exec sh $SetupScript
			done
			echo "User $loggedInUser is finally logged in. Starting device setup..." >> /var/log/jamf.log
	else
		echo "User $loggedInUser is already logged in. Starting device setup..." >> /var/log/jamf.log
	fi

# open SplashBuddy app
su $loggedInUser -c 'open -a /Library/Application Support/SplashBuddy/SplashBuddy.app'

# Setting ComputerName
echo "==================================================================================" >> /var/log/jamf.log
echo "Setting computer name to serial number and SA wallpaper..." >> /var/log/jamf.log
jamf policy -event wallpaper
jamf setComputerName -name $system_serial
echo "==================================================================================" >> /var/log/jamf.log

echo "==================================================================================" >> /var/log/jamf.log
echo "Creating sucadmin..." >> /var/log/jamf.log
jamf policy -event DEPMakeSucadmin
echo "==================================================================================" >> /var/log/jamf.log

# Finder FUT policies
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Finder FUT policies - will not be shown until restart..." >> /var/log/jamf.log
jamf policy -event FinderDEP
echo "==================================================================================" >> /var/log/jamf.log

# Opening Safari to Okta for password reset
echo "==================================================================================" >> /var/log/jamf.log
echo "Opening Safari to Okta" >> /var/log/jamf.log
jamf policy -event Okta
echo "==================================================================================" >> /var/log/jamf.log

# Start basic device setup
# This policy runs the following triggers for the following effects:
# wallpaper (sets SA wallpaper), EULA (installs loginwindow EULA), EnableRemoteMGMTDEP
# (enables ARD/SSH for sucadmin, PI_setfirmware (sets firmware password), EnableLocation
# (enables location services), SetTimeServer (sets 3 NTP time servers)
echo "==================================================================================" >> /var/log/jamf.log
echo "Running SA device customization policies..." >> /var/log/jamf.log
jamf policy -event SystemSettings
echo "==================================================================================" >> /var/log/jamf.log

# Installing Apple Enterprise Connect
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Apple Enterprise Connect..." >> /var/log/jamf.log
jamf policy -event EnterpriseConnect
echo "==================================================================================" >> /var/log/jamf.log

# Installing SonicWall Mobile Connect from JSS if missing from App Store
echo "==================================================================================" >> /var/log/jamf.log
echo "Checking if SonicWall installed from the App Store..." >> /var/log/jamf.log
	if [ ! -d "/Applications/SonicWall Mobile Connect.app" ];
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
# jamf policy -event ChromeDefault - commenting out bc script breaks Dock. May be fixed later.
echo "==================================================================================" >> /var/log/jamf.log

# Installing Flash and Java
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Flash..." >> /var/log/jamf.log
jamf policy -event BrowserPlugins
echo "==================================================================================" >> /var/log/jamf.log

# Installing Papercut Client
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Papercut Client..." >> /var/log/jamf.log
jamf policy -event PCClient
echo "==================================================================================" >> /var/log/jamf.log

# Preparing Share Drive
echo "==================================================================================" >> /var/log/jamf.log
echo "Installing Shared Drive dependencies (Zidget+ShadowConnect)..." >> /var/log/jamf.log
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
echo "Creating Staff High Sierra token and running recon..." >> /var/log/jamf.log
jamf policy -event DEPconfigstaffhighsierra
echo "==================================================================================" >> /var/log/jamf.log

# Unload + delete SplashBuddy LaunchAgent, Quit SplashBuddy if still running

if pgrep -x "SplashBuddy" >> /dev/null
	then
    	pkill "SplashBuddy"
	    launchctl unload /Library/LaunchAgents/io.fti.SplashBuddy.launch.plist
    	rm -rf /Library/LaunchAgents/io.fti.SplashBuddy.launch.plist
fi

# Alert prompting user to restart if Okta password reset is complete

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -title "Alert" -heading "Device Setup Complete ✅" -description "Your computer has been successfully prepared! To finalize setup, please restart now.

If you're a new hire, please complete your SA password setup at https://okta.successacademies.org if you haven't already, and then restart your computer.

Select 'Restart Now' to close all programs and restart immediately.
Select 'Restart Later' to complete device setup later."  -button1 "Restart now" -button2 "Restart later" -defaultButton 1 -cancelButton 2 -alignDescription left -alignHeading left

# Take action based on exit code
if [ $? -eq 0 ]
then
	echo "User indicated Okta setup complete. Rebooting..." >> /var/log/jamf.log
	jamf policy -event DEPReboot
else
	echo "User opted out of new device setup reboot. Exiting..." >> /var/log/jamf.log
fi

exit 0