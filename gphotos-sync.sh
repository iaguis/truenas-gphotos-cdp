#!/usr/bin/env bash

function usage () {
    echo "Usage: $0 [short|medium|long|full]"
}

if [ $# != 1 ]; then
    usage
    exit 1
fi

if [ "$1" == "short" ]; then
    SCAN_MODE="short"
elif [ "$1" == "medium" ]; then
    SCAN_MODE="medium"
elif [ "$1" == "long" ]; then
    SCAN_MODE="long"
elif [ "$1" == "full" ]; then
    SCAN_MODE="full"
else
    usage
    exit 1
fi

function is_sync_running() {
    local MODE="$1"

    for pid in $(pgrep -f "gphotos-sync.sh $MODE"); do
        if [ "$pid" != $$ ]; then
            return 0
        fi
    done

    return 1
}

if [ $SCAN_MODE == "full" ]; then
    if is_sync_running "full"; then
        echo "Full sync already running. Exiting..."
        exit 0
    fi
    killall chrome
elif [ $SCAN_MODE == "long" ]; then
    if is_sync_running "long"; then
        echo "Long sync already running. Exiting..."
        exit 0
    fi
    if is_sync_running "full"; then
        echo "Full sync already running. Exiting..."
        exit 0
    fi
    killall chrome
elif [ $SCAN_MODE == "medium" ]; then
    if is_sync_running "medium"; then
        echo "Medium sync already running. Exiting..."
        exit 0
    fi
    if is_sync_running "long"; then
        echo "Long sync already running. Exiting..."
        exit 0
    fi
    if is_sync_running "full"; then
        echo "Full sync already running. Exiting..."
        exit 0
    fi
    killall chrome
else
    if is_sync_running; then
        echo "Sync already running. Exiting..."
        exit 0
    fi
    killall chrome
fi

OUTPUT_DIR="/home/nonroot/Downloads/gphotos-cdp"

# First pass, download everything using traditional gphotos-cdp
if [ ! -e "$OUTPUT_DIR" ]; then
    while true; do
        timeout 15m gphotos-cdp --dev -v -headless
        if [ $? == 0 ]; then
            break
        else
            killall chrome
        fi
    done

    exit 0
fi

# Incremental downloads

if [ $SCAN_MODE == "short" ]; then
    # Start from 5 days ago
    DATE_LIMIT="$(date -d "5 days ago" "+%Y-%m-%d")"
    DAYS_THRESHOLD=5
elif [ $SCAN_MODE == "medium" ]; then
    # Start from 30 days ago
    DATE_LIMIT="$(date -d "30 days ago" "+%Y-%m-%d")"
    DAYS_THRESHOLD=10
elif [ $SCAN_MODE == "long" ]; then
    # Start from 2 years ago
    DATE_LIMIT="$(date -d "2 years" "+%Y-%m-%d")"
    DAYS_THRESHOLD=30
fi

if [ "$DATE_LIMIT" ]; then
    FILES="$(ls -ht "$OUTPUT_DIR")"

    for d in $FILES; do
        while IFS= read -r -d '' f; do
            EXIFDATE="$(exiftool -T -DateTimeOriginal "$f")"
            if [ $? != 0 ]; then
                continue
            fi

            DATE="$(echo "$EXIFDATE" | awk '{print $1}' | sed 's/:/-/g')"
            DATE_DIFF="$((($(date -d "$DATE_LIMIT" +%s) - $(date -d "$DATE" +%s))/86400))"
            echo "[debug] $f - DATE_DIFF = $DATE_DIFF (threshold: $DAYS_THRESHOLD)"
            if [ $DATE_DIFF -ge -"$DAYS_THRESHOLD" ] && [ $DATE_DIFF -le "$DAYS_THRESHOLD" ]; then
                URL='https://photos.google.com/photo/'"$d"
                break
            fi
        done < <(find "$OUTPUT_DIR/$d" -iname "*jpg" -print0)
        if [ -n "$URL" ]; then
            break
        fi
    done
fi

SUCCESS=0

if [ "$DATE_LIMIT" ]; then
    # start at some reasonable photo ($DATE_LIMIT) to capture new
    # shared album photos in combination with the skipexisting flag
    timeout 10m gphotos-cdp --dev -v -headless -skipexisting -start "$URL"
else
    # start from the beginning but skip already downloaded files
    mv "$OUTPUT_DIR"/.lastdone "$OUTPUT_DIR"/.lastdone.backup
    mv "$OUTPUT_DIR"/.lastdone.bak "$OUTPUT_DIR"/.lastdone.bak.backup
    timeout 10m gphotos-cdp --dev -v -headless -skipexisting
fi
if [ $? == 0 ]; then
    SUCCESS=1
else
    RETRIES=10
    TIMEOUT="10m"

    if [ $SCAN_MODE == "full" ] || [ $SCAN_MODE == "long" ]; then
        # Starting from long ago is less reliable, retry more and more
        # often
        RETRIES=300
        TIMEOUT="5m"
    fi

    # timeout or error, try some more times before giving up
    for _ in $(seq 1 $RETRIES); do
        timeout "$TIMEOUT" gphotos-cdp --dev -v -headless -skipexisting
        if [ $? == 0 ]; then
            SUCCESS=1
            break
        fi
    done
fi

# don't let lingering chrome processes
killall chrome

if [ $SUCCESS == 1 ]; then
    # success! let's unzip possible Photos.zip and exit

    # shellcheck disable=SC2016
    find "$OUTPUT_DIR" -name 'Photos.zip' -execdir unzip '{}' \; -exec bash -c 'mv "$1" "$1.bak"' bash {} \;
    exit 0
else
    # fail!
    exit 1
fi
