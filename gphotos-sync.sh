#!/usr/bin/env bash

function usage () {
    echo "Usage: $0"
}

if [ $# != 0 ]; then
    usage
    exit 1
fi

if [ -n "$HEALTHCHECK_ID" ]; then
    curl -sS -X POST -o /dev/null "https://hc-ping.com/$HEALTHCHECK_ID/start"
fi

function is_sync_running() {
    PGREP_COMMAND="pgrep gphotos-sync.sh"

    for pid in $($PGREP_COMMAND); do
        if [ "$pid" != $$ ]; then
            return 0
        fi
    done

    return 1
}

if is_sync_running; then
    echo "Sync already running. Exiting..."
    if [ -n "$HEALTHCHECK_ID" ]; then
        curl -sS -X POST -o /dev/null --fail "https://hc-ping.com/$HEALTHCHECK_ID"
    fi
        exit 0
fi

OUTPUT_DIR="/home/nonroot/Downloads/gphotos-cdp"

SUCCESS=0
timeout 2h gphotos-cdp -dldir /home/nonroot/Downloads/gphotos-cdp -workers 4 -dev -v -headless
if [ $? == 0 ]; then
    SUCCESS=1
fi

# don't let lingering chrome processes
killall chrome

if [ $SUCCESS == 1 ]; then
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
