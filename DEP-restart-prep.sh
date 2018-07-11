#!/bin/bash

# mw 07-10-18
# script to close programs likely to be open 

# Quit Safari if still running
if pgrep -x "Safari" >> /dev/null
	then pkill "Safari"
fi

# Quit Self Service if still running
if pgrep -x "Self Service" >> /dev/null
	then pkill "Self Service"
fi

exit 0