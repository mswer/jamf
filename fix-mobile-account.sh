#!/bin/bash

ADConfig=`dsconfigad -show`

# Enable mobile account creation and disable requirement for confirmation
echo "Enabling Mobile Account creation..." >> /var/log/jamf.log
dsconfigad -mobile enable
dsconfigad -mobileconfirm disable

# Print 
echo "Current directory settings following update" >> /var/log/jamf.log
echo $ADConfig >> /var/log/jamf.log

exit 0