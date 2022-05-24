#!/usr/bin/env bash

: '
Script created by Valentin DEVILLE (contact[@]valentin-deville.eu)
Available on Github: https://github.com/MyTheValentinus/docker-volume-backup

Thanks to loomchild for his tools https://github.com/loomchild/volume-backup
'


BACKUPS_DIR="/home/valentin/docker/backup/"
BACKUP_FLAG="backup_flag"



debug_log() {
    echo "[$(date --rfc-3339=seconds)] ${1}"
}

backup_volume() {
    volume=$1
    TEMP_CONTAINERS=()

    # Stop all containers that use the volume to be save
    for container in $(docker ps --filter=volume=$volume -q); do
      TEMP_CONTAINERS+=($container)
      docker stop $container
      debug_log "Container ${container} stopped"
    done

    # Make Backup
    docker run -v $volume:/volume --rm loomchild/volume-backup backup - > $BACKUPS_DIR$volume-$(date '+%d-%h-%Y-%H%M%S').tar.bz2
    debug_log "Volume ${volume} backuped"

    # Restart before stopped containers
    for container in ${TEMP_CONTAINERS[@]}; do
      docker start $container
      debug_log "Container ${container} started"
    done
}

restore_volume() {
    volume=$1
    archive=$2
    TEMP_CONTAINERS=()

    # Stop all containers that use the volume to be save
    for container in $(docker ps --filter=volume=$volume -q); do
      TEMP_CONTAINERS+=($container)
      docker stop $container
      debug_log "Container ${container} stopped"
    done

    # Make Restore
    cat $archive | docker run -i -v $volume:/volume --rm loomchild/volume-backup restore -f -
    debug_log "Volume ${volume} restored"

    # Restart before stopped containers
    for container in ${TEMP_CONTAINERS[@]}; do
      docker start $container
      debug_log "Container ${container} started"
    done
}

# Check if help is call
while getopts ":h" opt; do
  case ${opt} in
    h )
      echo "Usage:"
      echo "    backup -v <volume_name>                 Backup a specified volume or 'ALL' to backup all volumes with the backup label"
      echo "    restore -v <volume_name> <backup_file>  Restore a specified volume with specific backup"
      echo "    list-backups [[-v] <volume_name>]       List backups for a volume or by default for all volumes"
      exit 0
      ;;
  esac
done
shift $((OPTIND -1))


action=$1; shift  # Backup, restore, list
case $action in

  backup)
    volume="ALL"

    while getopts ":v:" opt; do
      case ${opt} in
        v)
          volume=$OPTARG
          ;;
        :)
          echo "Invalid option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done

    if [[ $volume == "ALL" ]]; then
        # Get the list of volume to be backup
        debug_log "Finding all volumes to be backup.."
      for volume in $(docker volume ls -f=label=$BACKUP_FLAG=True -q); do
        debug_log "Backuping ${volume}..."
        backup_volume $volume
        debug_log "Backup finished for ${volume}..."
      done
    else
        debug_log "Backuping ${volume}..."
        backup_volume $volume
        debug_log "Backup finished for ${volume}..."
    fi
    ;;

  restore)
    # Check if -t is supplied
    if [[ $1 != -v* ]]; then echo "No volume option specified (-v), please use -h to see the help" && exit 1; fi
    if [[ -z $3 ]]; then echo "No archive specified, please use -h to see the help" && exit 1; fi

    while getopts ":v:" opt; do
      case ${opt} in
        v)
          volume=$OPTARG
          ;;
        :)
          echo "Invalid option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done

    archive=$3
    if [[ -f "$archive" ]]; then
        debug_log "Restoring volume ${volume}.."
        restore_volume $volume $archive
        debug_log "Done."

    elif [[ ! -f "$BACKUPS_DIR/$archive" ]]; then
        debug_log "$archive not exist in current directory, but exist in ${BACKUPS_DIR}"
        archive=$BACKUPS_DIR/$archive
        debug_log "Restoring volume ${volume}.."
        restore_volume $volume $archive
        debug_log "Done."

    else
        debug_log "$archive not exist in ${BACKUPS_DIR}.. exiting."
        exit 1
    fi

    ;;

  list-backups)
    volume="ALL"
    while getopts ":v:" opt; do
      case ${opt} in
        v)
          volume=$OPTARG
          ;;
      esac
    done
    if [[ $volume == "ALL" ]]; then
        ls -lrt $BACKUPS_DIR | awk '{ print $NF }'
    else
        ls -lrt $BACKUPS_DIR$volume* | awk '{ print $NF }'
    fi

    ;;
  * )
    echo "No valid action, add -h argument to view the help" 1>&2
    exit 1
    ;;
esac
