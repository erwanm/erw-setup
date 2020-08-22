#!/bin/bash

# erw-setup
# Erwan Moreau, Nov. 2016
#
# My bash setup. Requires erw-bash-commons installed in the "main repository".
# This script is intended to be sourced from $HOME/.bashrc
#

aliasesPath="bash-aliases.sh"
cloudScriptsPath="/erwanshomedir/always/private-cloud/scripts"

# Get the location of this script
SCRIPT_PATH=$(dirname "$BASH_SOURCE")

#
# Give argument $1 to override the default location of the main repository
#
if [ -z "$1" ]; then
    mainrepo="$HOME/always/software"
else
    mainrepo="$1"
fi

# initialize erw-pm (in-house package mgmt)
source $mainrepo/erw-bash-commons/lib/init-erw-pm.sh
erw-pm addrepo $mainrepo

# source my standard settings
if [ -f "$SCRIPT_PATH/$aliasesPath" ]; then
    source "$SCRIPT_PATH/$aliasesPath"
else
    echo "Warning: file '$SCRIPT_PATH/$aliasesPath' not found." 1>&2
fi

# source machine-specific settings
if [ -f $HOME/local/bashrc ]; then
    source $HOME/local/bashrc
fi

# added March 17: add scripts to PATH from cloud dir
if [ -d "$cloudScriptsPath" ]; then
	export PATH=$PATH:$cloudScriptsPath
else
	echo "Warning: directory '$cloudScriptsPath' not found, cannot access cloud scripts" 1>&2
fi

# added August 20: encfs scripts repo
erw-pm activate encfs-util
