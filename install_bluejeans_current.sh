#!/bin/bash

# created by mw, 6-19-18
# script looks at BlueJeans large scale deployment site for the current mac installer, downloads and installs it
# may need occasional validation if BlueJeans redesigns the site or URL nomenclature

# Get the pkg download URL
installer_url=`/usr/bin/curl https://support.bluejeans.com/knowledge/app-large-deployment | grep mac/ |  cut -d \" -f 2`

# Define location to save installer
bluejeans_pkg="/tmp/BlueJeans.pkg"

# Download installer
/usr/bin/curl --output $bluejeans_pkg "$installer_url"

# Install BlueJeans
/usr/sbin/installer -pkg $bluejeans_pkg -target /

# Confirm installation and set proper permissions
if [ -d /Applications/Blue\ Jeans.app ]; then
	chown -R root:wheel /Applications/Blue\ Jeans.app/
	chmod -R 775 /Applications/Blue\ Jeans.app/
else exit 1
fi

# Clean up
rm -rf $bluejeans_pkg
if [ -d /Applications/Blue\ Jeans.app ]; then
exit 0
fi