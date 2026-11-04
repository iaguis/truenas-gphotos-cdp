# Run gphotos-cdp in TrueNAS

* Build and push the gphotos-cdp image (if not done already)
    ```
    docker build -t ghcr.io/iaguis/gphotos-cdp:v6 .
    docker push ghcr.io/iaguis/gphotos-cdp:v6
    ```
* Copy Chromium's profile logged in to the Google Photos account to the iago-home dataset
    ```
    sudo cp -r /tmp/gphotos-cdp/ /mnt/locke-nas/iago-home/gphotos-cdp/
    ```
* Make sure the google-photos dataset is present
    ```
    ls -d /mnt/locke-nas/google-photos
    ```
* Create [healthchecks.io](https://healthchecks.io) secret and add it to [`run-gphotos-sync.sh`](./run-gphotos-sync.sh)
    ```
    HEALTHCHECK_ID="00112233-4455-6677-8899-aabbccddeeff"
    ```
* Create a Cron Job in the TrueNAS UI under "System-Advanced Settings-Cron Jobs"
    We're currently using a Custom schedule: `50 */3 * * *`.
