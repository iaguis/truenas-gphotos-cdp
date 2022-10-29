# Run gphotos-cdp in a BSD jail

* Create a 13.1-RELEASE Jail using the TrueNAS web UI named gphotos-cdp
* Set a mountpoint from the Google Photos dataset to /home/iaguis/Downloads/gphotos-cdp
* Start the jail
* Copy Chromium's profile logged in to the Google Photos account
    ```
    POOL_NAME="nas-pool"

    sudo cp -r /tmp/gphotos-cdp/ /mnt/$POOL_NAME/iocage/jails/gphotos-cdp/root/tmp/gphotos-cdp/
    ```
* Enter the jail
    ```
    sudo iocage console gphotos-cdp
    ```
* Add dependencies
    ```
    pkg install go119 git exif bash chromium
    ```
* Create user
    ```
    USERNAME=iaguis

    mkdir -p /home/$USERNAME
    pw useradd -n $USERNAME -u 1000 -g 5000 -d /home/$USERNAME -s /usr/local/bin/bash
    ```
* Clone repo as user and install binary
    ```
    su - iaguis
    git clone https://github.com/perkeep/gphotos-cdp.git
    cd gphotos-cdp
    git remote add iaguis https://github.com/iaguis/gphotos-cdp.git
    git fetch iaguis
    git checkout iaguis/skip
    go119 install .
    ```
* Copy `gphotos-sync.sh` script to `/home/$USERNAME`
* Populate crontab with `crontab -e`
    ```
    crontab -e
    ```

    Add the following to have scans:
        * Short scan (from 5 days ago) every 3 hours (at minute 50)
        * Medium scan (from 30 days ago) every week (Sunday at 0AM)
        * Full scan (from the beginning) every 2 months (1st day of the month)

    ```
    50 */3 * * * /home/iaguis/gphotos-sync.sh short
    0 0 * * 7 /home/iaguis/gphotos-sync.sh medium
    0 0 1 */2 * /home/iaguis/gphotos-sync.sh full
    ```
