#!/bin/bash

RETHINKDB_HOST=${RETHINKDB_HOST:-rethinkdb-proxy}
RETHINKDB_PORT=${RETHINKDB_PORT:-28015}
BACKUP_NAME=${BACKUP_NAME:-rethinkdb}

[ -z "${GCLOUD_BUCKET}" ] && { echo "=> GCLOUD_BUCKET cannot be empty" && exit 1; }

echo "RETHINKDB: HOST: ${RETHINKDB_HOST}, PORT: ${RETHINKDB_PORT}, DB ${RETHINKDB_DB}, GCLOUD_BUCKET: ${GCLOUD_BUCKET}, BACKUP_NAME: ${BACKUP_NAME}, EXTRA_OPTS ${EXTRA_OPTS}"

FILE_NAME="${BACKUP_NAME}_$(date +\%m_\%d_\%Y_\%H_\%M_\%S).tar.gz"

echo "=> Backup starting"

rethinkdb-dump -c ${RETHINKDB_HOST}:${RETHINKDB_PORT} -f ${FILE_NAME} ${EXTRA_OPTS}
if [ $? -ne 0 ];then
  echo "   Backup failed"
  rm -rf /backups/\${FILE_NAME}
  exit 1
else
  echo "   Backup succeeded"
fi

if [ -n "$GCLOUD_AUTH_EMAIL" ]; then
  echo "   Authenticating with Google Service Account"
  gcloud auth activate-service-account $GCOUD_AUTH_EMAIL --key-file /etc/gcloud/$GCLOUD_KEY_FILE --project $GCLOUD_PROJECT_ID
  if [ $? -ne 0 ]; then
    echo "   Authentication failed"
    exit 1
  fi
fi

echo "=> Uploading backup to Google Storage"

gsutil cp ${FILE_NAME} gs://${GCLOUD_BUCKET}

if [ $? -ne 0 ]; then
  echo "   Upload failed"
  exit 1
else
  echo "   Upload succeeded"
fi

gsutil cp gs://${GCLOUD_BUCKET}/${FILE_NAME} gs://${GCLOUD_BUCKET}/${BACKUP_NAME}_latest.tar.gz

if [ $? -ne 0 ]; then
  echo "   Copy to _latest.tar.gz failed"
  exit 1
else
  echo "   Latest copy succeeded"
fi

echo "=> Backup finished"
