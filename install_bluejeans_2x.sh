#!/bin/bash

# created by mw, 6-19-18
# updated by mw, 3-18-19 for deployment of BlueJeans 2.x
# script looks at BlueJeans large scale deployment site for the current mac installer, downloads and installs it
# may need occasional validation if BlueJeans redesigns the site or URL nomenclature

#  variables
installer_url=`/usr/bin/curl https://support.bluejeans.com/knowledge/desktop-app-deployment | grep mac/ |  cut -d \" -f 2`
bluejeans_pkg="/tmp/BlueJeans.pkg"
BlueJeans1x="/Applications/Blue Jeans.app"
BlueJeans2x="/Applications/BlueJeans.app"

# Download installer
/usr/bin/curl -k --silent --retry 3 --retry-max-time 6 --fail --output $bluejeans_pkg "$installer_url"

# Check if 1.x app is installed and remove if so
if [ -d "$BlueJeans1x" ] ; then
	echo "Bluejeans 1.x found. Checking if running..."
	ps aux | grep -q "Blue Jeans" &&
		echo "Bluejeans is running. Closing, then deleting old app..."
		for i in $(ps aux | grep "Blue Jeans" | grep -v grep | awk '{print $2}')
		do
			kill $i
		done
		rm -rf "$BlueJeans1x" ||
	echo "No Bluejeans process found. Deleting old app..."
	rm -rf "$BlueJeans1x"
else
	echo "Blue Jean 1.x not installed. Proceeding..."
fi

# Install BlueJeans
/usr/sbin/installer -pkg $bluejeans_pkg -target /

# Confirm installation and set proper permissions
if [ -d "$BlueJeans2x" ] ; then
	bluejeans_version=`defaults read "$BlueJeans2x"/Contents/Info CFBundleShortVersionString`
	echo "Bluejeans "$bluejeans_version" installed successfully. Setting proper permissions..."
	chown -R root:wheel /Applications/BlueJeans.app/
	chmod -R 775 /Applications/BlueJeans.app/
	echo "Installation complete. Cleaning up..."
else
	echo "BlueJeans installation failed. Exiting.."
	exit 1
fi

# Clean up
rm -rf $bluejeans_pkg
if [ -d "$BlueJeans2x" ] && [ -n "$3" ] ; then
	echo "Launching new app so Bluejeans helper is running in background, then exiting..."
	osascript -e 'tell application "BlueJeans" to activate' > /dev/null 2>&1
exit 0
fi