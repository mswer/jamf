#!/bin/bash

#----------------------------------------------------------------------------------------
# based on https://www.jamf.com/jamf-nation/third-party-products/files/930/update-install-vlc
# Updated for Sublime Text 3 by mw 08-14-18
#----------------------------------------------------------------------------------------

# Queries VLC's website for one version behind the latest.
sublime_version=`/usr/bin/curl https://www.sublimetext.com/3 | grep "Sublime Text Build" | cut -d / -f 4 |  cut -d "\"" -f 1 | grep ".dmg"`

echo $sublime_version

# Creates the download url based on the version pulled from the website
fileURL="https://download.sublimetext.com/$sublime_version"

echo $fileURL

sublime_dmg="/tmp/sublime.dmg" 

#Download latest VLC based on the url created
/usr/bin/curl --output /tmp/sublime.dmg "$fileURL"

# Mount the .dmg
/usr/bin/hdiutil attach "$sublime_dmg" -nobrowse -noverify -noautoopen

vol_name=$(ls /Volumes/ | grep Sublime)

sleep 5

# Installs Sublime Text 3
cp -r /Volumes/"$vol_name"/Sublime\ Text.app /Applications/

#Confirm installation and set proper permissions, update jamf log
if [ -d "/Applications/Sublime Text.app" ]; then
	chown -R root:admin "/Applications/Sublime Text.app"
	chmod -R 775 "/Applications/Sublime Text.app"
echo "$sublime_version successfully installed"  >> /var/log/jamf.log
else
echo "Sublime Text installation failed :'(" >> /var/log/jamf.log
fi

#Cleanup
/usr/bin/hdiutil detach -force /Volumes/"$vol_name"
/bin/rm -rf "$sublime_dmg"

exit 0
