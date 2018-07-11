#!/bin/bash

# mw 07-10-18
# script to close programs likely to be open 

# Quit Safari if still running
if [[ $(pgrep 'Safari') ]]; then
	pkill 'Safari'
fi

# Quit Self Service if still running
if [[ $(pgrep 'Self Service') ]]; then
	pkill 'Self Service'
fi