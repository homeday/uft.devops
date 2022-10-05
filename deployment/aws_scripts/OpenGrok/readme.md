
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


## References
```
### Install docker
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-centos-7

### Isntall Docker compose
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-centos-7

### Open 8080 port
https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-centos-7

```

