#!/bin/bash

# created by mw, 6-19-18
# script looks at BlueJeans large scale deployment site for the current mac installer, downloads and installs it
# may need occasional validation if BlueJeans redesigns the site or URL nomenclature

#  Get the pkg download URL
installer_url=`/usr/bin/curl https://support.bluejeans.com/knowledge/app-large-deployment | grep mac/ |  cut -d \" -f 2`

# Define location to save installer
bluejeans_pkg="/tmp/BlueJeans.pkg"

# Download installer
/usr/bin/curl -k --silent --retry 3 --retry-max-time 6 --fail --output $bluejeans_pkg "$installer_url"

# Install BlueJeans
/usr/sbin/installer -pkg $bluejeans_pkg -target /

# Confirm installation and set proper permissions
if [ -d /Applications/Blue\ Jeans.app ] ; then
	bluejeans_version=`defaults read /Applications/Blue\ Jeans.app/Contents/Info CFBundleShortVersionString`
	echo "BlueJeans "$bluejeans_version" installed successfully. Setting proper permissions..."
	chown -R root:wheel /Applications/Blue\ Jeans.app/
	chmod -R 775 /Applications/Blue\ Jeans.app/
	echo "Installation complete. Exiting..."
else
	echo "BlueJeans installation failed. Exiting.."
	exit 1
fi

# Clean up
rm -rf $bluejeans_pkg
if [ -d /Applications/Blue\ Jeans.app ]; then
exit 0
fi