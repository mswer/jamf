#!/bin/bash

# created by mw, 6-19-18
# updated by mw, 3-18-19 for deployment of BlueJeans 2.x
# script looks at BlueJeans large scale deployment site for the current mac installer, downloads and installs it
# may need occasional validation if BlueJeans redesigns the site or URL nomenclature

# Variables
installer_url=`/usr/bin/curl https://support.bluejeans.com/knowledge/desktop-app-deployment | grep mac/ |  cut -d \" -f 2`
BlueJeans_pkg="/tmp/BlueJeans.pkg"
BlueJeans1x="/Applications/Blue Jeans.app"
BlueJeans1xLA="/Users/$3/LaunchAgents/com.bluejeans.app.detector.plist"
BlueJeans2x="/Applications/BlueJeans.app"
BlueJeans2xLA="/Users/$3/Library/LaunchAgents/com.bluejeansnet.BlueJeansHelper.plist"

# Download installer
/usr/bin/curl -k --silent --retry 3 --retry-max-time 6 --fail --output $BlueJeans_pkg "$installer_url"

# Check if 1.x app is installed and remove if so
if [ -d "$BlueJeans1x" ] ; then
	echo "BlueJeans 1.x found. Checking if running..."
	ps aux | grep -q "Blue Jeans" &&
		echo "BlueJeans is running. Closing, then deleting old app and LaunchAgent..."
		for i in $(ps aux | grep "Blue Jeans" | grep -v grep | awk '{print $2}')
		do
			kill $i
		done
		rm -rf "$BlueJeans1x"
		rm "$BlueJeans1xLA"
	echo "No BlueJeans processes found. Deleting old app and LaunchAgent..."
	rm -rf "$BlueJeans1x"
    rm "$BlueJeans1xLA"
else
	echo "BlueJean 1.x not installed. Proceeding..."
fi

# Install BlueJeans
/usr/sbin/installer -pkg $BlueJeans_pkg -target /

# Confirm installation and set proper permissions
if [ -d "$BlueJeans2x" ] ; then
	BlueJeans_version=`defaults read "$BlueJeans2x"/Contents/Info CFBundleShortVersionString`
	echo "Bluejeans "$BlueJeans_version" installed successfully. Setting proper permissions..."
	chown -R "$BlueJeans2x"
	chmod -R 775 "$BlueJeans2x"
	echo "Installation complete. Cleaning up..."
    rm "$BlueJeans_pkg"
else
	echo "BlueJeans installation failed. Exiting.."
	exit 1
fi

# Clean up
rm -rf $BlueJeans_pkg
if [ -d "$BlueJeans2x" ] && [ -n "$3" ] ; then
	echo "Loading BlueJeansHelper in background, then exiting..."
	#osascript -e 'tell application "BlueJeans" to activate' > /dev/null 2>&1
    cp "$Bluejeans2x"/Contents/Resources/daemon/BlueJeansHelper.app/Contents/Resources/com.bluejeansnet.BlueJeansHelper.plist "$BlueJeans2xLA"
	chmod 555 "$BlueJeans2xLA"
	launchctl load "$BlueJeans2xLA"
exit 0
fi
