HOSTNAME='localhost'
USERNAME='postgres'

BACKUP_DIR=/Users/vishnub/code/backups/

DAY_OF_WEEK_TO_KEEP=5 # It's Friday \m/
DAYS_TO_KEEP=7

S3_BUCKET='s3://backup2016.se.com/data/'

function perform_backups() {
    FREQUENCY=$1
    PGSQL_BACKUP_DIR=$BACKUP_DIR"$(date +%d-%m-%Y)$FREQUENCY/pgsql/"
    MONGO_BACKUP_DIR=$BACKUP_DIR"$(date +%d-%m-%Y)$FREQUENCY/mongo/"

    if ! mkdir -p $PGSQL_BACKUP_DIR; then
        echo "Failed to create backup directory $PGSQL_BACKUP_DIR." 1>&2
        exit 1;
    fi

    if ! mkdir -p $MONGO_BACKUP_DIR; then
        echo "Failed to create backup directory $MONGO_BACKUP_DIR." 1>&2
        exit 1;
    fi

    # postgres backup
    DATABASE_LIST_QUERY="select datname from pg_database where not datistemplate and datallowconn order by datname;"

    for DATABASE in `psql -h "$HOSTNAME" -U "$USERNAME" -At -c "$DATABASE_LIST_QUERY" postgres`
    do
        echo "Backing up $DATABASE"
        if ! pg_dump -Fp -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" | gzip > $PGSQL_BACKUP_DIR"$DATABASE".sql.gz.in_progress; then
            echo "Failed to backup $DATABASE" 1>&2
        else
            mv $PGSQL_BACKUP_DIR"$DATABASE".sql.gz.in_progress $PGSQL_BACKUP_DIR"$DATABASE".sql.gz
        fi
    done

    # mongo backup
    MONGODUMP=$(which mongodump)
    MONGO_TEMP_DIR=$BACKUP_DIR"mongo_temp/"
    if ! mkdir -p $MONGO_TEMP_DIR; then
        echo "Failed to create temp directory." 1>&2
        exit 1
    fi

    $MONGODUMP -o $MONGO_TEMP_DIR --quiet
    DIRS=$(find $MONGO_TEMP_DIR -mindepth 1 -maxdepth 1 -type d)
    for DIR in $DIRS;
    do
        if ! tar -zcf $DIR.tar.gz.in_progress -C $DIR .; then
            echo "Failed to backup $DB for mongo" 1>&2
        else
            mv $DIR.tar.gz.in_progress $MONGO_BACKUP_DIR"$(basename $DIR)".tar.gz
        fi
    done
    rm -rf $MONGO_TEMP_DIR
}

# monthly backups
DAY_OF_MONTH=`date +%d`
if [ $DAY_OF_MONTH -eq 1 ]; then
    find $BACKUP_DIR -maxdepth 2 -name "*-monthly" -exec rm -rf '{}' ';'
    perform_backups "-monthly"
fi

# weekly backups
DAY_OF_WEEK=`date +%u`
if [ $DAY_OF_WEEK = $DAY_OF_WEEK_TO_KEEP ]; then
    find $BACKUP_DIR -maxdepth 2 -name "*-weekly" -exec rm -rf '{}' ';'
    perform_backups "-weekly"
fi

# daily backup
find $BACKUP_DIR -maxdepth 2 -mtime +$DAYS_TO_KEEP -name "*-daily" -exec rm -rf '{}' ';'
perform_backups "-daily"

$AWS_PATH=$(which aws)
$AWS_PATH s3 sync $BACKUP_DIR $S3_BUCKET --delete


