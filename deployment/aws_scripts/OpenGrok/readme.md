
OpenGrok Deployment
====================

# Background
It is easy to utilize the [official Docker image](https://hub.docker.com/r/opengrok/docker/) for deployment, however, as documented in the page, _The indexer and the web container are not tuned for large workloads_, we may have to move the repository sync process out of the docker and do the sync by our own means and then schedule to trigger indexing through the Docker container. This can gain more control than doing that inside docker container.


# System Prerequisites
1. Run 'init.sh': Configure firewall and reboot the server
2. Run 'centos.sh': Configure and install Docker engine


# Deploy OpenGrok
1. Download the `OpenGrokDeployment.zip` package from **Release** page on the target machine.
2. Unzip the `OpenGrokDeployment.zip` package to any location on the target machine.
3. Go to the unzipped folder, run the following command:
    ```sh
    chmod +x ./start_opengrok.sh
    ./start_opengrok.sh
    ```
    This will create `/opengrok/` and `/opengrok-master` folders, and copy files to those folders.
4. Follow the instructions on screen to check accessibility of OpenGrok web page, run first-time sync and index and add cron job. Please note that you are required to prepare the **Git username** and **token** for the sync and index script to access internal GitHub Enterprise.
5. By default, two OpenGrok containers will be deployed: one is serving on port 80 with all branches (`master` and `UFT_*_Patches`); and the other is serving on port 8080 with only `master` branches. You can choose to use both or either one. If you decide to use only one OpenGrok container, just run sync and index script upon that container and stop/remove the other container.

#### Required Folders and Files for Deployment
The `OpenGrokDeployment.zip` package at least contains the following folders and files that support to deploy the OpenGrok containers.
```
- data
    footer_include
    header_include
    header_include-masteronly
    http_header_include
- etc
    readonly_configuration.xml
    readonly_configuration-masteronly.xml
- scripts
    index-src.sh
    sync-index.sh
    sync-src.sh
centos.sh
docker-compose.yaml
init.sh
start_opengrok.sh
```

#### Add Cron Job
For you convenient, here you can copy the command below and paste to the terminal to add the sync-index job to crontab. Don't forget to change the Git username and token.

##### Sync and index for all repository container
The sync and index script will be run every 3 hours per day, from 00:12 to 21:12.
```sh
(crontab -l ; echo "12 0,3,6,9,12,15,18,21 * * * /bin/bash -c '/opengrok/scripts/sync-index.sh \"<GIT-USER>\" \"<GIT-TOKEN>\" \"/opengrok/src\" \"uft/uft.devops/master/repolist/opengrok_sync.txt\" opengrok_all > \"/opengrok/sync.log\" 2>&1'") | crontab -
```

##### Sync and index for master-only repository container
The sync and index script will be run every 3 hours per day, from 02:47 to 23:47.
```sh
(crontab -l ; echo "47 2,5,8,11,14,17,20,23 * * * /bin/bash -c '/opengrok-master/scripts/sync-index.sh \"<GIT-USER>\" \"<GIT-TOKEN>\" \"/opengrok-master/src\" \"uft/uft.devops/master/repolist/opengrok_sync_master.txt\" opengrok_master > \"/opengrok-master/sync.log\" 2>&1'") | crontab -
```

#### Container Auto-restart For Stuck Indexing
The indexing process may stuck in the container occasionally. The `index-src.sh` script could detect that and try to restart the container if the last triggered index did not completed in time.

The period before the script restarts the container is called **Restart Threshold**, in hours. It can be changed in the `index-src.sh` file in the deployment folder (`/opengrok/scripts/index-src.sh` and `/opengrok-master/scripts/index-src.sh`). The default value is `48` hours.


## References
```
### Install docker
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-centos-7

### Isntall Docker compose
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-centos-7

### Open 8080 port
https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-7

```

