#!/usr/bin/env bash

function usage () {
    echo "Usage: $0 [short|medium|full]"
}

if [ $# != 1 ]; then
    usage
    exit 1
fi

if [ "$1" == "short" ]; then
    SCAN_MODE="short"
elif [ "$1" == "medium" ]; then
    SCAN_MODE="medium"
elif [ "$1" == "full" ]; then
    SCAN_MODE="full"
else
    usage
    exit 1
fi

if [ $SCAN_MODE == "full" ]; then
    if pgrep -q -f "gphotos-sync.sh full"; then
        echo "Full sync already running. Exiting..."
        exit 0
    fi
    killall chrome
elif [ $SCAN_MODE == "medium" ]; then
    if pgrep -q -f "gphotos-sync.sh full" || pgrep -q -f "gphotos-sync.sh medium"; then
        echo "Medium or full sync already running. Exiting..."
        exit 0
    fi
    killall chrome
else
    if pgrep -q gphotos-sync.sh; then
        echo "Sync already running. Exiting..."
        exit 0
    fi
fi

OUTPUT_DIR="/home/iaguis/Downloads/gphotos-cdp"

# First pass, download everything using traditional gphotos-cdp
if [ ! -e "$OUTPUT_DIR" ]; then
    while true; do
        timeout 15m go/bin/gphotos-cdp --dev -v -headless
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
    DATE_LIMIT="$(date -v-5d "+%Y-%m-%d")"
elif [ $SCAN_MODE == "medium" ]; then
    # Start from 30 days ago
    DATE_LIMIT="$(date -v-30d "+%Y-%m-%d")"
fi

if [ "$DATE_LIMIT" ]; then
    FILES="$(ls -ht "$OUTPUT_DIR" | head -n 10000)"

    for d in $FILES; do
        for f in $(find "$OUTPUT_DIR/$d" -iname "*jpg"); do
            EXIFDATA=$(exif "$f")
            if [ $? != 0 ]; then
                continue
            fi

            DATE="$(echo "$EXIFDATA" | grep 'Date and Time (Ori' | awk -F'|' '{print $2}' | awk '{print $1}' | sed 's/:/-/g')"
            DATE_DIFF=$((($(date -jf %Y-%m-%d "$DATE_LIMIT" +%s) - $(date -jf %Y-%m-%d "$DATE" +%s))/86400))
            if [ $DATE_DIFF == 0 ]; then
                URL='https://photos.google.com/photo/'"$d"
                break
            fi
        done
        if [ -n "$URL" ]; then
            break
        fi
    done
fi

SUCCESS=0

if [ "$DATE_LIMIT" ]; then
    # start at some reasonable photo ($DATE_LIMIT) to capture new
    # shared album photos in combination with the skipexisting flag
    timeout 10m go/bin/gphotos-cdp --dev -v -headless -skipexisting -start "$URL"
else
    # start from the beginning but skip already downloaded files
    mv "$OUTPUT_DIR"/.lastdone "$OUTPUT_DIR"/.lastdone.backup
    mv "$OUTPUT_DIR"/.lastdone.bak "$OUTPUT_DIR"/.lastdone.bak.backup
    timeout 10m go/bin/gphotos-cdp --dev -v -headless -skipexisting
fi
if [ $? == 0 ]; then
    SUCCESS=1
else
    # timeout or error, try 10 more times before giving up
    for _ in $(seq 1 10); do
        timeout 10m go/bin/gphotos-cdp --dev -v -headless -skipexisting
        if [ $? == 0 ]; then
            SUCCESS=1
        fi
    done
fi

# don't let lingering chrome processes
killall chrome

if [ $SUCCESS == 1 ]; then
    # success! let's unzip possible Photos.zip and exit
    exit 0
else
    # fail!
    exit 1
fi
