#!/bin/bash

MobileAccount=`dsconfigad -show | grep mobile | awk '{ print $7 }'`

echo "<result>$MobileAccount</result>"

exit 0