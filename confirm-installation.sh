#!/bin/sh

# small script to confirm a desired item has been installed
# do not use \ in spaces in app name - it will be quoted so read literally
# e.g. format the APP_NAME variable as "Microsoft Word.app" not "Microsoft\ Word.app"

APP_NAME="APP_NAME.app"

if [ -d "/Applications/$APP_NAME.app" ]; then
	echo "$APP_NAME installed successfully!"
		else echo "$APP_NAME not installed."
fi

exit 0