#!/bin/bash
set -e

# Abort entire script if any command fails
# S3QL_EXPORTER_ID=""
function disconnect() {
    
	echo "unmounting $S3QL_MOUNTPOINT"
    umount.s3ql "$S3QL_MOUNTPOINT"

    #echo "stoping prometheus"
    kill $S3QL_EXPORTER_ID    
 
    # echo "cleaning temporals"
    # rm -rf "${S3QL_CACHE_PATH}/*"
    echo "Stop Success!!"
}

echo "[backup-S3QL]" > /credentials
echo "storage-url: $STORAGE_URL" >> /credentials
echo "backend-login: $LOGIN_USER" >> /credentials
echo "backend-password: $LOGIN_PASSWORD" >> /credentials
echo "fs-passphrase: $PASSPHRASE" >> /credentials
chmod 700 /credentials

# Cache Size
CACHE_S3QL_SIZE=$((${CACHE_S3QL_SIZE}*1024*1024))
# Log File
logfile="$S3QL_CACHE_PATH/mount.log"

if [ ! -z "${BACKEND_OPTIONS}" ]; then
        BACKEND_OPTIONS='--backend-options "$BACKEND_OPTIONS"'
fi

mkdir -p "$S3QL_CACHE_PATH"


# Recover cache if e.g. system was shut down while fs was mounted
echo "check s3ql corruption"
if [ "$1" == "fsck" ]; then
    fsck.s3ql $BACKEND_OPTIONS \
    --cachedir "$S3QL_CACHE_PATH" \
    --authfile /credentials \
    "$STORAGE_URL"
    exit 0
fi
fsck.s3ql $BACKEND_OPTIONS \
    --force-remote --batch \
    --cachedir "$S3QL_CACHE_PATH" \
    --authfile /credentials \
    "$STORAGE_URL"

echo "mount s3ql to $S3QL_MOUNTPOINT"
# Convertimos a segundos
S3QL_METADATA_UPLOAD_INTERVAL=$((${S3QL_METADATA_UPLOAD_INTERVAL}*60*60))
# Create a temporary mountpoint and mount file system
mkdir -p "$S3QL_MOUNTPOINT"
mount.s3ql --log  "$logfile"\
    --cachedir "$S3QL_CACHE_PATH" \
    --cachesize $CACHE_S3QL_SIZE \
    --authfile /credentials \
    --compress $COMPRESS_METHOD \
    --metadata-upload-interval $S3QL_METADATA_UPLOAD_INTERVAL \
    --threads $S3QL_THREADS --nfs --allow-other \
    $BACKEND_OPTIONS "$STORAGE_URL" "$S3QL_MOUNTPOINT"

#echo "run prometheus exporter on port ${S3QL_PROMETHEUS_PORT}"
s3qlstat "$S3QL_MOUNTPOINT" --prometheus_port $S3QL_PROMETHEUS_PORT --prometheus_exporter &
S3QL_EXPORTER_ID=$!

# Make sure the file system is unmounted when we are done
# Note that this overwrites the earlier trap, so we
# also delete the lock file here.
trap disconnect  SIGINT
trap disconnect  SIGTERM

tail -f "$logfile" & wait
