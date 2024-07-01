# Docker volume backup

An utility to easily backup and restore your Docker volumes 


## Configuration

You need to change two variables:
`BACKUPS_DIR` and `BACKUP_FLAG` in the head of `.sh` file

`BACKUPS_DIR`: The directory where the backup goes

`BACKUP_FLAG`: The label you put on volumes you want to backup (if you dont specify specific volume to backup in command)


## Backup

### Backup all volumes tagged by a label

In docker-compose.yml:
```yaml
version: '3.3'

services:
   db:
     image: mysql:5.7
     volumes:
       - db_data:/var/lib/mysql
     ...
volumes:
    db_data:
      labels:
        backup_flag: true
```

For example:

    bash backup-volume-docker.sh backup


### Backup all volumes filled in the config variable BACKUP_VOLUMES

`BACKUP_VOLUMES="volume1 volume2"`

For example this config will backup volume1 and volume2:

    bash backup-volume-docker.sh backup -v CONFIG



### Backup specific volume


For example:

    bash backup-volume-docker.sh backup -v myvolume_example
    

## Restore

If you want to restore a backup

For example:

    bash backup-volume-docker.sh restore -v myvolume_example /mybackupdir/my_old_backup.tar.bz2

## List backups

For example to list all backups:

    bash backup-volume-docker.sh list-backups
    
For only one volume:

    bash backup-volume-docker.sh list-backups -v myvolume_example
    
    
    
Thanks,

Author: Valentin DEVILLE
