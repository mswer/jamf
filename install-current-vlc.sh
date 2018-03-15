#----------------------------------------------------------------------------------------
# Dev: Aaron Baumgarner
# Created: 29 July 2015
# Retrieved from https://www.jamf.com/jamf-nation/third-party-products/files/930/update-install-vlc
# Refreshed by Tim Kimpton 17th May 2017
# Updated to properly echo version, and updated to faster download mirror by Hector Castaneda, 6th July 2017
# Updated by Matt Wertheimer to successfully pull the full VLC version on line 15, added lines 41-43 to verify VLC installed successfully
# Description: This script is used to download and install the latest version VLC
#----------------------------------------------------------------------------------------

# Queries VLC's website for one version behind the latest.
vlc_version=`/usr/bin/curl https://mirror.wdc1.us.leaseweb.net/videolan/vlc/last/macosx/ | grep vlc- | cut -d \" -f 2 | awk '{printf("%s",$0);}' | cut -d . -f 1-5 | cut -d "/" -f 2`

echo $vlc_version

# Creates the download url based on the version pulled from the website
fileURL="https://mirror.wdc1.us.leaseweb.net/videolan/vlc/last/macosx/"$vlc_version".dmg"

echo $fileURL

vlc_dmg="/tmp/vlc.dmg" 

#Download latest VLC based on the url created
/usr/bin/curl --output /tmp/vlc.dmg "$fileURL"


#Mount the .dmg
/usr/bin/hdiutil attach "$vlc_dmg" -nobrowse -noverify -noautoopen

vol_name=$(ls /Volumes/ | grep VLC)

sleep 10

#Installs VLC
cp -r /Volumes/"$vol_name"/VLC.app /Applications/

#Confirm installation and set proper permissions, update jamf log
if [ -d /Applications/VLC.app ]; then
chown -R root:admin /Applications/VLC.app
chmod -R 775 /Applications/VLC.app
echo "$vlc_version successfully installed"  >> /var/log/jamf.log
else
echo "VLC installation failed :'(" >> /var/log/jamf.log
fi

#Cleanup
/usr/bin/hdiutil detach -force /Volumes/"$vol_name"
/bin/rm -rf "$vlc_dmg"

exit 0
