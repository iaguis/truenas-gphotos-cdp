# Run gphotos-cdp in TrueNAS Kubernetes

* Build and push the gphotos-cdp image (if not done already)
    ```
    docker build -t ghcr.io/iaguis/gphotos-cdp:v1 .
    docker push ghcr.io/iaguis/gphotos-cdp:v1
    ```
* Copy Chromium's profile logged in to the Google Photos account to the iago-home dataset
    ```
    sudo cp -r /tmp/gphotos-cdp/ /mnt/locke-nas/iago-home/gphotos-cdp/
    ```
* Make sure the google-photos dataset is present
    ```
    ls -d /mnt/locke-nas/google-photos
    ```
* Create [healthchecks.io](https://healthchecks.io) secret
    ```
    alias k='sudo k3s kubectl'
    HEALTHCHECKS_SHORT_UUID="XXX"
    HEALTHCHECKS_MEDIUM_UUID="XXX"
    HEALTHCHECKS_LONG_UUID="XXX"
    k create secret gphotos-sync-short-healthcheck --from-literal=id="$HEALTHCHECKS_SHORT_UUID"
    k create secret gphotos-sync-medium-healthcheck --from-literal=id="$HEALTHCHECKS_MEDIUM_UUID"
    k create secret gphotos-sync-long-healthcheck --from-literal=id="$HEALTHCHECKS_LONG_UUID"
    ```
* Apply CronJobs
    ```
    alias k='sudo k3s kubectl'
    k apply -f gphotos-sync-cronjob.yaml
    ```
