#!/bin/bash
#
# grive.sh - Script that will automatically sync grive
#
# Usage: ./grive.sh <grive_dir>
# Specifying a directory is optional, otherwise defaults to $HOME/Grive
#
# Remember to redirect stdout and stderr to a log file in crontab! ( &>>$HOME/grive.log )
#
# crontab line I use is as follows, syncs every 5 minutes and redirects to a log
#	*/5 * * * * /home/kyle/grive.sh &>>grive.log
#
# v1.0 June 1, 2016 17:36PST

### Variables

griveLog="$HOME/griveLog.log" # Saves it in the grive directory unless otherwise specified
griveDir="NULL"

### Functions

if [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
elif [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
else
	echo "commonFunctions.sh could not be located!"
	
	# Comment/uncomment below depending on if script actually uses common functions
	echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	exit 1
fi

### Main Script
debug "Starting $0..." $griveLog

# Determine runlevel for more debug
rl=$( runlevel | cut -d ' ' -f2 ) # Determine runlevel for additional info
case $rl in
	0)
	debug "Running script before shutdown!" $griveLog
	;;
	6)
	debug "Running script before reboot!" $griveLog
	;;
	*)
	continue
	;;
esac

# Optionally set directory for grive to use

if [[ -z $1 ]]; then
	export griveDir="$HOME/Grive"
else
	export griveDir="$1"
fi

# Check if directory exists
if [[ ! -d $griveDir ]]; then
	export debugFlag=1
	debug "Directory given does not exist, please fix and setup Grive for this directory!" $griveLog
	exit 1
fi

# Check if grive is installed
if [[ ! -e /usr/bin/grive ]]; then
	export debugFlag=1
	debug "Grive is not installed! Please install and setup, and re-run script!" $griveLog
	exit 2
fi

# Quit early if there is no internet connection
ping -q -c 1 8.8.8.8 &>/dev/null # Redirects to null because I don't want ping info shown, should be headless!
if [[ $? != 0 ]]; then
	export debugFlag=1
	debug "No internet connection, cancelling sync!"
	exit 3
fi

# If checks pass, sync!
cd $griveDir
grive sync &>> $griveLog

if [[ $? != 0 ]]; then
	debug "An error occurred with grive, check log for more info!" $griveLog
	echo "Grive encountered an error while attempting to sync at $(date)! Please view $griveLog for more info." | mail -s "grive.sh" $USER
	exit 4
fi

debug "Done with script!" $griveLog
#EOF