#!/bin/bash

RETHINKDB_HOST=${RETHINKDB_HOST:-rethinkdb-proxy}
RETHINKDB_PORT=${RETHINKDB_PORT:-28015}
BACKUP_NAME=${BACKUP_NAME:-rethinkdb}
FILE_NAME=${FILE_NAME:-${BACKUP_NAME}_latest.tar.gz}
DROP_ALL=${DROP_ALL:-false}

[ -z "${GCLOUD_BUCKET}" ] && { echo "=> GCLOUD_BUCKET cannot be empty" && exit 1; }

echo "RETHINKDB: HOST: ${RETHINKDB_HOST}, PORT: ${RETHINKDB_PORT}, DB ${RETHINKDB_DB}, GCLOUD_BUCKET: ${GCLOUD_BUCKET}, BACKUP_NAME: ${BACKUP_NAME}, FILE_NAME: ${FILE_NAME} EXTRA_OPTS ${EXTRA_OPTS}"

if [ -n "$GCLOUD_AUTH_EMAIL" ]; then
  echo "   Authenticating with Google Service Account"
  gcloud auth activate-service-account $GCOUD_AUTH_EMAIL --key-file /etc/gcloud/$GCLOUD_KEY_FILE --project $GCLOUD_PROJECT_ID
  if [ $? -ne 0 ]; then
    echo "   Authentication failed"
    exit 1
  fi
fi

echo "=> Downloading backup file"

gsutil cp gs://${GCLOUD_BUCKET}/${FILE_NAME} ${FILE_NAME}

if [ "${DROP_ALL}" == "true" ]; then
  echo "=> Dropping all dbs"
  python drop-dbs.py
fi

echo "=> Restore starting"

rethinkdb-restore ${FILE_NAME} --force -c ${RETHINKDB_HOST}:${RETHINKDB_PORT}  ${EXTRA_OPTS}
if [ $? -ne 0 ];then
  echo "   Restore failed"
  rm -rf /backups/\${FILE_NAME}
  exit 1
else
  echo "   Restore succeeded"
fi
