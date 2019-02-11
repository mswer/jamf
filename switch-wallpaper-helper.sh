#!/bin/bash

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -title "Management Notification" -heading "Upgrade Complete!" -icon "/Library/Desktop Pictures/SA_DesktopWallpaper_2019.png" -description "Your computer has been successfully updated to macOS High Sierra! Would you like to keep your current wallpaper, or switch to the new dark SA wallpaper?

The dark wallpaper can help increase battery life (dark screen colors use less power) and reduce eye strain when looking at your computer screen."  -button1 "Switch!" -button2 "Keep current" -defaultButton 1 -cancelButton 2 -alignDescription left -alignHeading left

# Take action based on exit code
if [ $? -eq 0 ]
then
	echo "User wants dark wallpaper. Switching..." >> /var/log/jamf.log
	jamf policy -event wallpaper-dark
else
	echo "User wants to retain current wallpaper. Exiting..." >> /var/log/jamf.log
fi