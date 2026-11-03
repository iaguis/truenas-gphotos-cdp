#!/usr/bin/env bash

function usage () {
    echo "Usage: $0 [short|medium|long|full]"
}

if [ $# != 1 ]; then
    usage
    exit 1
fi

if [ -n "$HEALTHCHECK_ID" ]; then
    curl -sS -X POST -o /dev/null "https://hc-ping.com/$HEALTHCHECK_ID/start"
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

        if [ -n "$HEALTHCHECK_ID" ]; then
            curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
        fi

        exit 0
    fi
    killall chrome
elif [ $SCAN_MODE == "long" ]; then
    if is_sync_running "long"; then
        echo "Long sync already running. Exiting..."

        if [ -n "$HEALTHCHECK_ID" ]; then
            curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
        fi

        exit 0
    fi
    if is_sync_running "full"; then
        echo "Full sync already running. Exiting..."

        if [ -n "$HEALTHCHECK_ID" ]; then
            curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
        fi

        exit 0
    fi
    killall chrome
elif [ $SCAN_MODE == "medium" ]; then
    if is_sync_running "medium"; then
        echo "Medium sync already running. Exiting..."

        if [ -n "$HEALTHCHECK_ID" ]; then
            curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
        fi

        exit 0
    fi
    if is_sync_running "long"; then
        echo "Long sync already running. Exiting..."

        if [ -n "$HEALTHCHECK_ID" ]; then
            curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
        fi

        exit 0
    fi
    if is_sync_running "full"; then
        echo "Full sync already running. Exiting..."

        if [ -n "$HEALTHCHECK_ID" ]; then
            curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
        fi

        exit 0
    fi
    killall chrome
else
    if is_sync_running; then
        echo "Sync already running. Exiting..."

        if [ -n "$HEALTHCHECK_ID" ]; then
            curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
        fi

        exit 0
    fi
    killall chrome
fi

OUTPUT_DIR="/home/nonroot/Downloads/gphotos-cdp"

# First pass, download everything using traditional gphotos-cdp
if [ ! -e "$OUTPUT_DIR" ]; then
    while true; do
        timeout 15m gphotos-cdp -dldir /home/nonroot/Downloads/gphotos-cdp -dev -v -headless
        if [ $? == 0 ]; then
            break
        else
            killall chrome
        fi
    done

    if [ -n "$HEALTHCHECK_ID" ]; then
        curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
    fi

    exit 0
fi

# Incremental downloads

if [ $SCAN_MODE == "short" ]; then
    # Start from 5 days ago
    DATE_LIMIT="$(date -d "5 days ago" "+%Y-%m-%d")"
elif [ $SCAN_MODE == "medium" ]; then
    # Start from 30 days ago
    DATE_LIMIT="$(date -d "30 days ago" "+%Y-%m-%d")"
elif [ $SCAN_MODE == "long" ]; then
    # Start from 2 years ago
    DATE_LIMIT="$(date -d "2 years ago" "+%Y-%m-%d")"
fi

SUCCESS=0

if [ "$DATE_LIMIT" ]; then
    # start at some reasonable photo ($DATE_LIMIT) to capture new
    # shared album photos in combination with the skipexisting flag
    timeout 10m gphotos-cdp -from $DATE_LIMIT -dldir /home/nonroot/Downloads/gphotos-cdp -dev -v -headless
else
    timeout 10m gphotos-cdp -dldir /home/nonroot/Downloads/gphotos-cdp -dev -v -headless
fi
if [ $? == 0 ]; then
    SUCCESS=1
fi

# don't let lingering chrome processes
killall chrome

if [ $SUCCESS == 1 ]; then
    # success! let's unzip possible Photos.zip and exit

    # shellcheck disable=SC2016
    find "$OUTPUT_DIR" -name 'Photos.zip' -execdir unzip '{}' \; -exec bash -c 'mv "$1" "$1.bak"' bash {} \;

    if [ -n "$HEALTHCHECK_ID" ]; then
        curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
    fi

    exit 0
else
    if [ -n "$HEALTHCHECK_ID" ]; then
        curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID/fail"
    fi

    # fail!
    exit 1
fi
