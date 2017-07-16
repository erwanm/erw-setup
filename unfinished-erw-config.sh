#!/bin/bash

progName="erw-config.sh"
mode=
activeDirLocation="/mnt/data"
packagesRepos="git@github.com:erwanm/erw-setup.git git@github.com:erwanm/erw-bash-commons.git"
verbose=0
nonInteractive=

function usage {
    echo "Usage: $progName [options] <read|write>"
    echo
    echo "  - In read mode, checks that my config (folders etc.) is in place."
    echo "  - In write mode, installs my config."
    echo
    echo "  Options:"
    echo "    -h this help message"
    echo "    -a <active dir location>. Default: $activeDirLocation"
    echo "    -v verbose mode"
    echo "    -n non-interactive mode (fails if user input required)"
    echo    
}


function failMsg {
    msg="$1"
    echo "$msg" 1>&2
    exit 10
}



function execCheckExitStatus {
    cmd="$1"
    execDir="$2"

    if [ ! -z "$execDir" ]; then
	pushd "$execDir" >/dev/null
    fi
    eval "$cmd"
    status=$?
    if [ $status -ne 0 ]; then
	echo "Error: command '$cmd' returned exit status $status" 1>&2
	if [ ! -z "$execDir" ]; then
	    popd >/dev/null
	fi
	exit 1
    fi
    if [ ! -z "$execDir" ]; then
	popd >/dev/null
    fi

}



function printInfo {
    level="$1"
    info="$2"
    if [ $verbose -ge "$level" ]; then
	echo "$info"
    fi
}


function checkDir {
    dir="$1"
    if [ ! -d "$dir" ]; then
	if [ "$mode" == "read" ]; then
	    failMsg "Error: directory '$dir' not found."
	else
	    execCheckExitStatus "mkdir \"$dir\""
	fi
    fi
}



function showSSHPublicKey {
    keyFile="$HOME/.ssh/id_rsa.pub"
    if [ ! -f "$keyFile" ]; then
	if [ ! -z "$nonInteractive" ]; then
	    failMsg "SSH public key '$keyFile' not found."
	fi
	TODO


	
    fi
    printInfo 0 "SSH public key:"
    cat "$keyFile"
}


function checkGitRepo {
    location="$1"
    repo="$2"

    name0=${repo##*/}
    name=${name0%.git}
    if [ -d "$location/$name" ]; then
	if [ -d "$location/$name/.git" ]; then
	    printInfo 1 "Git local repo '$location/$name': OK"
	else
	    failMsg "Error: directory '$location/$name' exists but no local git repo"
	fi
    else
	if [ "$mode" == "read" ]; then
	    failMsg "Error: no local git repo '$location/$name'"
	else
	    printInfo 0 "Cloning git repo $repo to '$location/$name'..."
	    execCheckExitStatus "git clone $repo" "$location"
	fi
    fi	    
    
}



while getopts 'va:h' option ; do
    case $option in
	"h" ) usage
	      exit 0;;
	"a" ) activeDirLocation="$OPTARG";;
	"v" ) verbose=1;;
	"n" ) nonInteractive="1"
        "?" )
            echo "Error, unknow option." 1>&2
            usage 1>&2
	    exit 1
    esac
done
shift $(($OPTIND - 1)) # skip options already processed above
if [ $# -ne 1 ]; then
    echo "Error: 1 argument expected, $# found." 1>&2
    usage 1>&2
    exit 1
fi
mode="$1"

# folder structure
checkDir "$activeDirLocation"
checkDir "$activeDirLocation/active"
checkDir "$activeDirLocation/active/always"
checkDir "$activeDirLocation/active/now"
checkDir "$activeDirLocation/active/souk"
softDir="$activeDirLocation/active/always/software"
checkDir "$softDir"
printInfo 1 "Folders structure: OK"

# my packages
for gitRepo in $packagesRepos; do
    checkGitRepo "$softDir" "$gitRepo"
done

