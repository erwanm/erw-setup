
#
# Erwan Moreau 22/02/11
# my aliases, config and a few short useful functions
#
# Updated Nov 16
#

## PATH, EXPORTS

export PATH=$PATH:$HOME/local/bin:.
export TMP=/tmp
export TMPDIR=/tmp
export LINES COLUMNS
export EDITOR='emacs -nw'
export PS1="\u@\h:\w> "


## ALIASES

alias rm="rm -i"
alias ll="ls -l"
alias cp="cp -i"
alias mv="mv -i"
alias rrm="rm -f"
alias max10dir="find . -maxdepth 1 -type d -print | xargs -i du -sm {} | sort -rn | head -n 11"
alias jo="joe -nobackups"


## FUNCTIONS

#
# Recursively run a given command in all subdirectories 
# from the current directory tree directory.
#
# Parameters: list of commands to be applied in each directory.
# (depth-first, i.e. current dir = last one)
#
function foralldirs {
  old_shopt_nullglob=$(shopt -p nullglob)
  shopt -s nullglob
  for entree in *; do
    if [ -d "$entree" ]; then
        cd "$entree"
        foralldirs "$@"
        cd ..
    fi
  done 
  eval "$old_shopt_nullglob"  
  while [ $# -ne 0 ]; do
    eval "$1"
    shift
  done
}


#
#
# STDIN=content, $1= address, $2=subject, other parameters = attached files
# requires mutt to be installed and properly configured (smtp server)
#
function send-email-via-mutt {
  if [ $# -eq 2 ] && [ "$1" != "-h" ] && [ "$2" != "-h" ]; then
    adr="$1"
    sujet="$2"
    shift 2
    attaches=" "
    while [ $# -ne 0 ]; do
      if [ -f "$1" ]; then
        attaches="$attaches -a \"$1\" "
      else
        echo "Error : unable to read file \"$1\"." >/dev/stderr
      fi
      shift
    done
    muttrc=$(mktemp --tmpdir "mutt-rc-XXXXXX")
    muttsent=$(mktemp --tmpdir "mutt-sent-XXXXXX")
    echo "set record=$muttsent;" > "$muttrc"
    eval  mutt -F "\"$muttrc\"" -s "\"$sujet\"" $attaches "\"$adr\"" 
    rm -f "$muttrc" "$muttsent"
  else
    echo "Usage: $0 <address> <subject> [ attached-file1 ... ]"
    echo "Content is read from STDIN."
    echo
  fi
}



#
# remove CR DOS end of line characters in $1
#
function rm-dos-cr {
  mv $1 $1.tmp
  rm -f $1
  tr -d "\015" <$1.tmp >$1
  rm $1.tmp
}


# mounts an ISO image in a directory
function iso_read {
  if [ $# != 2 ]; then
    echo "Syntax: iso_read <image ISO> <point de montage>"
    return 1
  fi
  mount -oro,loop=/dev/loop0 -v $1 $2
}



# renames any $1.xxx as $2.xxx (for any xxx extension)
#
function mv-all {
  if [ $# -ne 2 ]; then
    echo "Usage: mv_all <prefix1> <prefix2>" > /dev/stderr
    echo "   renames any prefix1.xxx as prefix2.xxx (for any xxx extension)" > /dev/stderr
    return 1
  fi
  for oldf in "$1".*; do
    if [ -f "$oldf" ]; then
      mv "$oldf" "$2${oldf:${#1}}"
    fi
  done
} 


#
# kill a process by name using grep
#
function kill-grep {
  if [ $# -eq 0 ]; then
    echo "Usage: kill-grep <grep pattern>"
    echo "CAUTION: NO WAY BACK!"
  else
    for num in $(ps uxww | grep "$1" |awk ' { print $2 } '); do 
      kill -9 $num; 
    done    
  fi
}
