
remoteProxy="moreaue@turing.cs.tcd.ie"

homeActive="/mnt/data/active"
homeActiveName="$HOSTNAME-active"
backupTargetActiveHD="/media/erwan/sg-big-ext4/backup/always"
# TODO problem: I can't use encfs-init etc. on dilly, but going through moreaue apparently causes permission issues and hangs forever
# Current work-around = copy the encrypted HD backup with clear rsync.
# I think the best solution will be for the location to be either a HD connected to moreaue or "attic" host
#backupTargetActiveRemote="moreaue:/home/moreaue/experimental-dilly/backup/always"
backupTargetActiveRemote="dilly:/experimental/Erwan/backup/always"

homeArchives="/media/erwan/sg-big-ext4/archives.encfs"
homeArchivesName="archives"
backupTargetArchivesHD="/media/erwan/wd2Text4/backup/"
backupTargetArchivesRemote="dilly:/experimental/Erwan/backup/always"

fullHomedir="/home/erwan"
backupTargetFullHomedirDD="/media/erwan/sg-big-ext4/backup/always"
backupTargetFullHomedirRemote="dilly:/experimental/Erwan/backup/always"

archivesSourceMusicPath="always/music/selections/full"
homeMusicDir="/mnt/data/music"
dillyMusicDir="dilly:/experimental/Erwan/music"

tmpDirBackup="/media/erwan/sg-big-ext4/tmp"
myGPGKey=3D9072C1EC7BF5FC910761F3347AED5300981861


function checkDir {
    local dir="$1"
    if [ ! -d "$dir" ]; then
	echo "Cannot find dir '$dir' (removable drive not connected?)" 1>&2
	exit 2
    fi
}

function TRANSFER_home_active_backup_HD {
    local regularity="$1"
    if [ -z "$regularity" ]; then echo "Error: arg 'regularity' is empty." 1>&2; exit 3; fi
    checkDir "$backupTargetActiveHD" || exit $?
    TRANSFER_encfs_rsync_pass_custom_pwd "$homeActive" "$backupTargetActiveHD/$homeActiveName.$regularity.encfs" || exit $?
}

function TRANSFER_home_active_backup_remote {
    local regularity="$1"
    if [ -z "$regularity" ]; then echo "Error: arg 'regularity' is empty." 1>&2; exit 3; fi
    #    TRANSFER_encfs_rsync_pass_custom_pwd "$homeActive" "$backupTargetActiveRemote/$homeActiveName.$regularity.encfs" "-g $remoteProxy" || exit $?
    # temporary work around: clear rsync from HD backup
    TRANSFER_clear_rsync "$backupTargetActiveHD/$homeActiveName.$regularity.encfs" "$backupTargetActiveRemote/$homeActiveName.$regularity.encfs" "-g $remoteProxy" || exit $?
}



function TRANSFER_home_archives_backup_HD {
#    local regularity="$1"
#    if [ -z "$regularity" ]; then echo "Error: arg 'regularity' is empty." 1>&2; exit 3; fi
    checkDir "$homeArchives" || exit $?
    checkDir "$backupTargetArchivesHD" || exit $?
    #    TRANSFER_clear_rsync "$homeArchives" "$backupTargetArchivesHD/$homeArchivesName.$regularity.encfs" || exit $?
    TRANSFER_clear_rsync "$homeArchives" "$backupTargetArchivesHD/$homeArchivesName.encfs" || exit $?
}

function TRANSFER_home_archives_backup_remote {
    local regularity="$1"
    if [ -z "$regularity" ]; then echo "Error: arg 'regularity' is empty." 1>&2; exit 3; fi
    checkDir "$homeArchives" || exit $?
    TRANSFER_clear_rsync "$homeArchives" "$backupTargetArchivesRemote/$homeArchivesName.$regularity.encfs" "-g $remoteProxy" || exit $?
}



function TRANSFER_home_HD {
    local regularity="$1"
    TRANSFER_home_active_backup_HD "$regularity" || exit $?
    TRANSFER_home_archives_backup_HD "$regularity" || exit $?
}

function TRANSFER_home_remote {
    local regularity="$1"
    TRANSFER_home_active_backup_remote "$regularity" || exit $?
    TRANSFER_home_archives_backup_remote "$regularity" || exit $?
}


# todo not weekly?
function TRANSFER_home {
    TRANSFER_home_HD weekly || exit $?
    TRANSFER_home_remote weekly || exit $?
}



function TRANSFER_full_homedir_sqgpg {
    local destFile="$1"
    #    local proxyOpt="$2"
    local tmpDirOpt="$2"

    checkDir "$(dirname "$destFile")" || exit $?
    if [ ! -z "$tmpDirOpt" ] && [ -d "$tmpDirOpt" ]; then
	sqFile=$(mktemp --tmpdir=$tmpDirOpt "TRANSFER_full_homedir.XXXXXXXXXX")
    else
	sqFile=$(mktemp --tmpdir "TRANSFER_full_homedir.XXXXXXXXXX")
    fi
    rm -f $sqFile
    TRANSFER_squash "$fullHomedir" "$sqFile"  || exit $?
    TRANSFER_gpg "$sqFile" "$destFile" "$myGPGKey" || exit $?
#    comm="rsync $proxyOpt $sqFile.gpg $destFile"
#    eval "$comm"  || exit $?
    rm -f "$sqFile"
}



function TRANSFER_full_homedir_sqgpg_backup_DD {
    mydate=$(date +"%y%m%d")
    TRANSFER_full_homedir_sqgpg "$backupTargetFullHomedirDD/$HOSTNAME-fullhomedir.$mydate.sqsh.gpg" "$tmpDirBackup"
}

# disabled December 2018: unworkable, would take too much time
#function TRANSFER_full_homedir_sqgpg_backup_remote {
#    mydate=$(date +"%y%m%d")
#    TRANSFER_full_homedir_sqgpg "$backupTargetFullHomedirRemote/$HOSTNAME-fullhomedir.$mydate.sqsh.gpg" "$remoteProxy"
#}


function TRANSFER_music {
    local dest="$1"
    local proxyOpt="$2"
    checkDir "$homeArchives" || exit $? 
    mountPoint=$(mktemp -d --tmpdir "TRANSFER_music_home.XXXXXXXXXX")
    encfs-open.sh "$homeArchives" "$mountPoint" || exit $?
    TRANSFER_clear_rsync "$mountPoint/$archivesSourceMusicPath/" "$dest/" "$proxyOpt -o '--copy-links --exclude-from=$mountPoint/$archivesSourceMusicPath.excluded'" || exit $?
    encfs-close.sh "$mountPoint" || exit $?
    rmdir "$mountPoint"
}



function TRANSFER_music_home {
    TRANSFER_music "$homeMusicDir" || exit $?
}

function TRANSFER_music_dilly {
    TRANSFER_music "$dillyMusicDir" "-g $remoteProxy" || exit $?
}

